from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from accounts.models import User
from clubs.models import Club, Membership, Event, EventRegistration


class Command(BaseCommand):
    help = 'Populate database with sample clubs, events, and users'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting data population...'))

        # Create admin user
        admin_user, _ = User.objects.get_or_create(
            email='admin@clubsphere.com',
            defaults={
                'full_name': 'Admin User',
                'role': User.Role.ADMIN,
                'is_verified': True,
                'is_staff': True,
                'is_superuser': True,
            }
        )
        if _:
            admin_user.set_password('admin123')
            admin_user.save()
            self.stdout.write(self.style.SUCCESS(f'✓ Created admin: {admin_user.email}'))

        # Create club heads
        club_head_emails = [
            'ritik@clubsphere.com',
            'priya@clubsphere.com',
            'aditya@clubsphere.com',
            'anjali@clubsphere.com',
        ]

        club_heads = []
        for email in club_head_emails:
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'full_name': email.split('@')[0].title(),
                    'role': User.Role.CLUB_HEAD,
                    'is_verified': True,
                }
            )
            if created:
                user.set_password('password123')
                user.save()
                self.stdout.write(self.style.SUCCESS(f'✓ Created club head: {user.email}'))
            club_heads.append(user)

        # Create students
        student_data = [
            ('student1@clubsphere.com', 'Rohan Kumar', '2024001'),
            ('student2@clubsphere.com', 'Neha Singh', '2024002'),
            ('student3@clubsphere.com', 'Vikram Patel', '2024003'),
            ('student4@clubsphere.com', 'Sneha Gupta', '2024004'),
            ('student5@clubsphere.com', 'Arjun Sharma', '2024005'),
            ('student6@clubsphere.com', 'Pooja Verma', '2024006'),
            ('student7@clubsphere.com', 'Rahul Mishra', '2024007'),
            ('student8@clubsphere.com', 'Divya Nair', '2024008'),
        ]

        students = []
        for email, full_name, roll_number in student_data:
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'full_name': full_name,
                    'roll_number': roll_number,
                    'role': User.Role.STUDENT,
                    'is_verified': True,
                }
            )
            if created:
                user.set_password('password123')
                user.save()
                self.stdout.write(self.style.SUCCESS(f'✓ Created student: {user.email}'))
            students.append(user)

        # Create clubs
        club_data = [
            ('Coding Club', 'A club for programming enthusiasts', club_heads[0]),
            ('Debate Society', 'For public speaking and debate lovers', club_heads[1]),
            ('Photography Club', 'Capture moments through lens', club_heads[2]),
            ('Dance Club', 'Express yourself through dance', club_heads[3]),
        ]

        clubs = []
        for name, description, club_head in club_data:
            club, created = Club.objects.get_or_create(
                name=name,
                defaults={
                    'description': description,
                    'created_by': club_head,
                }
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'✓ Created club: {club.name}'))
            clubs.append(club)

        # Add memberships
        for i, club in enumerate(clubs):
            # Add club head as member
            Membership.objects.get_or_create(
                user=club.created_by,
                club=club,
            )
            # Add some students to each club
            for student in students[i * 2:(i + 1) * 2 + 1]:
                Membership.objects.get_or_create(
                    user=student,
                    club=club,
                )
            self.stdout.write(self.style.SUCCESS(f'✓ Added members to {club.name}'))

        # Create events
        event_data = [
            ('Coding Bootcamp', 'Learn advanced Python and DSA', clubs[0], 50, 3),
            ('Hackathon', 'Build amazing projects in 24 hours', clubs[0], 100, 7),
            ('Debate Championship', 'Inter-college debate competition', clubs[1], 80, 5),
            ('Fashion Show', 'Formal dress competition', clubs[1], 60, 10),
            ('Photography Walk', 'Street photography session', clubs[2], 30, 2),
            ('Photography Exhibition', 'Showcase your best shots', clubs[2], 100, 20),
            ('Dance Workshop', 'Learn contemporary dance', clubs[3], 40, 4),
            ('Dance Battle', 'Showcase your moves', clubs[3], 150, 15),
        ]

        events = []
        for i, (title, description, club, capacity, days_offset) in enumerate(event_data):
            event_date = timezone.now() + timedelta(days=days_offset)
            event, created = Event.objects.get_or_create(
                title=title,
                club=club,
                defaults={
                    'description': description,
                    'event_date': event_date,
                    'capacity': capacity,
                    'created_by': club.created_by,
                    'status': Event.Status.UPCOMING,
                }
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'✓ Created event: {event.title}'))
            events.append(event)

        # Create event registrations
        for event in events:
            # Register 3-5 students for each event
            import random
            num_registrations = random.randint(3, 5)
            selected_students = random.sample(students, num_registrations)
            
            for student in selected_students:
                registration, created = EventRegistration.objects.get_or_create(
                    user=student,
                    event=event,
                    defaults={
                        'status': random.choice([
                            EventRegistration.Status.PENDING,
                            EventRegistration.Status.APPROVED,
                        ]),
                    }
                )
                if created:
                    self.stdout.write(f'  ✓ Registered {student.full_name} for {event.title}')

        self.stdout.write(self.style.SUCCESS('\n✅ Data population completed successfully!'))
