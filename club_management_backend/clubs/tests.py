from django.urls import reverse
from django.utils import timezone
from datetime import timedelta
from rest_framework.test import APITestCase
from rest_framework import status

from accounts.models import User
from clubs.models import Club, Event, EventRegistration, Membership, ClubPost, UserAchievement


class ClubSphereApiTests(APITestCase):
    def setUp(self):
        # Create users
        self.student = User.objects.create_user(
            email='teststudent@college.edu',
            full_name='Test Student',
            password='Password123!',
            role='student',
            is_verified=True,
        )
        self.club_head = User.objects.create_user(
            email='testhead@college.edu',
            full_name='Test Club Head',
            password='Password123!',
            role='club_head',
            is_verified=True,
        )
        self.admin = User.objects.create_superuser(
            email='testadmin@college.edu',
            full_name='Test Admin',
            password='Password123!',
        )

        # Create a club
        self.club = Club.objects.create(
            name='Robotics Society',
            description='Innovate and build robots.',
            category='Technology',
            created_by=self.club_head,
        )
        Membership.objects.create(user=self.club_head, club=self.club, role='lead')

        # Create an event
        self.event = Event.objects.create(
            title='Annual Bot Championship',
            description='Robotics competition.',
            event_date=timezone.now() + timedelta(days=7),
            venue='Tech Arena',
            category='Technology',
            club=self.club,
            capacity=50,
            created_by=self.club_head,
        )

    def test_club_list_and_filter(self):
        res = self.client.get('/api/clubs/?category=Technology')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(len(res.data) >= 1)
        self.assertEqual(res.data[0]['name'], 'Robotics Society')

    def test_club_join_and_leave(self):
        self.client.force_authenticate(user=self.student)
        # Join
        res_join = self.client.post(f'/api/clubs/{self.club.id}/join/')
        self.assertEqual(res_join.status_code, status.HTTP_201_CREATED)
        self.assertTrue(Membership.objects.filter(user=self.student, club=self.club).exists())

        # Leave
        res_leave = self.client.post(f'/api/clubs/{self.club.id}/leave/')
        self.assertEqual(res_leave.status_code, status.HTTP_200_OK)
        self.assertFalse(Membership.objects.filter(user=self.student, club=self.club).exists())

    def test_event_registration_and_ticket(self):
        self.client.force_authenticate(user=self.student)
        res = self.client.post(f'/api/clubs/events/{self.event.id}/apply/')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertIn('ticket_id', res.data)
        ticket_id = res.data['ticket_id']
        self.assertTrue(ticket_id.startswith('CS-'))

        # Duplicate registration prevented
        res_dup = self.client.post(f'/api/clubs/events/{self.event.id}/apply/')
        self.assertEqual(res_dup.status_code, status.HTTP_400_BAD_REQUEST)

    def test_qr_checkin(self):
        self.client.force_authenticate(user=self.student)
        res_reg = self.client.post(f'/api/clubs/events/{self.event.id}/apply/')
        ticket_id = res_reg.data['ticket_id']

        # Club head checks in student
        self.client.force_authenticate(user=self.club_head)
        res_checkin = self.client.post(
            f'/api/clubs/events/{self.event.id}/check-in/',
            {'ticket_id': ticket_id},
        )
        self.assertEqual(res_checkin.status_code, status.HTTP_200_OK)
        self.assertIn('Check-in successful', res_checkin.data['message'])

        # Prevent duplicate check-in
        res_checkin2 = self.client.post(
            f'/api/clubs/events/{self.event.id}/check-in/',
            {'ticket_id': ticket_id},
        )
        self.assertEqual(res_checkin2.status_code, status.HTTP_200_OK)
        self.assertTrue(res_checkin2.data.get('already_checked_in'))

    def test_community_post_and_comments(self):
        # Club head creates announcement post
        self.client.force_authenticate(user=self.club_head)
        post_res = self.client.post(f'/api/clubs/{self.club.id}/posts/', {
            'title': 'Welcome New Members!',
            'content': 'We meet this Friday at 5 PM in Room 204.',
            'post_type': 'announcement',
        })
        self.assertEqual(post_res.status_code, status.HTTP_201_CREATED)
        post_id = post_res.data['id']

        # Student likes and comments
        self.client.force_authenticate(user=self.student)
        like_res = self.client.post(f'/api/clubs/posts/{post_id}/like/')
        self.assertEqual(like_res.status_code, status.HTTP_200_OK)
        self.assertTrue(like_res.data['is_liked'])

        comment_res = self.client.post(f'/api/clubs/posts/{post_id}/comments/', {
            'content': 'Looking forward to it!',
        })
        self.assertEqual(comment_res.status_code, status.HTTP_201_CREATED)

    def test_global_search_and_recommendations(self):
        # Global search
        res = self.client.get('/api/clubs/search/?q=Robotics')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertTrue(len(res.data['clubs']) >= 1)

        # Recommendations
        self.client.force_authenticate(user=self.student)
        rec_res = self.client.get('/api/clubs/recommendations/')
        self.assertEqual(rec_res.status_code, status.HTTP_200_OK)
        self.assertIn('recommended_clubs', rec_res.data)
        self.assertIn('trending_events', rec_res.data)
