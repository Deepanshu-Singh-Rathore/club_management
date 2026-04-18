"""
Django settings for ClubSphere – College Club Management System.
"""

from pathlib import Path
from datetime import timedelta
import environ

# ------------------------------------------------------------------------------
# Base Directory
# ------------------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------
env = environ.Env(
    DEBUG=(bool, False)
)

environ.Env.read_env(BASE_DIR / ".env")

# ------------------------------------------------------------------------------
# Security
# ------------------------------------------------------------------------------
SECRET_KEY = env.str(
    "SECRET_KEY",
    default="django-insecure-change-this-in-production"
)

DEBUG = env.bool("DEBUG", default=True)

ALLOWED_HOSTS = env.list(
    "ALLOWED_HOSTS",
    default=["127.0.0.1", "localhost"]
)

# ------------------------------------------------------------------------------
# Application Definition
# ------------------------------------------------------------------------------
INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",

    # Third-party apps
    "rest_framework",
    "rest_framework_simplejwt",
    "corsheaders",

    # Local apps
    "accounts",
    "clubs",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",   # must stay at top
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "core.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "core.wsgi.application"

# ------------------------------------------------------------------------------
# Database (PostgreSQL)
# ------------------------------------------------------------------------------
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

# ------------------------------------------------------------------------------
# Custom User Model
# ------------------------------------------------------------------------------
AUTH_USER_MODEL = "accounts.User"

# ------------------------------------------------------------------------------
# Django REST Framework
# ------------------------------------------------------------------------------
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": (
        "rest_framework.permissions.IsAuthenticated",
    ),
    "DEFAULT_RENDERER_CLASSES": (
        "rest_framework.renderers.JSONRenderer",
    ),
    "DEFAULT_PARSER_CLASSES": (
        "rest_framework.parsers.JSONParser",
        "rest_framework.parsers.FormParser",
        "rest_framework.parsers.MultiPartParser",
    ),
}

# ------------------------------------------------------------------------------
# Simple JWT Configuration
# ------------------------------------------------------------------------------
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=60),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=7),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": False,
    "ALGORITHM": "HS256",
    "SIGNING_KEY": SECRET_KEY,
    "AUTH_HEADER_TYPES": ("Bearer",),
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
}

# ------------------------------------------------------------------------------
# CORS Configuration
# ------------------------------------------------------------------------------
CORS_ALLOW_ALL_ORIGINS = DEBUG

CORS_ALLOWED_ORIGINS = env.list(
    "CORS_ALLOWED_ORIGINS",
    default=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
)

# ------------------------------------------------------------------------------
# Email Configuration
# ------------------------------------------------------------------------------
EMAIL_BACKEND = env.str(
    "EMAIL_BACKEND",
    default="django.core.mail.backends.console.EmailBackend"
)

EMAIL_HOST = env.str("EMAIL_HOST", default="smtp.gmail.com")
EMAIL_PORT = env.int("EMAIL_PORT", default=587)
EMAIL_USE_TLS = env.bool("EMAIL_USE_TLS", default=True)
EMAIL_HOST_USER = env.str("EMAIL_HOST_USER", default="")
EMAIL_HOST_PASSWORD = env.str("EMAIL_HOST_PASSWORD", default="")
DEFAULT_FROM_EMAIL = env.str(
    "DEFAULT_FROM_EMAIL",
    default="ClubSphere <noreply@clubsphere.com>"
)

# ------------------------------------------------------------------------------
# Twilio / WhatsApp
# ------------------------------------------------------------------------------
TWILIO_ACCOUNT_SID = env.str("TWILIO_ACCOUNT_SID", default="")
TWILIO_AUTH_TOKEN = env.str("TWILIO_AUTH_TOKEN", default="")
TWILIO_WHATSAPP_FROM = env.str(
    "TWILIO_WHATSAPP_FROM",
    default="whatsapp:+14155238886"
)

# ------------------------------------------------------------------------------
# Leaderboard Points
# ------------------------------------------------------------------------------
EVENT_APPROVAL_POINTS = env.int("EVENT_APPROVAL_POINTS", default=10)

# ------------------------------------------------------------------------------
# Internationalization
# ------------------------------------------------------------------------------
LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

# ------------------------------------------------------------------------------
# Static Files
# ------------------------------------------------------------------------------
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"