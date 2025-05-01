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
    # Add columns for face_embedding and catchphrase_embedding (BLOB for future use)
    c.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
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

@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    if not data or 'username' not in data or 'password' not in data:
        return jsonify({'status': 'fail', 'message': 'Missing username or password'}), 400
    try:
        conn = sqlite3.connect(DB_USERS)
        c = conn.cursor()
        # Insert user with empty face/catchphrase embeddings for now
        c.execute("""
            INSERT INTO users (username, password, face_embedding, catchphrase_embedding)
            VALUES (?, ?, ?, ?)
        """, (data['username'], data['password'], None, None))
        conn.commit()
        conn.close()
        token = generate_paseto(data['username'])
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
    if not data or 'username' not in data or 'password' not in data:
        return jsonify({'status': 'fail', 'message': 'Missing username or password'}), 400
    conn = sqlite3.connect(DB_USERS)
    c = conn.cursor()
    c.execute("SELECT * FROM users WHERE username=? AND password=?", (data['username'], data['password']))
    user = c.fetchone()
    conn.close()
    if user:
        token = generate_paseto(data['username'])
        resp = jsonify({'status': 'success', 'message': 'Login successful'})
        resp.set_cookie('token', token, httponly=True, samesite='None', secure=True)
        return resp
    else:
        return jsonify({'status': 'fail', 'message': 'Invalid credentials'})

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
    if not data or 'id_image' not in data:
        return jsonify({'status': 'fail', 'message': 'Missing id_image'}), 400
    img_data = decode_image(data['id_image'])
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as id_file:
        id_file.write(img_data)
        id_filepath = id_file.name
    is_valid = validateIDDocument(id_filepath)
    os.remove(id_filepath)
    if is_valid:
        return jsonify({'status': 'success', 'message': 'ID card detected.'})
    else:
        return jsonify({'status': 'fail', 'message': 'No ID card detected. Please try again.'}), 400

class TimeoutException(Exception):
    pass

def timeout_handler(signum, frame):
    raise TimeoutException("Face registration timed out.")

@app.route('/api/face_register', methods=['POST'])
def face_register():
    import time
    start_time = time.time()
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(20)
    try:
        data = request.json
        if not data or 'username' not in data or 'id_image' not in data or 'face_image' not in data:
            return jsonify({'status': 'fail', 'message': 'Missing required fields'}), 400

        id_img_data = decode_image(data['id_image'])
        face_img_data = decode_image(data['face_image'])

        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as id_file:
            id_file.write(id_img_data)
            id_filepath = id_file.name
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as face_file:
            face_file.write(face_img_data)
            face_filepath = face_file.name

        # Validate ID card
        if not validateIDDocument(id_filepath):
            os.remove(id_filepath)
            os.remove(face_filepath)
            return jsonify({'status': 'fail', 'message': 'No ID card detected in first image.'}), 400

        # Perform face comparison with fast fail and logging
        try:
            match = compareFaces(face_filepath, id_filepath)
        except Exception as e:
            os.remove(id_filepath)
            os.remove(face_filepath)
            print("compareFaces error:", e)
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
        return jsonify({'status': 'fail', 'message': f'Internal error: {str(e)}'}), 400
    finally:
        signal.alarm(0)  # Always disable alarm

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
    # Load document image and extract text using OCR
    try:
        image = Image.open(document_path)
        text = pytesseract.image_to_string(image)
    except Exception as e:
        # Log or handle error
        return False
    # Basic check for expected identification keywords
    keywords = ['Driver', 'License', 'ID', 'Identification']
    if any(word in text for word in keywords):
        return True
    return False

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
    app.run(debug=True, host='0.0.0.0', ssl_context=('server.crt', 'server.key'))