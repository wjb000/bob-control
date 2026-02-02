from flask import Flask, request, Response, send_from_directory
from flask_httpauth import HTTPBasicAuth
import requests

app = Flask(__name__, static_folder='.')

auth = HTTPBasicAuth()

# Authentication - Set via environment variables or change below
import os
USERNAME = os.getenv('BOB_USERNAME', 'admin')
PASSWORD = os.getenv('BOB_PASSWORD', 'changeme')

users = {
    USERNAME: PASSWORD
}

@auth.verify_password
def verify_password(username, password):
    return users.get(username) == password

# Your ESP IPs (change only if they are different)
MOTOR_ESP = "192.168.1.100"
CAM_ESP   = "192.168.1.222"

@app.route('/')
@auth.login_required
def index():
    return send_from_directory('.', 'index.html')

@app.route('/c')
@auth.login_required
def control():
    cmd = request.args.get('d', '')
    try:
        requests.get(f'http://{MOTOR_ESP}/c?d={cmd}', timeout=1)
    except: pass
    return "OK"

@app.route('/stream')
@auth.login_required
def stream():
    def generate():
        with requests.get(f'http://{CAM_ESP}/stream', stream=True, timeout=5) as r:
            for chunk in r.iter_content(chunk_size=1024):
                if chunk: yield chunk
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    print("Proxy running with password protection!")
    app.run(host='0.0.0.0', port=5000)
