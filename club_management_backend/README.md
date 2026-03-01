# ClubSphere – Backend Setup Guide

## Tech Stack
- Python 3.10+, Django 4.2, Django REST Framework
- PostgreSQL + psycopg2-binary
- SimpleJWT (passwordless OTP auth)
- django-environ, django-cors-headers

---

## 1. Install Dependencies

```bash
cd club_management_backend
pip install -r requirements.txt
```

---

## 2. PostgreSQL Setup

```sql
-- Run in psql as a superuser
CREATE DATABASE clubsphere_db;
```

---

## 3. Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

Key variables:

| Variable | Description |
|---|---|
| `SECRET_KEY` | Django secret key |
| `DEBUG` | `True` in dev, `False` in prod |
| `DB_PASSWORD` | PostgreSQL password |
| `EMAIL_BACKEND` | Use `console.EmailBackend` for dev |

---

## 4. Migrations

```bash
python manage.py makemigrations accounts
python manage.py makemigrations clubs
python manage.py migrate
```

---

## 5. Create Superuser

```bash
python manage.py createsuperuser
```

---

## 6. Run Development Server

```bash
python manage.py runserver
```

---

## API Endpoints

### Auth (public)
| Method | URL | Description |
|--------|-----|-------------|
| POST | `/api/auth/request-otp/` | Send OTP to email |
| POST | `/api/auth/verify-otp/` | Verify OTP → get JWT tokens |
| POST | `/api/auth/refresh/` | Refresh JWT access token |
| GET/PATCH | `/api/auth/me/` | View/update own profile |

### Clubs (JWT required)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/clubs/` | List all clubs |
| POST | `/api/clubs/` | Create club (club_head/admin) |
| GET | `/api/clubs/{id}/` | Club detail |
| PUT | `/api/clubs/{id}/` | Update club (owner/admin) |
| DELETE | `/api/clubs/{id}/` | Delete club (admin only) |
| POST | `/api/clubs/{id}/join/` | Join a club |

### Events (JWT required)
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api/events/` | List all events (filter: `?club=<id>`) |
| POST | `/api/events/` | Create event (club_head/admin) |
| GET | `/api/events/{id}/` | Event detail |
| PUT | `/api/events/{id}/` | Update event (owner/admin) |
| DELETE | `/api/events/{id}/` | Delete event (owner/admin) |

---

## OTP Login Flow (Flutter)

1. `POST /api/auth/request-otp/` with `{"email": "user@college.edu"}`
2. User receives OTP in email (or console in dev)
3. `POST /api/auth/verify-otp/` with `{"email": "...", "otp": "123456"}`
4. Response contains `access`, `refresh`, and `user` object
5. Include `Authorization: Bearer <access>` header on all protected requests
6. Use `POST /api/auth/refresh/` with `{"refresh": "..."}` to get a new access token

---

## Role Permissions

| Role | Can Do |
|------|--------|
| `student` | View clubs/events, join clubs |
| `club_head` | + Create clubs/events for their own club |
| `admin` | Full access |
