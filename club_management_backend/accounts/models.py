import uuid
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.utils import timezone


# ---------------------------------------------------------------------------
# Custom User Manager
# ---------------------------------------------------------------------------

class UserManager(BaseUserManager):
    """Manager for the custom User model that uses email as the username."""

    def create_user(self, email, full_name='', password=None, **extra_fields):
        if not email:
            raise ValueError('Email address is required.')
        email = self.normalize_email(email)
        extra_fields.setdefault('is_active', True)
        user = self.model(email=email, full_name=full_name, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, email, full_name='', password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', User.Role.ADMIN)
        user = self.create_user(email, full_name, **extra_fields)
        if password:
            user.set_password(password)
            user.save(using=self._db)
        return user


# ---------------------------------------------------------------------------
# Custom User Model
# ---------------------------------------------------------------------------

class User(AbstractBaseUser, PermissionsMixin):
    """
    Custom user model for ClubSphere.
    Email is used as the login identifier (passwordless via OTP).
    """

    class Role(models.TextChoices):
        STUDENT = 'student', 'Student'
        CLUB_HEAD = 'club_head', 'Club Head'
        ADMIN = 'admin', 'Admin'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    full_name = models.CharField(max_length=255, blank=True)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20, blank=True, null=True, db_index=True)
    roll_number = models.CharField(max_length=30, blank=True, null=True, unique=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.STUDENT)
    points = models.PositiveIntegerField(default=0)
    department = models.CharField(max_length=100, blank=True, default='')
    year_of_study = models.CharField(max_length=20, blank=True, default='')
    bio = models.TextField(blank=True, default='')
    avatar_url = models.URLField(blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name']

    class Meta:
        db_table = 'users'
        ordering = ['-created_at']

    def __str__(self):
        return self.email


# ---------------------------------------------------------------------------
# OTP Verification Model
# ---------------------------------------------------------------------------

class OTPVerification(models.Model):
    """Stores one-time passwords sent to users for passwordless login."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='otps',
    )
    otp_code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    class Meta:
        db_table = 'otp_verifications'
        ordering = ['-created_at']

    def is_valid(self):
        """Return True if OTP has not been used and has not expired."""
        return not self.is_used and timezone.now() < self.expires_at

    def __str__(self):
        return f'OTP for {self.user.email} – used={self.is_used}'
