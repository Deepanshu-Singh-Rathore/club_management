# ClubSphere Team Setup (Copy-Paste)

Use this after pulling the latest merged branch.

---

## 1) Clone / Pull Latest

```powershell
cd C:\path\to\your\workspace
git clone <repo-url> club_project
cd club_project
# OR if already cloned:
# git pull origin <your-branch>
```

---

## 2) Environment Variables

### Backend — `club_management_backend/.env`

```env
SECRET_KEY=any-random-string-at-least-50-chars
DEBUG=True
ALLOWED_HOSTS=127.0.0.1,localhost
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# PostgreSQL — use your cloud DB credentials
DB_NAME=club_management
DB_USER=postgres
DB_PASSWORD=<your password>
DB_HOST=<your cloud host or localhost>
DB_PORT=5432

# Email — keep console backend for demo (no real email needed)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend

# Twilio — only needed if showing WhatsApp bot
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886

EVENT_APPROVAL_POINTS=10
```

### WhatsApp Bot — `whatsapp_bot/.env` (only if demoing bot)

```env
DJANGO_API_URL=http://127.0.0.1:8000/api
BOT_API_TOKEN=<generate this after backend starts — see Step 4>
ACCOUNT_SID=<same as TWILIO_ACCOUNT_SID>
AUTH_TOKEN=<same as TWILIO_AUTH_TOKEN>
TWILIO_WHATSAPP_NUMBER=whatsapp:+14155238886
PORT=3000
```

### Flutter — base URL

In `lib/services/api_service.dart`, set `_base` based on how you run:

| Device | URL |
|---|---|
| Android emulator | `http://10.0.2.2:8000/api` |
| Real phone (same WiFi) | `http://<host LAN IP>:8000/api` |
| iOS simulator | `http://127.0.0.1:8000/api` |

---

## 3) Backend Setup (Django + PostgreSQL)

```powershell
cd club_management_backend

# Create venv (first time only)
python -m venv ..\.venv

# Activate venv (Windows)
(Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned) ; (& ..\.venv\Scripts\Activate.ps1)

pip install -r requirements.txt

# Create .env from template
Copy-Item .env.example .env
```

Edit `.env` and set at least:
- `SECRET_KEY`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_HOST`
- `DB_PORT`
- `ALLOWED_HOSTS=127.0.0.1,localhost`
- `DEBUG=True` (dev only)

Cloud DB note:
- This PR uses a cloud PostgreSQL database. Use the cloud credentials/host in `.env`.
- Do not run local DB creation commands unless you are intentionally using a local fallback.

Optional local fallback only:

```sql
CREATE DATABASE club_management;
```

Run migrations and start backend:

```powershell
cd C:\Users\deepa\College\club_project\club_management_backend
(Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned) ; (& C:\Users\deepa\College\club_project\.venv\Scripts\Activate.ps1)

python manage.py migrate
python manage.py createsuperuser
python manage.py runserver 127.0.0.1:8000
```

---

## 4) Flutter App Setup

In a new terminal:

```powershell
cd C:\Users\deepa\College\club_project\club_management_app
flutter pub get
```

Set API base URL in `lib/services/api_service.dart` (`_base`):
- Android emulator: `http://10.0.2.2:8000/api`
- iOS simulator: `http://127.0.0.1:8000/api`
- Real device: `http://<your-lan-ip>:8000/api`

Run app:

```powershell
flutter run
```

---

## 5) WhatsApp Bot Setup (Optional)

In a new terminal:

```powershell
cd C:\Users\deepa\College\club_project\whatsapp_bot
npm install
Copy-Item .env.example .env
```

Set in `whatsapp_bot/.env`:
- `DJANGO_API_URL=http://127.0.0.1:8000/api`
- `BOT_API_TOKEN=<access token of admin service account>`

Generate token from backend:

```powershell
curl.exe -X POST http://127.0.0.1:8000/api/auth/login/ -H "Content-Type: application/json" -d "{\"email\":\"your_admin_email@example.com\",\"password\":\"your_password\"}"
```

Start bot:

```powershell
npm start
```

Scan QR from WhatsApp Linked Devices.

---

## 6) Quick Health Check

Backend should pass these:

```powershell
cd C:\Users\deepa\College\club_project\club_management_backend
(Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned) ; (& C:\Users\deepa\College\club_project\.venv\Scripts\Activate.ps1)

python manage.py check
python manage.py showmigrations clubs
python manage.py migrate --plan
```

Expected:
- `System check identified no issues (0 silenced)`
- all `clubs` migrations checked `[X]`
- `No planned migration operations`
