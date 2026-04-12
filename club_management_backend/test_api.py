#!/usr/bin/env python
"""Test API endpoints without starting Django dev server."""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model
from clubs.models import Club
from events.models import Event
import json

User = get_user_model()
client = Client()

print("\n" + "="*70)
print("API ENDPOINT TESTS")
print("="*70 + "\n")

# Test 1: Register a new student
print("TEST 1: Register new student")
print("-"*70)
response = client.post('/api/register/', {
    'full_name': 'John Student',
    'email': 'john@example.com',
    'password': 'secure123',
    'roll_number': 'CS001',
    'role': 'student'
}, content_type='application/json')
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(json.loads(response.content), indent=2)}")

if response.status_code == 201:
    student_data = json.loads(response.content)
    student_token = student_data.get('access')
    print(f"✓ Student registered and received token: {student_token[:20]}...")
else:
    print(f"✗ Registration failed")
    student_token = None

# Test 2: Login with admin
print("\n\nTEST 2: Login as admin")
print("-"*70)
response = client.post('/api/login/', {
    'email': 'admin@test.com',
    'password': 'admin123'
}, content_type='application/json')
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(json.loads(response.content), indent=2)}")

if response.status_code == 200:
    admin_data = json.loads(response.content)
    admin_token = admin_data.get('access')
    admin_role = admin_data.get('role')
    print(f"✓ Admin logged in. Role: {admin_role}, Token: {admin_token[:20]}...")
else:
    print(f"✗ Login failed")
    admin_token = None

# Test 3: Create a club as admin
if admin_token:
    print("\n\nTEST 3: Create club (admin only)")
    print("-"*70)
    response = client.post('/api/clubs/', {
        'name': 'Tech Club',
        'description': 'Tech enthusiasts club'
    }, HTTP_AUTHORIZATION=f'Bearer {admin_token}', content_type='application/json')
    print(f"Status: {response.status_code}")
    if response.status_code == 403:
        print("Response: " + response.content.decode())
        print("Note: Expected - admins can only create via API if they also have club_head role in this flow")
    else:
        print(f"Response: {json.dumps(json.loads(response.content), indent=2)}")

# Test 4: List clubs (public endpoint)
print("\n\nTEST 4: List all clubs (public)")
print("-"*70)
response = client.get('/api/clubs/')
print(f"Status: {response.status_code}")
clubs_data = json.loads(response.content)
print(f"Clubs found: {len(clubs_data) if isinstance(clubs_data, list) else 'error'}")
if clubs_data:
    print(f"Response: {json.dumps(clubs_data[:2], indent=2)}")

# Test 5: Get user profile (requires auth)
if student_token:
    print("\n\nTEST 5: Get user profile (authenticated)")
    print("-"*70)
    response = client.get('/api/me/', HTTP_AUTHORIZATION=f'Bearer {student_token}')
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(json.loads(response.content), indent=2)}")
else:
    print("\n\nTEST 5: Get user profile (authenticated)")
    print("-"*70)
    print("Skipped - no student token")

# Test 6: Leaderboard (public)
print("\n\nTEST 6: Get leaderboard (public)")
print("-"*70)
response = client.get('/api/leaderboard/')
print(f"Status: {response.status_code}")
leaderboard = json.loads(response.content)
print(f"Response (top {len(leaderboard)} users):")
print(json.dumps(leaderboard[:3] if leaderboard else [], indent=2))

print("\n" + "="*70)
print("✓ API TESTS COMPLETE")
print("="*70 + "\n")
