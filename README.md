
# ClubSphere – College Club Management System

Full-stack system: **Django REST** backend + **Flutter** mobile frontend + **WhatsApp bot**.

---

## Architecture

```
club_project/
├── club_management_backend/   # Django REST API
│   ├── accounts/              # Auth, Users, Leaderboard, Admin endpoints
│   ├── clubs/                 # Clubs, Events, Registrations, Notifications
│   │   ├── twilio_webhook.py  # Twilio WhatsApp handler
│   │   └── bot_urls.py        # /api/bot/ routes
│   ├── core/                  # settings.py, urls.py
│   ├── .env.example
│   └── requirements.txt
├── club_management_app/       # Flutter mobile app
│   └── lib/
│       ├── models/            # User, Club, Event, EventRegistration, Notification
│       ├── providers/         # AuthProvider (Provider package)
│       ├── services/          # ApiService — all HTTP calls
│       └── screens/
│           ├── login_screen.dart
│           ├── signup_screen.dart
│           ├── home_screen.dart       # Dashboard + bottom nav
│           ├── clubs_screen.dart
│           ├── club_detail_screen.dart
│           ├── events_screen.dart
│           ├── event_detail_screen.dart
│           ├── leaderboard_screen.dart
│           ├── profile_screen.dart
│           ├── notifications_screen.dart
│           ├── admin/
│           │   └── admin_dashboard_screen.dart   # Manage users & roles
│           └── clubhead/
│               ├── create_event_screen.dart
│               └── pending_approvals_screen.dart
└── whatsapp_bot/              # Node.js bot (whatsapp-web.js)
    └── index.js
```

---

## Database Schema

| Table | Key columns |
|---|---|
| `users` | id (UUID), email, full_name, role, points, roll_number |
| `otp_verifications` | user_id, otp_code, expires_at, is_used |
| `clubs` | id (UUID), name, description, created_by |
| `memberships` | user_id, club_id |
| `events` | id (UUID), title, event_date, club_id, capacity, status |
| `event_registrations` | id, user_id, event_id, status (pending/approved/rejected) |
| `notifications` | user_id, message, type, is_read |

---

## API Reference

### Auth — `/api/auth/`
| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `register/` | POST | — | Create student account |
| `login/` | POST | — | Email + password → JWT |
| `refresh/` | POST | — | Refresh access token |
| `me/` | GET/PATCH | Bearer | View / update profile |
| `leaderboard/` | GET | — | Top 50 by points |
| `admin/stats/` | GET | Admin | Dashboard counts |
| `admin/users/` | GET | Admin | List all users |
| `admin/users/<id>/` | PATCH/DELETE | Admin | Change role / deactivate |

### Clubs & Events — `/api/clubs/`
| Endpoint | Method | Auth | Description |
|---|---|---|---|
| `` | GET | Optional | List clubs |
| `` | POST | ClubHead/Admin | Create club |
| `<id>/join/` | POST | Bearer | Join club |
| `events/` | GET | Bearer | List events (`?club=<id>`) |
| `events/` | POST | ClubHead/Admin | Create event |
| `events/my/` | GET | Bearer | My registrations |
| `events/<id>/apply/` | POST | Student | Apply |
| `events/<id>/pending/` | GET | ClubHead/Admin | Pending list |
| `events/<id>/approve/` | POST | ClubHead/Admin | Approve (+10 pts) |
| `events/<id>/reject/` | POST | ClubHead/Admin | Reject |
| `notifications/` | GET | Bearer | My notifications |
| `notifications/<id>/read/` | POST | Bearer | Mark read |

### WhatsApp Webhook — `POST /api/bot/whatsapp/`
Twilio sends messages here. Commands: `events`, `clubs`, `leaderboard`, `status`, `help`.

---

## Roles & Permissions

| Action | Student | Club Head | Admin |
|---|---|---|---|
| Register / Login | ✅ | ✅ | ✅ |
| Browse clubs & events | ✅ | ✅ | ✅ |
| Join a club | ✅ | — | — |
| Apply for an event | ✅ | — | — |
| Create club / event | — | ✅ | ✅ |
| Approve / reject registrations | — | ✅ | ✅ |
| Manage users (role, deactivate) | — | — | ✅ |
| View admin stats | — | — | ✅ |

---

## ▶️ Run Locally

### 1. Backend

```bash
cd club_management_backend

python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate

pip install -r requirements.txt

cp .env.example .env
# Edit .env — set DB_PASSWORD, SECRET_KEY

# Create the PostgreSQL database
createdb club_management

python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

API base: `http://127.0.0.1:8000/api/`

### 2. Flutter App

```bash
cd club_management_app
flutter pub get

# In lib/services/api_service.dart set _base:
#   Android emulator  → http://10.0.2.2:8000/api
#   iOS simulator     → http://127.0.0.1:8000/api
#   Real device       → http://<LAN-IP>:8000/api

flutter run
```

### 3. WhatsApp Bot (whatsapp-web.js)

```bash
cd whatsapp_bot
npm install

# Create .env
DJANGO_API_URL=http://127.0.0.1:8000/api
BOT_API_TOKEN=<service-account-JWT>

npm start   # Scan QR code with WhatsApp
```

#### Create the JWT for the bot

The bot needs a JWT from a Django user with the `admin` role.

Use this request after the backend is running:

```bash
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
    -H "Content-Type: application/json" \
    -d '{"email": "your_admin_email@example.com", "password": "your_password"}'
```

On Windows PowerShell, use `curl.exe` or `Invoke-RestMethod` if plain `curl` is aliased.

Copy the `access` token from the response into `BOT_API_TOKEN` in `whatsapp_bot/.env`.

---

## 🌐 Deployment

### Backend (Gunicorn + Nginx)

```bash
pip install gunicorn whitenoise
python manage.py collectstatic --no-input

gunicorn core.wsgi:application --bind 0.0.0.0:8000 --workers 3
```

Nginx proxy `/api/` → `127.0.0.1:8000`.

### Twilio WhatsApp Webhook

In the Twilio console set the **Incoming Message Webhook** to:
```
https://yourdomain.com/api/bot/whatsapp/
```

### Flutter Release Build

```bash
flutter build apk --release          # Android APK
flutter build appbundle --release    # Play Store bundle
flutter build ios --release          # iOS (macOS + Xcode required)
```

---

## 🔐 Environment Variables

See `club_management_backend/.env.example`.

| Variable | Description |
|---|---|
| `SECRET_KEY` | Django secret key |
| `DEBUG` | `True` dev / `False` prod |
| `DB_NAME / DB_USER / DB_PASSWORD` | PostgreSQL |
| `TWILIO_ACCOUNT_SID / TWILIO_AUTH_TOKEN` | Twilio credentials |
| `TWILIO_WHATSAPP_FROM` | Sandbox number (`whatsapp:+14155238886`) |
| `EVENT_APPROVAL_POINTS` | Points per approval (default 10) |
| `EMAIL_HOST_USER / EMAIL_HOST_PASSWORD` | SMTP for OTP emails |
=======
# test

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## My Contribution (Tamanna regar)
- **Login Screen:** Created a card-based UI with school icon and input fields.
- **Home Screen:** Added a Dashboard with Club cards and Bottom Navigation Bar.
- **Navigation:** Successfully connected Login button to the Home Screen.
>>>>>>> 4b870e1 (Initial commit: ClubSphere UI and Navigation)
