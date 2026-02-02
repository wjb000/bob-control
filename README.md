# Bob Control - Robot FPV Controller

Complete robot control system with FPV camera feed, WASD controls, and password authentication.

## Features

- **FPV Camera Stream** - Real-time video feed from ESP32-CAM
- **WASD Controls** - Keyboard and button controls for robot movement
- **Speed Control** - Adjustable motor speed (5-13)
- **Light Toggle** - Control robot headlight/LED
- **Emergency Stop** - Double-tap red button for emergency halt
- **Password Protected** - HTTP Basic Auth security
- **Mobile Friendly** - Touch controls for smartphones

## Hardware Requirements

### ESP32 Motor Controller
- IP: `192.168.1.100` (configurable in server.py)
- Controls: Motors, LED light
- Commands:
  - `w` - Forward
  - `s` - Backward
  - `a` - Left
  - `d` - Right
  - `x` - Stop
  - `l` - Toggle light
  - `s[5-13]` - Set speed

### ESP32-CAM
- IP: `192.168.1.222` (configurable in server.py)
- Streams: MJPEG video feed at `/stream`

## Setup Instructions

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Server

Edit `server.py`:

```python
# Change credentials
users = {
    "robot": "YourStrongPassword123"
}

# Update ESP IPs if different
MOTOR_ESP = "192.168.1.100"
CAM_ESP   = "192.168.1.222"
```

### 3. Run Server

```bash
python server.py
```

Server will start at `http://0.0.0.0:5000`

### 4. Access Control Interface

Open browser and navigate to:
- Local: `http://localhost:5000`
- Network: `http://[your-ip]:5000`

Login with credentials set in step 2.

## Controls

### Keyboard
- **W / ↑** - Forward
- **S / ↓** - Backward
- **A / ←** - Turn Left
- **D / →** - Turn Right
- **Release Key** - Stop

### On-Screen Buttons
- **↑ ↓ ← →** - Direction controls
- **Red Center** - Emergency stop (double-tap)
- **LIGHT Button** - Toggle headlight
- **Speed Slider** - Adjust motor speed

### Mobile
- Touch buttons for movement
- Pinch/zoom camera view
- Landscape mode recommended

## Architecture

```
┌─────────────┐
│   Browser   │  (You control here)
└──────┬──────┘
       │ HTTP
┌──────▼──────┐
│ Flask Proxy │  (Password protection)
│  Port 5000  │
└──┬───────┬──┘
   │       │
   │       └──────────────┐
   │                      │
   ▼                      ▼
┌──────────────┐   ┌─────────────┐
│  ESP32 Motor │   │ ESP32-CAM   │
│ 192.168.1.100│   │192.168.1.222│
└──────────────┘   └─────────────┘
   │                      │
   ▼                      ▼
[Motors/LED]         [Camera]
```

## Security Features

- HTTP Basic Authentication
- No command injection (sanitized inputs)
- Timeout protection (1s motor, 5s camera)
- Emergency stop function
- Window blur stops movement

## Customization

### Change Control Repeat Rate
In `index.html`, modify:
```javascript
repeatTimer = setInterval(() => send(cmd), 180);  // milliseconds
```

### Adjust Speed Range
In `index.html`:
```html
<input type="number" id="speedVal" value="13" min="5" max="13">
```

### Modify UI Colors
In `<style>` section, change:
```css
color:#0f0;  /* Green theme */
border:8px solid #0f0;
```

## Troubleshooting

### Camera Not Loading
- Check ESP32-CAM IP is correct
- Verify `/stream` endpoint works: `http://192.168.1.222/stream`
- Check network connectivity

### Motor Not Responding
- Verify ESP32 motor controller IP
- Test direct: `http://192.168.1.100/c?d=w`
- Check ESP32 serial monitor for errors

### Password Not Working
- Ensure credentials match in `server.py`
- Clear browser cache
- Try incognito/private window

### High Latency
- Reduce camera resolution on ESP32-CAM
- Use local network (not through internet)
- Check WiFi signal strength

## ESP32 Arduino Code Reference

### Motor Controller Expected Commands
```cpp
void handleCommand() {
  String cmd = server.arg("d");

  if (cmd == "w") forward();
  else if (cmd == "s") backward();
  else if (cmd == "a") left();
  else if (cmd == "d") right();
  else if (cmd == "x") stopMotors();
  else if (cmd == "l") toggleLight();
  else if (cmd.startsWith("s")) {
    int speed = cmd.substring(1).toInt();
    setSpeed(speed);
  }
}
```

### ESP32-CAM Stream Endpoint
```cpp
server.on("/stream", HTTP_GET, []() {
  WiFiClient client = server.client();
  // Stream MJPEG frames
});
```

## Advanced Features

### Add Servo Control
Extend commands in `server.py`:
```python
@app.route('/servo')
@auth.login_required
def servo():
    angle = request.args.get('angle', '90')
    requests.get(f'http://{MOTOR_ESP}/servo?angle={angle}')
    return "OK"
```

### Add Sensor Readings
```python
@app.route('/sensors')
@auth.login_required
def sensors():
    r = requests.get(f'http://{MOTOR_ESP}/sensors')
    return r.json()
```

### Remote Access
Use ngrok or similar:
```bash
ngrok http 5000
```

## Development

### Project Structure
```
bob-control/
├── index.html        # Frontend UI
├── server.py         # Flask proxy server
├── requirements.txt  # Python dependencies
└── README.md         # This file
```

### Testing
1. Test motor controller: `curl http://192.168.1.100/c?d=w`
2. Test camera stream: Open `http://192.168.1.222/stream`
3. Test proxy: `python server.py` → `http://localhost:5000`

## License

MIT License - Feel free to modify and use for your projects!

## Credits

Built for ESP32 robot control with FPV capabilities.
