#!/bin/bash
# run_dev.sh - Start Flask backend and Vue.js frontend for MyMark web app with HTTPS for all active IPs

set -e

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

# 2. Generate openssl.cnf with SAN for all IPs
cat > openssl.cnf <<EOF
[req]
default_bits       = 2048
distinguished_name = req_distinguished_name
x509_extensions    = v3_req
prompt             = no

[req_distinguished_name]
CN = $(echo "$IP_LIST" | head -n1)

[v3_req]
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
EOF

i=1
for ip in $IP_LIST; do
  echo "IP.$i = $ip" >> openssl.cnf
  i=$((i+1))
done

# 3. Generate self-signed cert if not present or if any IP is missing from SAN
REGEN_CERT=0
if [[ ! -f server.crt || ! -f server.key ]]; then
  REGEN_CERT=1
else
  for ip in $IP_LIST; do
    if ! openssl x509 -in server.crt -noout -text | grep -q "IP Address:$ip"; then
      REGEN_CERT=1
      break
    fi
  done
fi

if [[ $REGEN_CERT -eq 1 ]]; then
  echo "Generating self-signed certificate for IPs: $IP_LIST ..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 \
    -keyout server.key -out server.crt -config openssl.cnf
else
  echo "Existing certificate is valid for all IPs."
fi

# 4. Validate cert covers all IPs before starting servers
for ip in $IP_LIST; do
  if ! openssl x509 -in server.crt -noout -text | grep -q "IP Address:$ip"; then
    echo "ERROR: Certificate is missing IP $ip in SAN. Aborting."
    exit 1
  fi
done

# 5. Start Flask backend in background with HTTPS
source .venv/bin/activate
export FLASK_APP=app.py
export FLASK_ENV=development
nohup python app.py > flask.log 2>&1 &
FLASK_PID=$!
echo "Flask backend started with PID $FLASK_PID (logs: flask.log)"
deactivate

# 6. Update Vite config to use the first detected IP for proxy and HTTPS
FRONTEND_VITE_CONFIG="frontend/vite.config.js"
PRIMARY_IP=$(echo "$IP_LIST" | head -n1)
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
trap "kill $FLASK_PID $VITE_PID" EXIT
wait
