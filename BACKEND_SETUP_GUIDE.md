# ClubSphere Backend - Setup & API Guide

## ✅ Current Status

- **Database**: SQLite (development) - Fully operational ✓
- **Migrations**: All applied successfully ✓
- **Tables**: 17 tables created including users, clubs, events ✓
- **Test Data**: Sample admin, club head, students created ✓
- **Functionality**: All models and JWT auth verified ✓

---

## 🚀 Running the Backend

### Option 1: Start Django Development Server

```bash
cd club_management_backend
python manage.py runserver
```

The backend will start on: `http://127.0.0.1:8000/`

### Option 2: Specify Port

```bash
python manage.py runserver 8000
```

---

## 🧪 Testing API Endpoints

### Using Postman or cURL

#### 1. **Login as Admin** (Get JWT Token)
```bash
POST http://127.0.0.1:8000/api/login/

Body (JSON):
{
  "email": "admin@test.com",
  "password": "admin123"
}

Response:
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "role": "admin",
  "user": { ... }
}
```

#### 2. **Register New Student**
```bash
POST http://127.0.0.1:8000/api/register/

Body (JSON):
{
  "full_name": "John Doe",
  "email": "john@example.com",
  "password": "secure123",
  "roll_number": "2024001",
  "role": "student"
}

Response: 201 Created
```

#### 3. **List All Clubs** (Public - No Auth Needed)
```bash
GET http://127.0.0.1:8000/api/clubs/

Response:
[
  {
    "id": "f5673660-d0e4-41ee-8d3a-8325d0e4d15c",
    "name": "Technology Club",
    "description": "For all tech enthusiasts",
    "created_by": { ... },
    "pending_requests": 1,
    "created_at": "2026-03-18T..."
  }
]
```

#### 4. **Create Join Request** (Student - Requires Auth)
```bash
POST http://127.0.0.1:8000/api/join-requests/

Header:
Authorization: Bearer <your_access_token>

Body (JSON):
{
  "club_id": "f5673660-d0e4-41ee-8d3a-8325d0e4d15c"
}

Response: 201 Created
{
  "id": "...",
  "user": { ... },
  "club": { ... },
  "status": "pending",
  "created_at": "..."
}
```

#### 5. **Approve Join Request** (Club Head - Requires Auth)
```bash
POST http://127.0.0.1:8000/api/join-requests/{join_request_id}/approve/

Header:
Authorization: Bearer <club_head_token>

Response: 200 OK
```

#### 6. **List Events** (Authenticated)
```bash
GET http://127.0.0.1:8000/api/events/

Header:
Authorization: Bearer <your_access_token>

Response: 200 OK
[
  {
    "id": "...",
    "title": "Tech Meetup",
    "description": "Monthly tech meetup",
    "event_date": "2026-03-25T...",
    "club": "...",
    "club_name": "Technology Club",
    "participant_count": 2,
    "created_at": "..."
  }
]
```

#### 7. **Register for Event** (Student - Requires Auth)
```bash
POST http://127.0.0.1:8000/api/events/{event_id}/register/

Header:
Authorization: Bearer <student_token>

Response: 201 Created
```

#### 8. **Get Leaderboard** (Public - No Auth Needed)
```bash
GET http://127.0.0.1:8000/api/leaderboard/

Response: 200 OK
[
  {
    "rank": 1,
    "id": "...",
    "full_name": "Admin User",
    "points": 0,
    "roll_number": ""
  }
]
```

---

## 🔑 Test User Credentials

| Role | Email | Password | Roll Number |
|------|-------|----------|-------------|
| Admin | admin@test.com | admin123 | - |
| Club Head | clubhead@test.com | ch123456 | - |
| Student 1 | student1@test.com | st123456 | 2024001 |
| Student 2 | student2@test.com | st123456 | 2024002 |

---

## 📊 Database Tables Created

```
✓ users                      (custom User model)
✓ otp_verifications          (OTP login)
✓ clubs                      (club management)
✓ join_requests              (join approvals)
✓ events                     (events)
✓ event_registrations        (event participants)
✓ auth_*                     (Django auth)
✓ django_*                   (Django framework)
```

---

## 🔐 Authentication Tokens

All endpoints (except public ones) require JWT token in header:

```
Authorization: Bearer <access_token>
```

**Token Lifespan**:
- Access Token: 15 minutes
- Refresh Token: 7 days

To refresh token:
```bash
POST http://127.0.0.1:8000/api/refresh/

Body (JSON):
{
  "refresh": "<refresh_token>"
}

Response:
{
  "access": "<new_access_token>"
}
```

---

## 📝 API Response Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Request successful |
| 201 | Created - Resource created |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Missing/invalid token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |

---

## 🔄 Switching to PostgreSQL (Production)

When ready to use PostgreSQL:

1. **Install PostgreSQL** on your system
2. **Create database**:
   ```sql
   CREATE DATABASE clubsphere_db;
   CREATE USER postgres WITH PASSWORD 'your_secure_password';
   ALTER ROLE postgres SET client_encoding TO 'utf8';
   ALTER ROLE postgres SET default_transaction_isolation TO 'read committed';
   ALTER ROLE postgres SET default_transaction_deferrable TO on;
   ALTER ROLE postgres SET timezone TO 'UTC';
   GRANT ALL PRIVILEGES ON DATABASE clubsphere_db TO postgres;
   ```

3. **Update `.env`**:
   ```
   DEBUG=False
   DB_NAME=clubsphere_db
   DB_USER=postgres
   DB_PASSWORD=your_secure_password
   DB_HOST=localhost
   DB_PORT=5432
   ```

4. **Settings.py already supports both** - when `DEBUG=False`, it uses PostgreSQL

5. **Migrate**:
   ```bash
   pip install psycopg2-binary
   python manage.py migrate
   ```

---

## 🛠️ Useful Commands

```bash
# Create new superuser
python manage.py createsuperuser

# Access Django admin
http://127.0.0.1:8000/admin/

# Generate new migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Run tests
python manage.py test

# Check system
python manage.py check

# Django shell (interactive Python with Django context)
python manage.py shell
```

---

## 📱 Next: Flutter Integration

Once backend is running:

1. Update Flutter's `api_service.dart` with correct backend URL
2. Set `_baseUrl = 'http://127.0.0.1:8000/api'` (or your machine IP for emulator/device)
3. For Android emulator: Use `http://10.0.2.2:8000/api`
4. For iOS simulator: Use `http://127.0.0.1:8000/api`
5. For real device: Use your machine's LAN IP: `http://192.168.x.x:8000/api`

---

## ⚠️ Common Issues

**CORS Errors?**
- Django CORS is configured in settings.py
- Make sure Flutter client is in `ALLOWED_ORIGINS` or `CORS_ALLOW_ALL_ORIGINS=True` for dev

**Database locked?**
- Delete `db.sqlite3` and re-run `python manage.py migrate --run-syncdb`

**Token expired?**
- Use the refresh token endpoint to get a new access token

---

## 📞 Quick Support

All API endpoints are documented in `core/urls.py` and individual app `urls.py` files.

For more details, check:
- `accounts/views.py` - Auth endpoints
- `clubs/views.py` - Club & join request endpoints
- `events/views.py` - Event endpoints
