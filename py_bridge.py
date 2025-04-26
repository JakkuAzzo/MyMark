import base64, json, sys, os, hashlib
import numpy as np, cv2
from face_auth import face_embedding
from pymongo import MongoClient
from argon2 import PasswordHasher
from datetime import datetime

ph = PasswordHasher()
users = MongoClient("mongodb://localhost:27017").mymark_users_db.users

def b64_to_bgr(b64):
    data = base64.b64decode(b64.split(",")[-1])
    arr = np.frombuffer(data, np.uint8)
    return cv2.imdecode(arr, cv2.IMREAD_COLOR)

def main():
    msg = json.loads(sys.stdin.read())
    emb_id  = face_embedding(b64_to_bgr(msg["idFrameBase64"]))
    emb_live = face_embedding(b64_to_bgr(msg["liveFrameBase64"]))
    if emb_id is None or emb_live is None:
        sys.exit("no-face")
    sim = np.dot(emb_id, emb_live) / (np.linalg.norm(emb_id)*np.linalg.norm(emb_live))
    if sim < 0.88:
        sys.exit("kyc-mismatch")
    if users.count_documents({"face_embedding": {"$near": {"$vector": emb_live.tolist(), "$distance": 0.12}}}):
        sys.exit("already-exists")
    salt = os.urandom(16).hex()
    users.insert_one({
        "face_embedding": emb_live.tobytes(),
        "pass_salt": salt,
        "pass_hash": ph.hash(msg["passphrase"] + salt),
        "kyc_id_hash": hashlib.sha256(emb_id.tobytes()).hexdigest(),
        "created_at": datetime.utcnow()
    })
    print("ok")

if __name__ == "__main__":
    main()
