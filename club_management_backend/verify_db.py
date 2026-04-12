#!/usr/bin/env python
"""Verify database tables and create test data."""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection
from django.contrib.auth import get_user_model
from clubs.models import Club, JoinRequest
from events.models import Event, EventRegistration

User = get_user_model()

# List all tables
cursor = connection.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
tables = [row[0] for row in cursor.fetchall()]

print("\n" + "="*70)
print("DATABASE VERIFICATION REPORT")
print("="*70)
print(f"\nTotal Tables: {len(tables)}\n")
print("Tables found:")
for table in tables:
    print(f"  ✓ {table}")

# Check critical tables
critical_tables = ['users', 'clubs', 'join_requests', 'events', 'event_registrations', 'otp_verifications']
missing = [t for t in critical_tables if t not in tables]
if missing:
    print(f"\n⚠️  Missing critical tables: {missing}")
else:
    print(f"\n✓ All critical tables present!")

# Count key data
print("\n" + "-"*70)
print("DATA SUMMARY")
print("-"*70)
print(f"Users:                  {User.objects.count()}")
print(f"Clubs:                  {Club.objects.count()}")
print(f"Join Requests:          {JoinRequest.objects.count()}")
print(f"Events:                 {Event.objects.count()}")
print(f"Event Registrations:    {EventRegistration.objects.count()}")

# List admin users
admins = User.objects.filter(role='admin')
print(f"\nAdmin Users: {admins.count()}")
for admin in admins:
    print(f"  - {admin.email} (verified: {admin.is_verified})")

print("\n" + "="*70)
print("✓ Database verification complete!")
print("="*70 + "\n")
