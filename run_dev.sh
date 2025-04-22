#!/bin/bash
# run_dev.sh - Start Flask backend and Vue.js frontend for MyMark web app

# Start Flask backend in background
source .venv/bin/activate
export FLASK_APP=app.py
export FLASK_ENV=development
nohup python app.py > flask.log 2>&1 &
FLASK_PID=$!
echo "Flask backend started with PID $FLASK_PID (logs: flask.log)"
deactivate

# Start Vue.js frontend (Vite dev server)
echo "Starting Vue.js frontend (Vite dev server)..."
cd frontend
npm run dev &
VITE_PID=$!
cd ..

# Wait for user to stop the script
trap "kill $FLASK_PID $VITE_PID" EXIT
wait
