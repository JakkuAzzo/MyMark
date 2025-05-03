from flask import Flask, request, jsonify, send_file, make_response, render_template_string
from flask_cors import CORS
import sqlite3
import os
from pathlib import Path
from werkzeug.utils import secure_filename
from watermarking import embed_watermark, phash
from detection import add_fingerprint, find_matches, all_fingerprints
from blockchain import BlockchainRegistry
import tempfile
import paseto
import datetime
import base64
from functools import wraps
import face_recognition
import pytesseract
from PIL import Image
import signal
import numpy as np
import onnxruntime as ort

app = Flask(__name__)
CORS(app, supports_credentials=True, origins="*")

DB_USERS = os.path.join(os.getcwd(), 'data', 'users_db', 'users.db')
DB_SOCIAL = os.path.join(os.getcwd(), 'data', 'social_db', 'social.db')

# Blockchain registry instance
bc = BlockchainRegistry()

PASETO_KEY = os.environ.get("PASETO_KEY", "supersecretkey1234567890123456")  # 32 bytes

def generate_paseto(username):
    return paseto.create(
        key=PASETO_KEY.encode(),
        purpose='local',
        claims={
            "sub": username,
            "exp": (datetime.datetime.utcnow() + datetime.timedelta(days=1)).isoformat()
        }
    )

def verify_paseto(token):
    try:
        if not token:
            print("verify_paseto: No token provided")
            return None
        claims = paseto.parse(key=PASETO_KEY.encode(), purpose='local', token=token)
        print("verify_paseto: claims received:", claims)
        if datetime.datetime.fromisoformat(claims['exp']) < datetime.datetime.utcnow():
            print("verify_paseto: Token expired")
            return None
        return claims['sub']
    except Exception as e:
        print("verify_paseto: error parsing token:", e)
        return None

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.cookies.get('token')
        username = verify_paseto(token) if token else None
        if not username:
            return jsonify({'status': 'fail', 'message': 'Not authenticated'}), 401
        return f(*args, **kwargs)
    return decorated

def init_users_db():
    db_path = DB_USERS
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            face_embedding BLOB,
            catchphrase_embedding BLOB,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
    """)
    conn.commit()
    conn.close()

# Call this at startup
init_users_db()

@app.route('/', methods=['GET'])
def index():
    # Always serve SPA, let frontend handle auth
    return render_template_string("""
    <!DOCTYPE html>
    <html>
    <head>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>My Mark</title>
    <style>
    body { background: #f0f4f8; }
    #app { margin: 60px auto; max-width: 400px; }
    </style>
    </head>
    <body>
    <div id="app"></div>
    <script type="module" src="/static/main.js"></script>
    </body>
    </html>
    """)

@app.route('/api/upload', methods=['POST'])
@require_auth
def upload():
    if 'image' not in request.files or 'owner' not in request.form:
        return jsonify({'status': 'fail', 'message': 'Missing image or owner'}), 400
    image = request.files['image']
    owner = request.form['owner']
    filename = secure_filename(image.filename)
    with tempfile.TemporaryDirectory() as tmpdir:
        orig_path = Path(tmpdir) / filename
        wm_path = Path(tmpdir) / f"wm_{filename}"
        image.save(orig_path)
        # Embed watermark and get fingerprint
        fingerprint_hex = embed_watermark(orig_path, wm_path, owner)
        # Register in detection index
        image_id = filename
        add_fingerprint(image_id, phash(orig_path))
        # Register on blockchain
        try:
            tx_hash = bc.register(image_id, fingerprint_hex)
        except Exception as e:
            tx_hash = str(e)
        # Return watermarked image as download
        return send_file(wm_path, as_attachment=True, download_name=f"watermarked_{filename}")

def is_valid_id_document(img_path):
    try:
        image = Image.open(img_path)
        text = pytesseract.image_to_string(image)
        print(f"[is_valid_id_document] OCR text: {repr(text)}")
        keywords = [
            'driver', 'license', 'licence', 'id', 'identification',
            'passport', 'university', 'provisional', 'driving',
            'identity', 'card', 'british', 'united kingdom', 'uk', 'eu', 'european', 'union', 'number', 'surname', 'given name', 'authority'
        ]
        text_lower = text.lower()
        print(f"[is_valid_id_document] text_lower: {repr(text_lower)}")
        matched = [word for word in keywords if word in text_lower]
        print(f"[is_valid_id_document] matched keywords: {matched}")
        has_keyword = bool(matched)
        img_arr = face_recognition.load_image_file(img_path)
        faces = face_recognition.face_locations(img_arr)
        print(f"[is_valid_id_document] Detected faces: {faces}")
        has_face = len(faces) > 0
        print(f"[is_valid_id_document] has_face={has_face}")
        # Print image size and mode for debugging OCR issues
        print(f"[is_valid_id_document] image.size={image.size}, image.mode={image.mode}")
        return has_keyword and has_face
    except Exception as e:
        print("is_valid_id_document error:", e)
        return False

def is_real_face(img_path):
    # Heuristic: check for face, and optionally anti-spoofing (liveness)
    try:
        img_arr = face_recognition.load_image_file(img_path)
        faces = face_recognition.face_locations(img_arr)
        if len(faces) == 0:
            return False
        # Optionally: check for screen glare, moire, or printout artifacts (stub)
        # For demo, just check face exists
        return True
    except Exception as e:
        print("is_real_face error:", e)
        return False

def faces_match(face_path, id_path, tolerance=0.6):
    try:
        face_img = face_recognition.load_image_file(face_path)
        id_img = face_recognition.load_image_file(id_path)
        face_enc = face_recognition.face_encodings(face_img)
        id_enc = face_recognition.face_encodings(id_img)
        if not face_enc or not id_enc:
            return False
        return face_recognition.compare_faces([id_enc[0]], face_enc[0], tolerance=tolerance)[0]
    except Exception as e:
        print("faces_match error:", e)
        return False

def facenet_embedding(img_path):
    # Return the 128-d FaceNet embedding as bytes
    try:
        img = face_recognition.load_image_file(img_path)
        encodings = face_recognition.face_encodings(img)
        if not encodings:
            return None
        arr = np.array(encodings[0], dtype=np.float32)
        return arr.tobytes()
    except Exception as e:
        print("facenet_embedding error:", e)
        return None

@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    # Required: username, id_image (base64), face_image (base64), optional: catchphrase
    if not data or 'username' not in data or 'id_image' not in data or 'face_image' not in data:
        return jsonify({'status': 'fail', 'message': 'Missing required fields (username, id_image, face_image)'}), 400

    username = data['username']
    catchphrase = data.get('catchphrase', None)
    id_img_data = base64.b64decode(data['id_image'].split(',')[1] if ',' in data['id_image'] else data['id_image'])
    face_img_data = base64.b64decode(data['face_image'].split(',')[1] if ',' in data['face_image'] else data['face_image'])

    # Save temp files
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as id_file:
        id_file.write(id_img_data)
        id_path = id_file.name
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as face_file:
        face_file.write(face_img_data)
        face_path = face_file.name

    # a. Validate ID document
    if not is_valid_id_document(id_path):
        os.remove(id_path)
        os.remove(face_path)
        return jsonify({'status': 'fail', 'message': 'ID document must be a valid passport, driver\'s license, or university ID containing a face.'}), 400

    # b. Validate real face (not screen/printout)
    if not is_real_face(face_path):
        os.remove(id_path)
        os.remove(face_path)
        return jsonify({'status': 'fail', 'message': 'No real face detected in face image. Please use a live photo.'}), 400

    # c. Check face matches ID document
    if not faces_match(face_path, id_path):
        os.remove(id_path)
        os.remove(face_path)
        return jsonify({'status': 'fail', 'message': 'Face does not match ID document.'}), 400

    # d. Generate FaceNet embedding
    embedding = facenet_embedding(face_path)
    if embedding is None:
        os.remove(id_path)
        os.remove(face_path)
        return jsonify({'status': 'fail', 'message': 'Could not generate FaceNet embedding.'}), 400

    os.remove(id_path)
    os.remove(face_path)

    # e. Store in users DB
    try:
        conn = sqlite3.connect(DB_USERS)
        c = conn.cursor()
        c.execute("""
            INSERT INTO users (username, face_embedding, catchphrase_embedding)
            VALUES (?, ?, ?)
        """, (username, embedding, catchphrase.encode('utf-8') if catchphrase else None))
        conn.commit()
        conn.close()
        token = generate_paseto(username)
        resp = jsonify({'status': 'success', 'message': 'User registered'})
        resp.set_cookie('token', token, httponly=True, samesite='None', secure=True)
        return resp
    except sqlite3.IntegrityError:
        return jsonify({'status': 'fail', 'message': 'Username already exists'}), 400
    except Exception as e:
        return jsonify({'status': 'fail', 'message': f'Registration failed: {str(e)}'}), 500

@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    if not data or 'username' not in data or 'face_image' not in data:
        return jsonify({'status': 'fail', 'message': 'Missing username or face_image'}), 400
    username = data['username']
    face_img_data = base64.b64decode(data['face_image'].split(',')[1] if ',' in data['face_image'] else data['face_image'])
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as face_file:
        face_file.write(face_img_data)
        face_path = face_file.name
    # Get stored embedding for username
    conn = sqlite3.connect(DB_USERS)
    c = conn.cursor()
    c.execute("SELECT face_embedding FROM users WHERE username=?", (username,))
    row = c.fetchone()
    conn.close()
    if not row:
        os.remove(face_path)
        return jsonify({'status': 'fail', 'message': 'User not found'}), 401
    stored_embedding = np.frombuffer(row[0], dtype=np.float32)
    # Compute embedding for uploaded face
    img = face_recognition.load_image_file(face_path)
    encodings = face_recognition.face_encodings(img)
    os.remove(face_path)
    if not encodings:
        return jsonify({'status': 'fail', 'message': 'No face detected'}), 401
    uploaded_embedding = np.array(encodings[0], dtype=np.float32)
    # Compare embeddings (cosine similarity)
    sim = np.dot(stored_embedding, uploaded_embedding) / (np.linalg.norm(stored_embedding) * np.linalg.norm(uploaded_embedding))
    if sim > 0.88:  # threshold, tune as needed
        token = generate_paseto(username)
        resp = jsonify({'status': 'success', 'message': 'Login successful'})
        resp.set_cookie('token', token, httponly=True, samesite='None', secure=True)
        return resp
    else:
        return jsonify({'status': 'fail', 'message': 'Face does not match'}), 401

@app.route('/api/logout', methods=['POST'])
def logout():
    resp = jsonify({'status': 'success', 'message': 'Logged out'})
    resp.set_cookie('token', '', expires=0, samesite='None', secure=True)
    return resp

@app.route('/api/user', methods=['GET'])
@require_auth
def user_details():
    token = request.cookies.get('token')
    print("user_details: token=", token)
    username = verify_paseto(token) if token else None
    if not username:
        print("user_details: No valid username; aborting.")
        return jsonify({'status': 'fail', 'message': 'Not logged in'}), 401
    print("user_details: username=", username)
    return jsonify({
        'status': 'success',
        'username': username,
        'images': len(all_fingerprints()),
        'matches': 0,
        'last_scan': None
    })

@app.route('/api/matches', methods=['GET'])
@require_auth
def matches():
    # Return all fingerprints for demo
    return jsonify({'matches': list(all_fingerprints().items())})

@app.route('/api/stats', methods=['GET'])
@require_auth
def stats():
    # Return simple stats
    return jsonify({'images': len(all_fingerprints()), 'matches': 0, 'last_scan': None})

@app.route('/api/scan', methods=['POST'])
@require_auth
def scan():
    # For demo, just return a stub
    return jsonify({'status': 'success', 'message': 'Scan triggered (stub)'})

# --- Face/Vocal registration/login endpoints (stubs) ---
def decode_image(dataUrl):
    # Strip data URL header, if present
    if ',' in dataUrl:
        _, encoded = dataUrl.split(',', 1)
    else:
        encoded = dataUrl
    return base64.b64decode(encoded)

@app.route('/api/validate_id', methods=['POST'])
def validate_id():
    data = request.json
    print(f"[validate_id] Received data: {data if data else None}")
    if not data or 'id_image' not in data:
        print("[validate_id] Missing id_image in request.")
        return jsonify({'status': 'fail', 'message': 'Missing id_image'}), 400
    id_image = data['id_image']
    print(f"[validate_id] id_image type: {type(id_image)}")
    print(f"[validate_id] id_image length: {len(id_image) if id_image else 0}")
    print(f"[validate_id] id_image startswith: {id_image[:30] if id_image else 'None'}")
    # Extra debug: check for empty or very short base64 string
    if not id_image or len(id_image) < 100:
        print("[validate_id] id_image is empty or too short for a valid image.")
        return jsonify({'status': 'fail', 'message': 'Image data is empty or too short.'}), 400
    try:
        img_data = decode_image(id_image)
        print(f"[validate_id] Decoded image bytes: {len(img_data)}")
        if len(img_data) < 1000:
            print("[validate_id] Decoded image is too small to be valid.")
            return jsonify({'status': 'fail', 'message': 'Decoded image is too small.'}), 400
    except Exception as e:
        print(f"[validate_id] Error decoding image: {e}")
        return jsonify({'status': 'fail', 'message': 'Could not decode image data.'}), 400
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as id_file:
        id_file.write(img_data)
        id_filepath = id_file.name
    print(f"[validate_id] Saved temp file: {id_filepath}")
    is_valid = validateIDDocument(id_filepath)
    os.remove(id_filepath)
    print(f"[validate_id] validateIDDocument result: {is_valid}")
    if is_valid:
        return jsonify({'status': 'success', 'message': 'ID card detected.'})
    else:
        return jsonify({'status': 'fail', 'message': 'No ID card detected. Please try again.'}), 400

@app.route('/api/face_register', methods=['POST'])
def face_register():
    import time
    start_time = time.time()
    # Remove signal.signal usage (not allowed in Flask dev server threads)
    # signal.signal(signal.SIGALRM, timeout_handler)
    # signal.alarm(20)
    try:
        data = request.json
        print("face_register: received data:", data)
        if not data or 'username' not in data or 'id_image' not in data or 'face_image' not in data:
            print("face_register: missing required fields")
            return jsonify({'status': 'fail', 'message': 'Missing required fields'}), 400

        # Defensive: check for empty or None images
        if not data['id_image'] or not data['face_image']:
            print("face_register: id_image or face_image is empty")
            return jsonify({'status': 'fail', 'message': 'ID image and face image are required.'}), 400

        id_img_data = decode_image(data['id_image'])
        face_img_data = decode_image(data['face_image'])

        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as id_file:
            id_file.write(id_img_data)
            id_filepath = id_file.name
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as face_file:
            face_file.write(face_img_data)
            face_filepath = face_file.name

        is_valid = validateIDDocument(id_filepath)
        print("face_register: validateIDDocument result:", is_valid)
        if not is_valid:
            os.remove(id_filepath)
            os.remove(face_filepath)
            return jsonify({'status': 'fail', 'message': 'No ID card detected in first image.'}), 400

        try:
            match = compareFaces(face_filepath, id_filepath)
            print("face_register: compareFaces result:", match)
        except Exception as e:
            os.remove(id_filepath)
            os.remove(face_filepath)
            print("compareFaces error:", e)
            import traceback
            traceback.print_exc()
            return jsonify({'status': 'fail', 'message': f'Face comparison error: {str(e)}'}), 400

        os.remove(id_filepath)
        os.remove(face_filepath)
        if match:
            print(f"face_register: success in {time.time() - start_time:.2f}s")
            return jsonify({'status': 'success', 'message': 'Face images match.'})
        else:
            print(f"face_register: no match in {time.time() - start_time:.2f}s")
            return jsonify({'status': 'fail', 'message': 'Face images do not match.'}), 400
    except TimeoutException as e:
        print("face_register: timeout")
        return jsonify({'status': 'fail', 'message': str(e)}), 504
    except Exception as e:
        print("face_register error:", e)
        import traceback
        traceback.print_exc()
        return jsonify({'status': 'fail', 'message': f'Internal error: {str(e)}'}), 500
    finally:
        # signal.alarm(0)  # Remove alarm usage
        pass

@app.route('/api/face_login', methods=['POST'])
def face_login():
    # Accepts: { "face_image": base64 }
    # TODO: Implement FaceNet logic
    # On success, set PASETO token
    resp = jsonify({'status': 'success', 'message': 'Face login successful (stub)'})
    resp.set_cookie('token', generate_paseto("demo_user"), httponly=True, samesite='None', secure=True)
    return resp

@app.route('/api/vocal_register', methods=['POST'])
def vocal_register():
    # Accepts: { "audio": base64, "username": str }
    # TODO: Implement vocal registration logic
    return jsonify({'status': 'success', 'message': 'Vocal registered (stub)'})

@app.route('/api/vocal_login', methods=['POST'])
def vocal_login():
    # Accepts: { "audio": base64 }
    # TODO: Implement vocal login logic
    resp = jsonify({'status': 'success', 'message': 'Vocal login successful (stub)'})
    resp.set_cookie('token', generate_paseto("demo_user"), httponly=True, samesite='None', secure=True)
    return resp

@app.route('/api/nav-items')
def nav_items():
    return jsonify([
        {"name": "upload", "label": "Upload", "tooltip": "Upload a file"},
        {"name": "login", "label": "Login", "tooltip": "Sign in to your account"},
        # ...other nav items...
    ])

def compareFaces(uploaded_face_path, id_face_path, tolerance=0.6):
    # Load images from file paths
    uploaded_image = face_recognition.load_image_file(uploaded_face_path)
    id_image = face_recognition.load_image_file(id_face_path)
    # Get face encodings
    uploaded_encodings = face_recognition.face_encodings(uploaded_image)
    id_encodings = face_recognition.face_encodings(id_image)
    if not uploaded_encodings or not id_encodings:
        # Could not detect a face in one or both images
        return False
    # Compare the first detected face
    results = face_recognition.compare_faces([id_encodings[0]], uploaded_encodings[0], tolerance=tolerance)
    return results[0]

def validateIDDocument(document_path):
    try:
        image = Image.open(document_path)
        text = pytesseract.image_to_string(image)
        print(f"[validateIDDocument] OCR text: {repr(text)}")
    except Exception as e:
        print("[validateIDDocument] error:", e)
        return False
    keywords = [
        'driver', 'license', 'licence', 'id', 'identification',
        'passport', 'university', 'provisional', 'driving',
        'identity', 'card', 'british', 'united kingdom', 'uk', 'eu', 'european', 'union', 'number', 'surname', 'given name', 'authority'
    ]
    text_lower = text.lower()
    matched = [word for word in keywords if word in text_lower]
    print(f"[validateIDDocument] text_lower: {repr(text_lower)}")
    print(f"[validateIDDocument] matched keywords: {matched}")
    has_keyword = bool(matched)
    print(f"[validateIDDocument] has_keyword={has_keyword}")
    # Print image size and mode for debugging OCR issues
    print(f"[validateIDDocument] image.size={image.size}, image.mode={image.mode}")
    return has_keyword

@app.route('/api/check_db', methods=['GET'])
def check_db():
    try:
        conn = sqlite3.connect(DB_USERS)
        c = conn.cursor()
        c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='users';")
        exists = c.fetchone() is not None
        conn.close()
        return jsonify({'status': 'success', 'users_table_exists': exists})
    except Exception as e:
        return jsonify({'status': 'fail', 'error': str(e)}), 500

if __name__ == '__main__':
    try:
        app.run(debug=True, host='0.0.0.0', port=5050, ssl_context=('server.crt', 'server.key'))
    except Exception as e:
        print(f"Failed to start Flask on port 5050: {e}")
        raise