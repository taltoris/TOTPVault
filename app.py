from flask import Flask, render_template, request, jsonify, session, redirect, url_for
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes
from cryptography.fernet import Fernet
import pyotp
import json
import os
import base64
from functools import wraps

app = Flask(__name__)
app.secret_key = os.urandom(32)

DATA_FILE = '/data/secrets.enc'
CONFIG_FILE = '/data/config.json'

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get('logged_in'):
            return jsonify({'error': 'Not authenticated'}), 401
        return f(*args, **kwargs)
    return decorated

def derive_key(password, salt):
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=600000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
    return key

def is_first_run():
    return not os.path.exists(CONFIG_FILE)

def save_config(password_hash, salt):
    config = {
        'password_hash': password_hash,
        'salt': base64.b64encode(salt).decode()
    }
    os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f)

def load_config():
    if not os.path.exists(CONFIG_FILE):
        return None
    with open(CONFIG_FILE, 'r') as f:
        config = json.load(f)
        config['salt'] = base64.b64decode(config['salt'])
        return config

def verify_password(password):
    config = load_config()
    if not config:
        return False
    key = derive_key(password, config['salt'])
    return base64.b64encode(key).decode() == config['password_hash']

def encrypt_data(data, password):
    config = load_config()
    key = derive_key(password, config['salt'])
    f = Fernet(key)
    return f.encrypt(json.dumps(data).encode())

def decrypt_data(password):
    config = load_config()
    if not os.path.exists(DATA_FILE):
        return {}
    key = derive_key(password, config['salt'])
    f = Fernet(key)
    with open(DATA_FILE, 'rb') as file:
        encrypted = file.read()
    if not encrypted:
        return {}
    decrypted = f.decrypt(encrypted)
    return json.loads(decrypted)

def save_secrets(secrets, password):
    encrypted = encrypt_data(secrets, password)
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, 'wb') as f:
        f.write(encrypted)

@app.route('/')
def index():
    if is_first_run():
        return render_template('setup.html')
    if not session.get('logged_in'):
        return render_template('login.html')
    return render_template('index.html')

@app.route('/api/setup', methods=['POST'])
def setup():
    if not is_first_run():
        return jsonify({'error': 'Already configured'}), 400
    
    data = request.json
    password = data.get('password')
    
    if not password or len(password) < 8:
        return jsonify({'error': 'Password must be at least 8 characters'}), 400
    
    salt = os.urandom(16)
    key = derive_key(password, salt)
    password_hash = base64.b64encode(key).decode()
    
    save_config(password_hash, salt)
    save_secrets({}, password)
    
    session['logged_in'] = True
    session['password'] = password
    
    return jsonify({'success': True})

@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    password = data.get('password')
    
    if verify_password(password):
        session['logged_in'] = True
        session['password'] = password
        return jsonify({'success': True})
    
    return jsonify({'error': 'Invalid password'}), 401

@app.route('/api/logout', methods=['POST'])
def logout():
    session.clear()
    return jsonify({'success': True})

@app.route('/api/secrets', methods=['GET'])
@login_required
def get_secrets():
    try:
        secrets = decrypt_data(session['password'])
        return jsonify({'secrets': list(secrets.keys())})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/secrets', methods=['POST'])
@login_required
def add_secret():
    data = request.json
    service = data.get('service')
    secret = data.get('secret')
    
    if not service or not secret:
        return jsonify({'error': 'Service and secret required'}), 400
    
    # Validate TOTP secret
    try:
        secret = secret.replace(' ', '').upper()
        pyotp.TOTP(secret).now()
    except Exception:
        return jsonify({'error': 'Invalid TOTP secret'}), 400
    
    try:
        secrets = decrypt_data(session['password'])
        secrets[service] = secret
        save_secrets(secrets, session['password'])
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/secrets/<service>', methods=['DELETE'])
@login_required
def delete_secret(service):
    try:
        secrets = decrypt_data(session['password'])
        if service in secrets:
            del secrets[service]
            save_secrets(secrets, session['password'])
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/totp/<service>', methods=['GET'])
@login_required
def generate_totp(service):
    try:
        secrets = decrypt_data(session['password'])
        if service not in secrets:
            return jsonify({'error': 'Service not found'}), 404
        
        totp = pyotp.TOTP(secrets[service])
        code = totp.now()
        
        import time
        current_time = int(time.time())
        remaining = 30 - (current_time % 30)
        
        return jsonify({
            'code': code,
            'remaining': remaining
        })
    except Exception as e:
        app.logger.error(f"Error generating TOTP: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
