from flask import Flask, request, Response, send_from_directory
import requests

app = Flask(__name__, static_folder='.')

# Your ESP IPs (change only if they are different)
MOTOR_ESP = "192.168.1.100"
CAM_ESP   = "192.168.1.222"

@app.route('/')
def index():
    return send_from_directory('.', 'index.html')

@app.route('/c')
def control():
    cmd = request.args.get('d', '')
    try:
        requests.get(f'http://{MOTOR_ESP}/c?d={cmd}', timeout=1)
    except: pass
    return "OK"

@app.route('/stream')
def stream():
    def generate():
        with requests.get(f'http://{CAM_ESP}/stream', stream=True, timeout=5) as r:
            for chunk in r.iter_content(chunk_size=1024):
                if chunk: yield chunk
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    print("🤖 Bob Control Server Starting...")
    print("📡 Motor ESP:", MOTOR_ESP)
    print("📷 Camera ESP:", CAM_ESP)
    print("🌐 Access at: http://localhost:5000")
    print("⚠️  No authentication (localhost only)")
    app.run(host='0.0.0.0', port=5000)
