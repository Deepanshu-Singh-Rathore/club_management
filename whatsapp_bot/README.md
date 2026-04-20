# Club Management WhatsApp Bot

A WhatsApp bot built with [whatsapp-web.js](https://github.com/pedroslopez/whatsapp-web.js) that lets students and club heads interact with the Club Management System directly from WhatsApp.

## Features

| Command | Description |
|---|---|
| `!help` | Show all available commands |
| `!events` | List upcoming events |
| `!clubs` | List all clubs with member count |
| `!login <OTP>` | Login using OTP from the college portal |
| `!status <event-id>` | Check registration status for an event |
| `!register <event-id>` | Apply for an event |
| `!notifications` | View latest notifications |

## Setup

### 1. Install dependencies

```bash
cd whatsapp_bot
npm install
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env`:
- `DJANGO_API_URL` – URL of your running Django backend (default: `http://127.0.0.1:8000/api`)
- `BOT_API_TOKEN` – JWT token for the bot's service account (create a user with `admin` role in Django admin and log in via `/api/auth/login/` to get a token)

To create the token, run this after the backend is up:

```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
	-H "Content-Type: application/json" \
	-d '{"email": "your_admin_email@example.com", "password": "your_password"}'
```

Use the `access` token from the response as `BOT_API_TOKEN`.

### 3. Start the bot

```bash
npm start
```

A QR code will appear in the terminal. Scan it with WhatsApp (the phone number you want the bot to run from) via **Linked Devices**.

### 4. Keep alive (production)

Use [PM2](https://pm2.keymetrics.io/) to keep the bot running:

```bash
npm install -g pm2
pm2 start index.js --name club-bot
pm2 save
```

## Login Flow

Students need to:
1. Request an OTP from the college portal (email).
2. Send `!login <OTP>` to the bot on WhatsApp.
3. Reply with their college email address when prompted.

The bot exchanges the OTP for a JWT and stores the session in memory for the current bot session.

## Notes

- The bot uses `LocalAuth` strategy, so session data is stored in `.wwebjs_auth/` (gitignored).
- Restart the bot and re-scan QR if the session expires.
- Only **students** can register for events (`!register`); club heads and admins manage approvals via the Django admin panel or API.
