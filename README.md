# TOTPVault — Secure TOTP Authenticator

A self-hosted, password-protected TOTP (Time-Based One-Time Password) authenticator built with Python and Flask. Store and generate 2FA codes locally — no cloud dependency, no third-party apps.

## Features

-  Master password encryption using PBKDF2-HMAC-SHA256
-  TOTP secrets encrypted with Fernet (AES-128-CBC)
-  Web UI for adding, viewing, and deleting services
-  Real-time TOTP code generator with countdown timer
-  Data stored locally in `/data` (config.json + secrets.enc)
-  Docker-ready with compose support

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

2. Build and run the container:
   ```bash
   docker compose up --build
   ```

3. Access the app at [http://localhost:5002](http://localhost:5002)

>  The `data/` directory is mounted as a volume, so your secrets persist between restarts.

## Security Notes

- Your master password is never stored in plaintext — only a hashed key derived from it.
- All secrets are encrypted at rest using a unique salt per installation.
- Never share your master password or exported secret keys.
- This app is designed for personal use. For enterprise deployments, consider additional hardening (HTTPS, rate limiting, etc.).

## Data Storage

All sensitive data is stored in:
- `/data/config.json` — contains password hash and salt
- `/data/secrets.enc` — encrypted TOTP secrets

> These files are ignored in `.dockerignore` and `.gitignore` by default to prevent accidental exposure.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you’d like to change.

## License

MIT

