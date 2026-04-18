# ClubSphere – Local Setup Guide (Windows)

Follow these steps in order to get the backend and Flutter frontend running on your machine.

---

## Prerequisites

Install all of these before starting. Use the exact versions listed.

| Tool | Version | Download |
|---|---|---|
| Python | 3.13.x | https://www.python.org/downloads/ |
| PostgreSQL | 18.x | https://www.postgresql.org/download/windows/ |
| Flutter SDK | 3.22.2 | https://docs.flutter.dev/get-started/install/windows |
| Git | Latest | https://git-scm.com/download/win |

> **Python install tip:** During installation check **"Add Python to PATH"**.
>
> **PostgreSQL install tip:** When the installer asks for a password, set it to `root` (to match the project config). Note down the port — it should be `5432`.
>
> **Flutter install tip:** Follow the Windows setup guide linked above. After installing, add the `flutter/bin` folder to your system PATH.

---

## 1. Clone the Repository

Open **Command Prompt** or **PowerShell** and run:

```
git clone <your-repo-url>
cd club_project
```

---

## 2. Backend Setup (Django + PostgreSQL)

### 2a. Create the PostgreSQL Database

Open **pgAdmin** (installed with PostgreSQL) or the **SQL Shell (psql)** shortcut and run:

```sql
CREATE DATABASE club_management;
```

If using the SQL Shell, connect first with user `postgres` and your password (`root`), then run the command above.

### 2b. Create and Activate Virtual Environment

```
cd club_management_backend
python -m venv venv
venv\Scripts\activate
```

Your terminal prompt should now show `(venv)` at the start.

### 2c. Install Dependencies

```
pip install -r requirements.txt
```

### 2d. Create the `.env` File

Create a file called `.env` inside the `club_management_backend` folder. Copy the contents below exactly — only change `DB_PASSWORD` if you used a different PostgreSQL password during installation:

```
SECRET_KEY=django-insecure-change-this-to-something-secret-in-production

DEBUG=True

ALLOWED_HOSTS=127.0.0.1,localhost,10.0.2.2

DB_NAME=club_management
DB_USER=postgres
DB_PASSWORD=root
DB_HOST=localhost
DB_PORT=5432

EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=testerdeveloper05@gmail.com
EMAIL_HOST_PASSWORD=zyvtclazsoiauloe
DEFAULT_FROM_EMAIL=ClubSphere <testerdeveloper05@gmail.com>
```

### 2e. Apply Migrations

```
python manage.py migrate
```

You should see a list of migrations applying with `OK` next to each one.

### 2f. Seed Test Data

```
python manage.py seed_data
```

This creates users, clubs, events, and registrations so you have data to work with right away.

**Login credentials loaded by seed:**

| Role | Email | Password |
|---|---|---|
| Admin | admin@clubsphere.com | admin123 |
| Club Head | rahul.kapoor@college.edu | head123 |
| Club Head | meera.nambiar@college.edu | head123 |
| Student | aarav.sharma@college.edu | student123 |
| Student | priya.patel@college.edu | student123 |

> All club heads use password `head123`. All students use `student123`.

### 2g. Start the Backend Server

```
python manage.py runserver
```

The backend will be available at `http://127.0.0.1:8000`. Keep this terminal open while using the app.

---

## 3. Flutter Frontend Setup

Open a **new** terminal window for this section (keep the backend terminal running).

### 3a. Navigate to the Flutter App

```
cd club_management_app
```

### 3b. Install Flutter Dependencies

```
flutter pub get
```

### 3c. Verify Flutter is Set Up

```
flutter doctor
```

Fix any issues it reports before continuing (the most important ones are the Flutter SDK and Chrome/Edge browser).

### 3d. Run the App

**On Chrome (recommended, works without extra installs):**
```
flutter run -d chrome
```

**On Edge:**
```
flutter run -d edge
```

The app will open in your browser automatically.

> **Note:** The app is configured to connect to `http://127.0.0.1:8000` which is where the Django backend runs locally. Make sure the backend server (step 2g) is running before using the app.

---

## 4. Running Both at the Same Time

You need **two terminal windows** open simultaneously:

**Terminal 1 — Backend:**
```
cd club_management_backend
venv\Scripts\activate
python manage.py runserver
```

**Terminal 2 — Frontend:**
```
cd club_management_app
flutter run -d chrome
```

---

## 5. Troubleshooting

**`psycopg2` install fails**
> Make sure PostgreSQL is installed and its `bin` folder is in your PATH, or install the binary version: `pip install psycopg2-binary`

**`flutter: command not found`**
> Flutter's `bin` folder is not in your PATH. Re-run the Flutter installer or add it manually: System Properties → Environment Variables → Path → Add `C:\flutter\bin` (or wherever you extracted Flutter).

**`flutter run` says no devices found**
> Run `flutter doctor` to see what's missing. For Chrome, make sure Google Chrome is installed.

**App shows connection error / can't reach backend**
> Make sure the Django server is running (`python manage.py runserver`) before opening the app.

**Migration error about inconsistent history**
> Drop and recreate the database, then re-run migrations:
> ```
> -- In pgAdmin or psql:
> DROP DATABASE club_management;
> CREATE DATABASE club_management;
> ```
> Then: `python manage.py migrate`

**Port 8000 already in use**
> Run on a different port: `python manage.py runserver 8001`
> Then update `lib/services/api_service.dart` line 9: change `8000` to `8001`.

---

## 6. WhatsApp Bot Quick Start

Use this when you want to start the bot manually later.

### 6a. Start the Django backend

Open one terminal and run:

```
cd club_management_backend
venv\Scripts\activate
python manage.py runserver
```

### 6b. Start the bot

Open a second terminal and run:

```
cd whatsapp_bot
npm start
```

Make sure `.env` in `whatsapp_bot` still points to the correct Django API URL and JWT token.

### 6c. If you are testing WhatsApp sandbox delivery

1. Start ngrok on the bot port:

```
ngrok http 3000
```

2. Copy the ngrok HTTPS URL and set it as the Twilio sandbox webhook for `/webhook`.
3. From your WhatsApp account, join the Twilio sandbox using the code shown in the Twilio Console.
4. Send `!events` or `!clubs` to confirm the bot is responding.
