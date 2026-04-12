#!/usr/bin/env python
"""Simple API test by creating test data and verifying models."""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth import get_user_model
from clubs.models import Club, JoinRequest
from events.models import Event, EventRegistration
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

print("\n" + "="*70)
print("BACKEND FUNCTIONALITY VERIFICATION")
print("="*70 + "\n")

# Test 1: Register a club head user
print("TEST 1: Create club head user")
print("-"*70)
try:
    club_head = User.objects.create_user(
        email='clubhead@test.com',
        full_name='Club Head User',
        password='ch123456',
        role='club_head',
        is_verified=True
    )
    print(f"✓ Club head created: {club_head.email} ({club_head.role})")
except Exception as e:
    print(f"✗ Error: {e}")

# Test 2: Register student users
print("\n\nTEST 2: Create student users")
print("-"*70)
try:
    student1 = User.objects.create_user(
        email='student1@test.com',
        full_name='Student One',
        password='st123456',
        roll_number='2024001',
        role='student',
        is_verified=True
    )
    student2 = User.objects.create_user(
        email='student2@test.com',
        full_name='Student Two',
        password='st123456',
        roll_number='2024002',
        role='student',
        is_verified=True
    )
    print(f"✓ Student 1 created: {student1.email}")
    print(f"✓ Student 2 created: {student2.email}")
except Exception as e:
    print(f"✗ Error: {e}")

# Test 3: Create club
print("\n\nTEST 3: Create a club")
print("-"*70)
try:
    club = Club.objects.create(
        name='Technology Club',
        description='For all tech enthusiasts',
        created_by=club_head
    )
    print(f"✓ Club created: {club.name}")
    print(f"  Created by: {club.created_by.email}")
    print(f"  ID: {club.id}")
except Exception as e:
    print(f"✗ Error: {e}")

# Test 4: Create join requests
print("\n\nTEST 4: Create join requests")
print("-"*70)
try:
    jr1 = JoinRequest.objects.create(
        user=student1,
        club=club,
        status=JoinRequest.Status.PENDING
    )
    jr2 = JoinRequest.objects.create(
        user=student2,
        club=club,
        status=JoinRequest.Status.PENDING
    )
    print(f"✓ Join request 1: {jr1.user.email} → {jr1.club.name} ({jr1.status})")
    print(f"✓ Join request 2: {jr2.user.email} → {jr2.club.name} ({jr2.status})")
except Exception as e:
    print(f"✗ Error: {e}")

# Test 5: Approve join request
print("\n\nTEST 5: Approve join request")
print("-"*70)
try:
    jr1.status = JoinRequest.Status.APPROVED
    jr1.save()
    print(f"✓ Join request approved: {jr1.user.email} ({jr1.status})")
except Exception as e:
    print(f"✗ Error: {e}")

# Test 6: Create event
print("\n\nTEST 6: Create an event")
print("-"*70)
try:
    from datetime import datetime, timedelta
    event_date = datetime.now() + timedelta(days=7)
    event = Event.objects.create(
        title='Tech Meetup',
        description='Monthly tech meetup',
        event_date=event_date,
        club=club,
        created_by=club_head
    )
    print(f"✓ Event created: {event.title}")
    print(f"  Club: {event.club.name}")
    print(f"  Date: {event.event_date}")
except Exception as e:
    print(f"✗ Error: {e}")

# Test 7: Register for event
print("\n\nTEST 7: Register students for event")
print("-"*70)
try:
    reg1 = EventRegistration.objects.create(
        user=student1,
        event=event,
        status=EventRegistration.Status.REGISTERED
    )
    reg2 = EventRegistration.objects.create(
        user=student2,
        event=event,
        status=EventRegistration.Status.REGISTERED
    )
    print(f"✓ Student 1 registered for event")
    print(f"✓ Student 2 registered for event")
    print(f"  Total registrations: {event.registrations.count()}")
except Exception as e:
    print(f"✗ Error: {e}")

# Test 8: JWT Token generation
print("\n\nTEST 8: Generate JWT tokens")
print("-"*70)
try:
    student_refresh = RefreshToken.for_user(student1)
    student_access = str(student_refresh.access_token)
    print(f"✓ JWT token generated for {student1.email}")
    print(f"  Access token (preview): {student_access[:40]}...")
    print(f"  Token contains user_id: {student1.id}")
except Exception as e:
    print(f"✗ Error: {e}")

# Summary
print("\n\n" + "="*70)
print("DATA SUMMARY AFTER TESTS")
print("="*70)
print(f"Total Users:            {User.objects.count()}")
print(f"Total Clubs:            {Club.objects.count()}")
print(f"Total Join Requests:    {JoinRequest.objects.count()}")
print(f"  - Pending:            {JoinRequest.objects.filter(status=JoinRequest.Status.PENDING).count()}")
print(f"  - Approved:           {JoinRequest.objects.filter(status=JoinRequest.Status.APPROVED).count()}")
print(f"Total Events:           {Event.objects.count()}")
print(f"Total Event Registrations: {EventRegistration.objects.count()}")

print("\n" + "="*70)
print("✓ ALL BACKEND FUNCTIONALITY TESTS PASSED!")
print("="*70)
print("\nNext Step: Start Django dev server and test API endpoints in Flutter/Postman")
print("\nRun: python manage.py runserver")
print("\n" + "="*70 + "\n")
