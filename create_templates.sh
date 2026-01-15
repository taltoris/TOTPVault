#!/bin/bash

# Create templates directory
mkdir -p templates

# Create base.html
cat > templates/base.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>TOTP Authenticator</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 12px;
            padding: 40px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 500px;
            width: 100%;
        }
        h1 { color: #333; margin-bottom: 30px; text-align: center; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 8px; color: #555; font-weight: 500; }
        input, select {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        input:focus, select:focus {
            outline: none;
            border-color: #667eea;
        }
        button {
            width: 100%;
            padding: 14px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.3s;
        }
        button:hover { background: #5568d3; }
        button.secondary {
            background: #e0e0e0;
            color: #333;
            margin-top: 10px;
        }
        button.secondary:hover { background: #d0d0d0; }
        button.delete {
            background: #f44336;
            padding: 8px 16px;
            width: auto;
            font-size: 14px;
        }
        button.delete:hover { background: #d32f2f; }
        .error { color: #f44336; margin-top: 10px; text-align: center; }
        .success { color: #4caf50; margin-top: 10px; text-align: center; }
        .totp-display {
            text-align: center;
            margin: 20px 0;
            padding: 30px;
            background: #f5f5f5;
            border-radius: 8px;
        }
        .totp-code {
            font-size: 48px;
            font-weight: bold;
            letter-spacing: 8px;
            color: #667eea;
            font-family: 'Courier New', monospace;
        }
        .totp-timer {
            margin-top: 10px;
            color: #666;
            font-size: 14px;
        }
        .service-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px;
            background: #f9f9f9;
            border-radius: 6px;
            margin-bottom: 10px;
        }
        .service-name { font-weight: 500; color: #333; }
        .add-form {
            background: #f5f5f5;
            padding: 20px;
            border-radius: 8px;
            margin-top: 20px;
        }
        .header-actions {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    {% block content %}{% endblock %}
</body>
</html>
EOF

# Create setup.html
cat > templates/setup.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<div class="container">
    <h1>🔐 Setup Authenticator</h1>
    <p style="text-align: center; color: #666; margin-bottom: 30px;">
        Create your master password to secure your TOTP secrets
    </p>
    <form id="setupForm">
        <div class="form-group">
            <label>Master Password</label>
            <input type="password" id="password" required minlength="8" placeholder="Minimum 8 characters">
        </div>
        <div class="form-group">
            <label>Confirm Password</label>
            <input type="password" id="confirmPassword" required minlength="8">
        </div>
        <button type="submit">Create Account</button>
        <div id="message" class="error"></div>
    </form>
</div>
<script>
document.getElementById('setupForm').onsubmit = async (e) => {
    e.preventDefault();
    const pwd = document.getElementById('password').value;
    const confirm = document.getElementById('confirmPassword').value;
    const msg = document.getElementById('message');
    
    if (pwd !== confirm) {
        msg.textContent = 'Passwords do not match';
        return;
    }
    
    const res = await fetch('/api/setup', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({password: pwd})
    });
    
    if (res.ok) {
        window.location.href = '/';
    } else {
        const data = await res.json();
        msg.textContent = data.error;
    }
};
</script>
{% endblock %}
EOF

# Create login.html
cat > templates/login.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<div class="container">
    <h1>🔐 TOTP Authenticator</h1>
    <p style="text-align: center; color: #666; margin-bottom: 30px;">
        Enter your master password
    </p>
    <form id="loginForm">
        <div class="form-group">
            <label>Password</label>
            <input type="password" id="password" required autofocus>
        </div>
        <button type="submit">Login</button>
        <div id="message" class="error"></div>
    </form>
</div>
<script>
document.getElementById('loginForm').onsubmit = async (e) => {
    e.preventDefault();
    const pwd = document.getElementById('password').value;
    
    const res = await fetch('/api/login', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({password: pwd})
    });
    
    if (res.ok) {
        window.location.href = '/';
    } else {
        document.getElementById('message').textContent = 'Invalid password';
    }
};
</script>
{% endblock %}
EOF

# Create index.html
cat > templates/index.html << 'EOF'
{% extends "base.html" %}
{% block content %}
<div class="container">
    <div class="header-actions">
        <h1 style="margin: 0;">🔐 Authenticator</h1>
        <button class="secondary" onclick="logout()" style="width: auto; padding: 8px 20px;">Logout</button>
    </div>
    
    <div class="form-group">
        <label>Select Service</label>
        <select id="serviceSelect">
            <option value="">-- Select a service --</option>
        </select>
    </div>
    
    <button onclick="generateCode()" id="generateBtn" disabled>Generate Code</button>
    
    <div id="totpDisplay" class="totp-display" style="display: none;">
        <div class="totp-code" id="totpCode">------</div>
        <div class="totp-timer" id="totpTimer">Expires in: --s</div>
    </div>
    
    <div class="add-form">
        <h3 style="margin-bottom: 15px;">Add New Service</h3>
        <div class="form-group">
            <label>Service Name</label>
            <input type="text" id="newService" placeholder="e.g., GitHub, Gmail">
        </div>
        <div class="form-group">
            <label>Secret Key</label>
            <input type="text" id="newSecret" placeholder="Base32 encoded secret">
        </div>
        <button onclick="addService()">Add Service</button>
        <div id="addMessage"></div>
    </div>
    
    <div id="servicesList" style="margin-top: 30px;"></div>
</div>

<script>
let currentInterval = null;

async function loadServices() {
    const res = await fetch('/api/secrets');
    const data = await res.json();
    const select = document.getElementById('serviceSelect');
    const list = document.getElementById('servicesList');
    
    select.innerHTML = '<option value="">-- Select a service --</option>';
    list.innerHTML = '';
    
    data.secrets.forEach(service => {
        const opt = document.createElement('option');
        opt.value = service;
        opt.textContent = service;
        select.appendChild(opt);
        
        const item = document.createElement('div');
        item.className = 'service-item';
        item.innerHTML = `
            <span class="service-name">${service}</span>
            <button class="delete" onclick="deleteService('${service}')">Delete</button>
        `;
        list.appendChild(item);
    });
    
    document.getElementById('generateBtn').disabled = data.secrets.length === 0;
}

document.getElementById('serviceSelect').onchange = (e) => {
    document.getElementById('generateBtn').disabled = !e.target.value;
};

async function generateCode() {
    const service = document.getElementById('serviceSelect').value;
    if (!service) return;
    
    if (currentInterval) clearInterval(currentInterval);
    
    const display = document.getElementById('totpDisplay');
    display.style.display = 'block';
    
    let lastCode = null;
    
    async function updateCode() {
        try {
            const res = await fetch(`/api/totp/${encodeURIComponent(service)}`);
            if (!res.ok) {
                console.error('Failed to fetch TOTP');
                return;
            }
            const data = await res.json();
            
            // Only update the code if it has changed
            if (data.code !== lastCode) {
                document.getElementById('totpCode').textContent = data.code;
                lastCode = data.code;
            }
            
            // Always update the timer
            document.getElementById('totpTimer').textContent = `Expires in: ${data.remaining}s`;
        } catch (error) {
            console.error('Error fetching TOTP:', error);
        }
    }
    
    await updateCode();
    currentInterval = setInterval(updateCode, 1000);
}

async function addService() {
    const service = document.getElementById('newService').value.trim();
    const secret = document.getElementById('newSecret').value.trim();
    const msg = document.getElementById('addMessage');
    
    if (!service || !secret) {
        msg.className = 'error';
        msg.textContent = 'Please fill in both fields';
        return;
    }
    
    const res = await fetch('/api/secrets', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({service, secret})
    });
    
    if (res.ok) {
        msg.className = 'success';
        msg.textContent = 'Service added successfully!';
        document.getElementById('newService').value = '';
        document.getElementById('newSecret').value = '';
        loadServices();
        setTimeout(() => msg.textContent = '', 3000);
    } else {
        const data = await res.json();
        msg.className = 'error';
        msg.textContent = data.error;
    }
}

async function deleteService(service) {
    if (!confirm(`Delete ${service}?`)) return;
    
    await fetch(`/api/secrets/${encodeURIComponent(service)}`, {method: 'DELETE'});
    loadServices();
}

async function logout() {
    await fetch('/api/logout', {method: 'POST'});
    window.location.href = '/';
}

loadServices();
</script>
{% endblock %}
EOF

echo "Templates created successfully!"
