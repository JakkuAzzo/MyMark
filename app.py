from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import sqlite3
import os
from pathlib import Path
from werkzeug.utils import secure_filename
from watermarking import embed_watermark, phash
from detection import add_fingerprint, find_matches, all_fingerprints
from blockchain import BlockchainRegistry
import tempfile

app = Flask(__name__)
CORS(app)

DB_USERS = os.path.join(os.getcwd(), 'data', 'users_db', 'users.db')
DB_SOCIAL = os.path.join(os.getcwd(), 'data', 'social_db', 'social.db')

# Blockchain registry instance
bc = BlockchainRegistry()

@app.route('/api/upload', methods=['POST'])
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
    return jsonify({'status': 'success', 'message': 'User registered'})

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
        return jsonify({'status': 'success', 'message': 'Login successful'})
    else:
        return jsonify({'status': 'fail', 'message': 'Invalid credentials'})

@app.route('/api/matches', methods=['GET'])
def matches():
    # Return all fingerprints for demo
    return jsonify({'matches': list(all_fingerprints().items())})

@app.route('/api/stats', methods=['GET'])
def stats():
    # Return simple stats
    return jsonify({'images': len(all_fingerprints()), 'matches': 0, 'last_scan': None})

@app.route('/api/scan', methods=['POST'])
def scan():
    # For demo, just return a stub
    return jsonify({'status': 'success', 'message': 'Scan triggered (stub)'})

if __name__ == '__main__':
    app.run(debug=True)
