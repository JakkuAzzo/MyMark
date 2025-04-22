<<<<<<< HEAD
# MyMark Web App (Vue.js + Flask)

## Overview
This project is a user-friendly web application for watermarking, registering, and matching images using perceptual hashes and blockchain proofs. The frontend is built with Vue.js (bundled by Parcel), and the backend is a Flask API with SQLite storage.

## Project Structure
- **src/**: Vue.js frontend (entry: `main.js`, HTML: `index.html`)
- **app.py**: Flask backend API
- **data/**: SQLite databases for users and social data
- **blockchain/**, **detection/**, **watermarking/**: Python modules for watermarking, matching, and blockchain interaction

## Getting Started

### 1. Install Python dependencies
```sh
python3 -m venv .venv
source .venv/bin/activate
pip install flask flask-cors
```

### 2. Install Node.js dependencies
```sh
npm install
```

### 3. Run the Flask backend
```sh
python app.py
```
The backend will be available at http://127.0.0.1:5000

### 4. Run the Vue.js frontend (in a new terminal)
```sh
npm run dev
```
The frontend will be available at http://localhost:1234

## API Endpoints
- `POST /api/upload` — Upload and fingerprint an image
- `POST /api/register` — Register a new user
- `POST /api/login` — User login
- `GET /api/matches` — Fetch image matches
- `GET /api/stats` — Fetch statistics
- `POST /api/scan` — Trigger a scan for matches

## Notes
- The backend endpoints are currently stubs. Integrate with the existing Python modules for full functionality.
- CORS is enabled for local development.
- Databases are stored in `data/users_db/users.db` and `data/social_db/social.db`.

## Migrating from Electron/React
- All Electron and React code has been removed.
- The app is now a pure web app (Vue.js + Flask).

---

For further development, connect the Flask API endpoints to the logic in `watermarking/`, `detection/`, and `blockchain/` as needed.
=======
# cerrf-scratch
>>>>>>> origin/main
