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
    # Store user in SQLite users DB
    conn = sqlite3.connect(DB_USERS)
    c = conn.cursor()
    c.execute("INSERT INTO users (pass_salt, pass_hash, kyc_id_hash, created_at) VALUES (?, ?, ?, datetime('now'))", (data['username'], data['password'], data.get('kyc_id_hash', '')))
    conn.commit()
    conn.close()
    token = generate_paseto(data['username'])
    resp = jsonify({'status': 'success', 'message': 'User registered'})
    resp.set_cookie('token', token, httponly=True, samesite='None', secure=True)
    return resp

@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    if not data or 'username' not in data or 'password' not in data:
        return jsonify({'status': 'fail', 'message': 'Missing username or password'}), 400
    conn = sqlite3.connect(DB_USERS)
    c = conn.cursor()
    c.execute("SELECT * FROM users WHERE pass_salt=? AND pass_hash=?", (data['username'], data['password']))
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
@app.route('/api/face_register', methods=['POST'])
def face_register():
    # Accepts: { "face_image": base64, "username": str }
    # TODO: Implement FaceNet logic
    return jsonify({'status': 'success', 'message': 'Face registered (stub)'})

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

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', ssl_context=('server.crt', 'server.key'))