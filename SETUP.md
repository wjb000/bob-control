# Quick Setup Guide

## GitHub Repository Setup

A browser window has been opened to create the GitHub repository. Follow these steps:

### 1. Create GitHub Repo
In the opened browser window:
- **Repository name:** `bob-control`
- **Description:** Robot FPV Control System - Full ESP32 robot control with camera feed
- **Visibility:** Public
- Click **"Create repository"**

### 2. Push Code to GitHub
Once the repo is created, run these commands:

```bash
cd /Users/sudo/Desktop/bob-control
git remote add origin https://github.com/YOUR_USERNAME/bob-control.git
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

---

## Quick Start

### 1. Install Python Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure ESP32 IPs
Edit `server.py`:
```python
MOTOR_ESP = "192.168.1.100"  # Your ESP32 motor controller IP
CAM_ESP   = "192.168.1.222"  # Your ESP32-CAM IP
```

### 3. Set Password
Edit `server.py`:
```python
users = {
    "robot": "YourSecurePassword123"
}
```

### 4. Run Server
```bash
python server.py
```

### 5. Access Control Panel
Open browser: `http://localhost:5000`

Login with username `robot` and your password.

---

## Controls

- **W/↑** - Forward
- **S/↓** - Backward
- **A/←** - Left
- **D/→** - Right
- **Speed Slider** - Adjust motor speed (5-13)
- **LIGHT Button** - Toggle headlight
- **Red Center** - Emergency stop (double-tap)

---

## Testing Without Hardware

You can test the interface without ESP32 hardware:

1. Run `python server.py`
2. Open `http://localhost:5000`
3. The UI will load (camera will show error)
4. Controls will work but commands won't reach hardware

---

## Deployment

### Option 1: Local Network
- Run on computer connected to same WiFi as ESP32
- Access from phone/tablet: `http://YOUR_COMPUTER_IP:5000`

### Option 2: Raspberry Pi
- Copy files to Raspberry Pi
- Run `python server.py` on boot
- Access from anywhere on network

### Option 3: Cloud (with VPN)
- Deploy to cloud server
- Set up VPN for ESP32s
- Access from anywhere

---

## Troubleshooting

**Camera not loading?**
- Check ESP32-CAM IP in `server.py`
- Test direct access: `http://192.168.1.222/stream`

**Motors not responding?**
- Verify motor ESP32 IP
- Check network connectivity
- View Python console for errors

**Can't login?**
- Check username/password in `server.py`
- Clear browser cache

---

For full documentation, see **README.md**
