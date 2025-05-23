#!/bin/bash
# run_dev.sh - Start Flask backend and Vue.js frontend for MyMark web app with HTTPS for all active IPs

set -e

# 0. Ensure Ganache (Ethereum testnet) is running on port 8545
GANACHE_PORT=8545
GANACHE_PID=""
if ! command -v lsof >/dev/null 2>&1; then
  echo "lsof not found. Please install lsof or manually ensure Ganache is running on port $GANACHE_PORT."
  exit 1
fi

if ! command -v ganache >/dev/null 2>&1; then
  echo "Ganache is not installed or not in PATH. Please install Ganache CLI (npm i -g ganache) and try again."
  exit 1
fi

GANACHE_PID=$(lsof -ti tcp:$GANACHE_PORT || true)

if [ -z "$GANACHE_PID" ]; then
  echo "Ganache is not running. Starting Ganache on port $GANACHE_PORT..."
  if ! command -v ganache >/dev/null 2>&1; then
    echo "Ganache is not installed or not in PATH. Please install Ganache CLI (npm i -g ganache) and try again."
    exit 1
  fi
  # Fix: Remove invalid argument and use correct Ganache CLI options
  nohup ganache --wallet.seed MyMarkDev --db "$(pwd)/blockchain/ganache-db" --port $GANACHE_PORT > ganache.log 2>&1 &
  GANACHE_PID=$!
  echo "Ganache started with PID $GANACHE_PID (logs: ganache.log)"
  # Wait for Ganache to be ready
  echo "Waiting for Ganache to listen on port $GANACHE_PORT..."
  for i in {1..20}; do
    if lsof -i :$GANACHE_PORT | grep -q node; then
      echo "Ganache is running on port $GANACHE_PORT."
      break
    fi
    sleep 1
    if [ $i -eq 20 ]; then
      echo "ERROR: Ganache did not start on port $GANACHE_PORT after 20 seconds."
      echo "Last 20 lines of ganache.log:"
      tail -20 ganache.log
      kill $GANACHE_PID 2>/dev/null || true
      exit 1
    fi
  done
else
  echo "Ganache is already running on port $GANACHE_PORT (PID $GANACHE_PID)."
fi

# 1. Detect all active IPv4 addresses (excluding loopback)
if command -v ip > /dev/null 2>&1; then
  # Linux: use `ip`
  IP_LIST=$(ip -4 addr show | awk '/inet / && $2 !~ /^127/ {print $2}' | cut -d/ -f1)
elif command -v ifconfig > /dev/null 2>&1; then
  # macOS: use `ifconfig`
  IP_LIST=$(ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}')
else
  echo "Could not detect local IP addresses (no ip or ifconfig found)."
  exit 1
fi

if [[ -z "$IP_LIST" ]]; then
  echo "Could not detect any active local IP addresses."
  exit 1
fi
echo "Detected local IPs: $IP_LIST"

# 1a. Filter out link-local addresses (e.g. 169.254.x.x)
FILTERED_IPS=""
for ip in $IP_LIST; do
  if [[ ! $ip =~ ^169\.254\. ]]; then
    FILTERED_IPS="$FILTERED_IPS $ip"
  fi
done
if [[ -z "$FILTERED_IPS" ]]; then
  echo "No non-link-local IPs detected; using original list."
  FILTERED_IPS="$IP_LIST"
fi
echo "Using IPs for certificate generation: $FILTERED_IPS"

# 2. Generate openssl.cnf with SAN for all filtered IPs
cat > openssl.cnf <<EOF
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
x509_extensions    = v3_req
prompt             = no

[req_distinguished_name]
CN = $(echo "$FILTERED_IPS" | awk '{print $1}')

[v3_req]
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
EOF

i=2
for ip in $FILTERED_IPS; do
  echo "IP.$i = $ip" >> openssl.cnf
  i=$((i+1))
done

# 3. Generate self-signed cert if not present or if any IP is missing from SAN
REGEN_CERT=0
if [[ ! -f server.crt || ! -f server.key ]]; then
  REGEN_CERT=1
else
  for ip in $FILTERED_IPS; do
    if ! openssl x509 -in server.crt -noout -text | grep -q "IP Address:$ip"; then
      REGEN_CERT=1
      break
    fi
  done
fi

if [[ $REGEN_CERT -eq 1 ]]; then
  echo "Generating self-signed certificate for IPs: $FILTERED_IPS ..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 \
    -keyout server.key -out server.crt -config openssl.cnf
else
  echo "Existing certificate is valid for all IPs."
fi

# 4. Validate cert covers all IPs before starting servers
for ip in $FILTERED_IPS; do
  if ! openssl x509 -in server.crt -noout -text | grep -q "IP Address:$ip"; then
    echo "ERROR: Certificate is missing IP $ip in SAN. Aborting."
    exit 1
  fi
done

# 5. Ensure port 5050 is free before starting Flask backend
FLASK_PORT=5050
# Try to kill all processes using port 5050, retry if still in use
for attempt in {1..3}; do
  FLASK_PID_EXISTING=$(lsof -ti tcp:$FLASK_PORT || true)
  if [ -n "$FLASK_PID_EXISTING" ]; then
    echo "Port $FLASK_PORT is already in use by process(es): $FLASK_PID_EXISTING. Killing them..."
    kill -9 $FLASK_PID_EXISTING || true
    sleep 2
  else
    break
  fi
done

# Final check: if still in use, abort with clear message
FLASK_PID_EXISTING=$(lsof -ti tcp:$FLASK_PORT || true)
if [ -n "$FLASK_PID_EXISTING" ]; then
  echo "ERROR: Port $FLASK_PORT is still in use after multiple kill attempts."
  echo "You may need to disable AirPlay Receiver (System Preferences -> General -> AirDrop & Handoff) or reboot."
  exit 1
fi

# 5. Start Flask backend in background with HTTPS
source .venv/bin/activate
export FLASK_APP=app.py
export FLASK_ENV=development
nohup python app.py > flask.log 2>&1 &
FLASK_PID=$!
echo "Flask backend started with PID $FLASK_PID (logs: flask.log)"
deactivate

# NEW: Wait for Flask to actually listen on port 5050 (max 20s)
echo "Waiting for Flask to listen on port 5050..."
for i in {1..20}; do
  if lsof -i :5050 | grep -q LISTEN; then
    echo "Flask is running on port 5050."
    break
  fi
  sleep 1
  if [ $i -eq 20 ]; then
    echo "ERROR: Flask did not start on port 5050 after 20 seconds."
    echo "Last 20 lines of flask.log:"
    tail -20 flask.log
    kill $FLASK_PID 2>/dev/null || true
    exit 1
  fi
done

# NEW: Wait a few seconds to ensure Flask is ready
sleep 5

# 6. Update Vite config to use the first detected non-link-local IP for proxy and HTTPS
FRONTEND_VITE_CONFIG="frontend/vite.config.js"
PRIMARY_IP=$(echo "$FILTERED_IPS" | awk '{print $1}')
if grep -q "const SERVER_IP" "$FRONTEND_VITE_CONFIG"; then
  sed -i.bak "s/const SERVER_IP = .*/const SERVER_IP = '$PRIMARY_IP';/" "$FRONTEND_VITE_CONFIG"
  echo "Updated Vite config to use IP $PRIMARY_IP"
fi

# 7. Start Vue.js frontend (Vite dev server)
echo "Starting Vue.js frontend (Vite dev server)..."
cd frontend
rm -rf node_modules/.vite dist .vite
npm run dev -- --host 0.0.0.0 &
VITE_PID=$!
cd ..

# 8. Wait for user to stop the script
trap "kill $FLASK_PID $VITE_PID $GANACHE_PID" EXIT
wait
