#!/bin/bash

# === CONFIGURABLE VARIABLE ===
API_URL="http://SERVER_IP:5000/get-config"  # Replace SERVER_IP with actual server address

# === FUNCTIONS ===

connect_vpn() {
  echo "Enter username:"
  read username
  echo "Enter password:"
  read -s password

  # Build JSON payload
  payload=$(jq -n --arg u "$username" --arg p "$password" '{username: $u, password: $p}')

  # Request config
  config=$(curl -s -X POST -H "Content-Type: application/json" -d "$payload" "$API_URL" | jq -r '.config')

  if [[ "$config" == "null" || -z "$config" ]]; then
    echo "Authentication failed or server error."
    return
  fi

  # Write to temp file and bring up WireGuard
  echo "$config" > /tmp/wg-client.conf
  sudo wg-quick up /tmp/wg-client.conf

  echo "VPN connected successfully."
}

disconnect_vpn() {
  sudo wg-quick down /tmp/wg-client.conf
  rm -f /tmp/wg-client.conf
  echo "VPN disconnected."
}

# === MENU ===
while true; do
  echo ""
  echo "=== VPN Client Menu ==="
  echo "1. Connect VPN"
  echo "2. Disconnect VPN"
  echo "3. Exit"
  read -p "Choose option [1-3]: " opt

  case $opt in
    1) connect_vpn ;;
    2) disconnect_vpn ;;
    3) echo "Bye."; exit 0 ;;
    *) echo "Invalid option." ;;
  esac
done
