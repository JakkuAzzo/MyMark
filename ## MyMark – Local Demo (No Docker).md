## MyMark – Local Demo (No Docker)

> **Version 0.5 – 21 Apr 2025**

This variant shows how to run the MyMark demo without Docker. All services run directly on your host using local SQLite databases and persisted data directories.

---

### 0  Prerequisites

| Tool               | Version | Install hint                |
|--------------------|---------|-----------------------------|
| **SQLite (pysqlite3)** | Any   | Comes with Python (or install via pip if needed) |
| **Ganache CLI**    | ≥ 7.9  | `npm i -g ganache`          |
| **Node.js**        | ≥ 18    | `brew install node` or installer |
| **Python**         | ≥ 3.10  | Use project venv            |

---

### 1  Folder layout for local data

```
mymark/
  data/
    users_db/            # SQLite file (users.db will be created here)
    social_db/           # SQLite file (social.db will be created here)
  blockchain/
    ganache-db/          # Optional: persisted chain data
```

Create these folders:

```bash
mkdir -p data/users_db data/social_db blockchain/ganache-db
```

### Database Initialization

To create the SQLite databases and seed them with dummy data, run:

```bash
python generate_db.py
```

### SQLite Structure

**User Database (users.db in data/users_db):**

| Column         | Type      | Notes                                                        |
|----------------|-----------|--------------------------------------------------------------|
| id             | INTEGER   | PRIMARY KEY, AUTOINCREMENT                                   |
| face_embedding | BLOB      | 512-byte binary (dummy 128‑D vector)                         |
| pass_salt      | TEXT      | 16 random bytes encoded in hex                               |
| pass_hash      | TEXT      | SHA‑256 hash of "password" + salt                             |
| kyc_id_hash    | TEXT      | SHA‑256 of dummy ID‑document                                  |
| created_at     | DATETIME  | ISO timestamp                                                |

**Social Database (social.db in data/social_db):**

- **platforms:** id, name  
- **accounts:** id, platform_id, handle  
- **posts:** id, account_id, ts, media_type, media_path, phash64, face_embeds, caption  
  *Note: The face_embeds column is stored as a JSON‑encoded string of hex values.*

---

### 2  Start the background service

**Tab 1 – Ganache (Ethereum JSON-RPC @ 8545):**
```bash
ganache --wallet.seed MyMarkDev --database.blockchain="$(pwd)/blockchain/ganache-db" --port 8545
```

---

### 3  Run the Electron app

In your project root:

```bash
npm install

env USERS_DB_PATH="$(pwd)/data/users_db/users.db" \
    SOCIAL_DB_PATH="$(pwd)/data/social_db/social.db" \
    CHAIN_RPC="http://localhost:8545" \
    npm run dev
```

The renderer opens; now you can:
* **Register** a new account (using face capture & a catchphrase, plus an ID document check).
* **Login** using either your face (or catchphrase).
* **Upload** images – MyMark embeds a watermark and writes its fingerprint on‑chain.
* **Scan** – finds potential matches against social media posts from the social database.

---

### 4  Service shutdown / cleanup

```bash
pkill -f ganache
```