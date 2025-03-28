# One-Click WireGuard VPN

### 🔐 Authenticated WireGuard VPN with REST API — connect with login & password, no config files needed

---

## 📖 Description

This project provides a fully automated VPN infrastructure using **WireGuard** and a **custom REST API**.

Clients on Linux and Windows can connect to the VPN by simply entering a username and password — **no static config files, no manual distribution**.

### Includes:
- Server-side: WireGuard + REST API (Flask)
- Client-side (Linux): Bash CLI with interactive menu
- Client-side (Windows): PowerShell menu with logging
- One-click scripts, preconfigured with examples and instructions

---

## ✨ Features

- 🔐 **Authentication-based access** (login & password)
- ⚙️ **One-click installation** on server and clients
- 🔄 **Automatic key generation and assignment**
- 📡 **REST API for config delivery** (no file sharing)
- 💻 **Interactive CLI for Linux**, PowerShell menu for Windows
- 🌍 **Full tunnel mode** — all traffic goes through VPN
- 📝 **Logging** on Windows clients
- 🧩 Easily expandable, portable, open

---

## 📦 Requirements

| Component        | OS           | Notes                           |
|------------------|--------------|----------------------------------|
| Server           | Debian 12    | Required: root access            |
| Linux Client     | Debian/Ubuntu| WireGuard, curl, jq, resolvconf |
| Windows Client   | Windows 10+  | WireGuard app, PowerShell       |

---

## 🚀 Quick Start Guide

---

### I. Server Setup (Debian)

#### 1. Install dependencies

```bash
sudo apt update
sudo apt install -y wireguard iptables iptables-persistent python3-pip python3-venv curl
```

#### 2. Create setup script

```bash
nano server-setup.sh
```

Paste the full script from `server-setup.sh`, then update:

```bash
SERVER_IP="your.server.ip"
INTERFACE_NAME="your_network_interface"
```

Inside Flask app (at bottom of script), change credentials:

```python
USER_CREDENTIALS = {"your_username": "your_password"}
```

#### 3. Run the script

```bash
chmod +x server-setup.sh
sudo ./server-setup.sh
```

After completion:
- VPN listens on UDP port `51820`
- API available at `http://<SERVER_IP>:5000/get-config`

---

### II. Linux Client Setup

#### 1. Install tools

```bash
sudo apt update
sudo apt install -y wireguard curl jq resolvconf
```

#### 2. Create script

```bash
nano client-linux.sh
```

Paste the Linux script and modify this line:

```bash
API_URL="http://your.server.ip:5000/get-config"
```

Make it executable:

```bash
chmod +x client-linux.sh
```

#### 3. Run client menu

```bash
./client-linux.sh
```

Menu options:

```
1) Connect VPN
2) Disconnect VPN
3) Exit
```

---

### III. Windows Client Setup

#### 1. Install [WireGuard for Windows](https://www.wireguard.com/install/)

#### 2. Allow PowerShell scripts

Open PowerShell as Administrator:

```powershell
Set-ExecutionPolicy Bypass -Scope CurrentUser
```

#### 3. Save the client script

Create a file:

```powershell
vpn-interactive.ps1
```

Paste the full script, then update this line:

```powershell
$global:ApiUrl = "http://your.server.ip:5000/get-config"
```

#### 4. Run the script

```powershell
cd C:\Path\To\Script
.\vpn-interactive.ps1
```

Menu options:
```
1) Connect VPN
2) Disconnect VPN
3) Exit
```

#### 5. (Optional) Create shortcut

- Right click desktop → New → Shortcut
- Command:
```
powershell.exe -ExecutionPolicy Bypass -File "C:\Path\To\vpn-interactive.ps1"
```
- Right click → Properties → Advanced → ✅ "Run as Administrator"

---

## Repository Structure

```
LICENSE               # MIT license
README.md             # Documentation and usage instructions
client-linux.sh       # Linux client script
server-setup.sh       # One-click VPN + REST API installer
vpn-interactive.ps1   # Windows PowerShell client
```


## 🔒 Security Notes

- Server handles all key generation
- Configs are per-session and not stored permanently
- No need to manually distribute `.conf` files
- Users only need login/password to connect

---

## ✅ Summary

Whether you're protecting remote clients, setting up a self-hosted VPN for home or office, or deploying simple secure access for users — this project gets you running in minutes with minimal effort.

It combines the speed and security of **WireGuard** with the flexibility of **API-driven configuration** and a modern approach to VPN onboarding.

---

## 📜 License

MIT License — see [LICENSE](LICENSE)

---

## 🙌 Acknowledgements

Thanks to:
- [WireGuard](https://www.wireguard.com)
- [Flask](https://flask.palletsprojects.com)
- Everyone contributing, testing, and giving feedback ❤️

---

## 🔧 Want to contribute?

Pull requests welcome!

Have ideas for Android, QR-code login, or GUI version?  
Create an issue or fork and build!

```bash
# Secure. Simple. Yours.
```

