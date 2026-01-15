Hereâ€™s a clean, professional `README.md` you can use for your TOTPVault project:

---

# TOTPVault â€” Secure TOTP Authenticator

A self-hosted, password-protected TOTP (Time-Based One-Time Password) authenticator built with Python and Flask. Store and generate 2FA codes locally â€” no cloud dependency, no third-party apps.

## Features

- í ½í´ Master password encryption using PBKDF2-HMAC-SHA256
- í ½í´’ TOTP secrets encrypted with Fernet (AES-128-CBC)
- í ½í¶¥ï¸ Web UI for adding, viewing, and deleting services
- â±ï¸ Real-time TOTP code generator with countdown timer
- í ½í³ Data stored locally in `/data` (config.json + secrets.enc)
- í ½í°³ Docker-ready with compose support

## Installation

### Prerequisites

- Python 3.8+
- Docker (optional, for containerized deployment)

### Local Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/taltoris/TOTPVault.git
   cd TOTPVault
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the app:
   ```bash
   python app.py
   ```

4. Open [http://localhost:5002](http://localhost:5002) in your browser and set up your master password.

### Docker Setup

1. Build and run the container:
   ```bash
   docker-compose up --build
   ```

2. Access the app at [http://localhost:5002](http://localhost:5002)

> í ½í²¡ The `data/` directory is mounted as a volume, so your secrets persist between restarts.

## Security Notes

- Your master password is never stored in plaintext â€” only a hashed key derived from it.
- All secrets are encrypted at rest using a unique salt per installation.
- Never share your master password or exported secret keys.
- This app is designed for personal use. For enterprise deployments, consider additional hardening (HTTPS, rate limiting, etc.).

## Data Storage

All sensitive data is stored in:
- `/data/config.json` â€” contains password hash and salt
- `/data/secrets.enc` â€” encrypted TOTP secrets

> These files are ignored in `.dockerignore` and `.gitignore` by default to prevent accidental exposure.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what youâ€™d like to change.

## License

MIT

