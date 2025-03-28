#!/bin/bash

# === CONFIGURATION VARIABLES ===
SERVER_IP="SERVER_IP"                # ← Replace with actual public IP or local IP
INTERFACE_NAME="INTERFACE_NAME"      # ← Replace with server's main network interface (e.g., enp0s3)
LISTEN_PORT=51820
API_PORT=5000

# === INSTALL WIREGUARD AND DEPENDENCIES ===
apt update
apt install -y wireguard iptables python3-pip python3-venv curl iptables-persistent

# === CLEAN FIREWALL RULES ===
iptables -t nat -F
iptables -F
iptables -X

# === ENABLE IP FORWARDING ===
sysctl -w net.ipv4.ip_forward=1
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# === SET UP WIREGUARD KEYS AND CONFIGURATION ===
mkdir -p /etc/wireguard
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
chmod 600 /etc/wireguard/server_private.key
SERVER_PRIV_KEY=$(cat /etc/wireguard/server_private.key)

cat > /etc/wireguard/wg0.conf <<EOL
[Interface]
Address = 10.0.0.1/24
ListenPort = $LISTEN_PORT
PrivateKey = $SERVER_PRIV_KEY
SaveConfig = true

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $INTERFACE_NAME -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $INTERFACE_NAME -j MASQUERADE
EOL

systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

# === INSTALL AND SET UP REST API ===
mkdir -p /opt/vpn-api
python3 -m venv /opt/vpn-api/env
source /opt/vpn-api/env/bin/activate
pip install flask

cat > /opt/vpn-api/app.py <<EOF
from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

USER_CREDENTIALS = {"USERNAME": "PASSWORD"}  # ← Replace with desired credentials

@app.route('/get-config', methods=['POST'])
def get_config():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    if USER_CREDENTIALS.get(username) == password:
        private_key = subprocess.check_output("wg genkey", shell=True).decode().strip()
        public_key = subprocess.check_output(f"echo '{private_key}' | wg pubkey", shell=True).decode().strip()
        subprocess.run(f"wg set wg0 peer {public_key} allowed-ips 10.0.0.2/32", shell=True)

        config = f\"\"\"
[Interface]
PrivateKey = {private_key}
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = $SERVER_IP:$LISTEN_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 21
\"\"\"
        return jsonify({"config": config}), 200

    return jsonify({"error": "Unauthorized"}), 401

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=$API_PORT)
EOF

cat > /etc/systemd/system/vpn-api.service <<EOF
[Unit]
Description=VPN REST API
After=network.target

[Service]
User=root
WorkingDirectory=/opt/vpn-api
ExecStart=/opt/vpn-api/env/bin/python /opt/vpn-api/app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vpn-api
systemctl restart vpn-api
netfilter-persistent save

echo "✅ VPN Server and REST API are now ready."
