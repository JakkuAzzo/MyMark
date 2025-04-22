import os
import sys
import sqlite3
import json
import datetime
import hashlib

def generate_dummy_user():
    # Create dummy user data.
    face_embedding = os.urandom(512)  # 512 bytes binary (dummy 128‑D vector)
    salt = os.urandom(16)             # 16 random bytes
    pass_salt = salt.hex()
    password = "password".encode('utf-8')
    pass_hash = hashlib.sha256(password + salt).hexdigest()
    kyc_id_hash = hashlib.sha256(b"dummy_id_document").hexdigest()
    created_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
    return (face_embedding, pass_salt, pass_hash, kyc_id_hash, created_at)

def generate_dummy_social_data():
    # Create dummy social data.
    platform = ("Facebook",)
    account = ("dummy_user",)  # Will assign platform_id after insertion.
    ts = datetime.datetime.now(datetime.timezone.utc).isoformat()
    post = (ts, "image", "/path/to/dummy_image.jpg", "ffffffffffffffff",
            json.dumps([os.urandom(512).hex()]), "This is a dummy post.")
    return platform, account, post

def init_users_db():
    db_path = os.path.join(os.getcwd(), "data", "users_db", "users.db")
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("DROP TABLE IF EXISTS users;")
    c.execute("""
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            face_embedding BLOB,
            pass_salt TEXT,
            pass_hash TEXT,
            kyc_id_hash TEXT,
            created_at DATETIME
        );
    """)
    user = generate_dummy_user()
    c.execute("""
        INSERT INTO users (face_embedding, pass_salt, pass_hash, kyc_id_hash, created_at)
        VALUES (?, ?, ?, ?, ?);
    """, user)
    conn.commit()
    print("Inserted dummy user with id:", c.lastrowid)
    conn.close()

def init_social_db():
    db_path = os.path.join(os.getcwd(), "data", "social_db", "social.db")
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute("DROP TABLE IF EXISTS platforms;")
    c.execute("DROP TABLE IF EXISTS accounts;")
    c.execute("DROP TABLE IF EXISTS posts;")
    c.execute("""
        CREATE TABLE platforms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
        );
    """)
    c.execute("""
        CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            platform_id INTEGER,
            handle TEXT,
            FOREIGN KEY (platform_id) REFERENCES platforms(id)
        );
    """)
    c.execute("""
        CREATE TABLE posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account_id INTEGER,
            ts DATETIME,
            media_type TEXT,
            media_path TEXT,
            phash64 TEXT,
            face_embeds TEXT,
            caption TEXT,
            FOREIGN KEY (account_id) REFERENCES accounts(id)
        );
    """)
    platform, account, post = generate_dummy_social_data()
    c.execute("INSERT INTO platforms (name) VALUES (?);", platform)
    platform_id = c.lastrowid
    c.execute("INSERT INTO accounts (platform_id, handle) VALUES (?, ?);", (platform_id, account[0]))
    account_id = c.lastrowid
    c.execute("""
        INSERT INTO posts (account_id, ts, media_type, media_path, phash64, face_embeds, caption)
        VALUES (?, ?, ?, ?, ?, ?, ?);
    """, (account_id, *post))
    conn.commit()
    print("Inserted dummy platform with id:", platform_id)
    print("Inserted dummy account with id:", account_id)
    print("Inserted dummy post with id:", c.lastrowid)
    conn.close()

def main():
    try:
        init_users_db()
    except Exception as e:
        print("Error initializing users db:", e)
        sys.exit(1)
    try:
        init_social_db()
    except Exception as e:
        print("Error initializing social db:", e)
        sys.exit(1)

if __name__ == "__main__":
    main()