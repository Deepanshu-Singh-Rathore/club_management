"""
Management command to seed the database with realistic test data.
Usage: python manage.py seed_data
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
import random

from accounts.models import User
from clubs.models import Club, Membership, Event, EventRegistration, Notification


CLUBS = [
    {
        "name": "Coding Club",
        "description": "A community for students passionate about programming, competitive coding, and software development.",
    },
    {
        "name": "Robotics Club",
        "description": "Building and programming robots for competitions and exhibitions across the country.",
    },
    {
        "name": "Photography Club",
        "description": "Exploring the art of photography — from street photography to astrophotography.",
    },
    {
        "name": "Debate Society",
        "description": "Sharpening critical thinking and public speaking through structured debates and MUNs.",
    },
    {
        "name": "Music Club",
        "description": "A space for vocalists, instrumentalists, and music producers to collaborate and perform.",
    },
    {
        "name": "Entrepreneurship Cell",
        "description": "Fostering a startup culture by connecting student innovators with mentors and resources.",
    },
]

STUDENTS = [
    ("Aarav Sharma", "aarav.sharma@college.edu", "CS2021001"),
    ("Priya Patel", "priya.patel@college.edu", "CS2021002"),
    ("Rohan Mehta", "rohan.mehta@college.edu", "EC2021003"),
    ("Ananya Singh", "ananya.singh@college.edu", "ME2021004"),
    ("Karan Gupta", "karan.gupta@college.edu", "CS2022005"),
    ("Sneha Reddy", "sneha.reddy@college.edu", "IT2022006"),
    ("Arjun Nair", "arjun.nair@college.edu", "CS2022007"),
    ("Divya Iyer", "divya.iyer@college.edu", "EC2022008"),
    ("Yash Joshi", "yash.joshi@college.edu", "ME2023009"),
    ("Neha Verma", "neha.verma@college.edu", "CS2023010"),
    ("Siddharth Bose", "siddharth.bose@college.edu", "IT2023011"),
    ("Tanvi Kulkarni", "tanvi.kulkarni@college.edu", "CS2023012"),
]

CLUB_HEADS = [
    ("Rahul Kapoor", "rahul.kapoor@college.edu", "HEAD001"),
    ("Meera Nambiar", "meera.nambiar@college.edu", "HEAD002"),
    ("Dev Anand", "dev.anand@college.edu", "HEAD003"),
    ("Pooja Saxena", "pooja.saxena@college.edu", "HEAD004"),
    ("Vikram Tiwari", "vikram.tiwari@college.edu", "HEAD005"),
    ("Ishita Das", "ishita.das@college.edu", "HEAD006"),
]

EVENTS = [
    ("Hackathon 2025", "coding", 10, True),
    ("Python Bootcamp", "coding", 5, True),
    ("Bot War Championship", "robotics", 7, True),
    ("Portrait Photography Walk", "photography", 3, True),
    ("Inter-College Debate", "debate", 14, True),
    ("Acoustic Night", "music", 2, True),
    ("Startup Pitch Fest", "ecell", 21, True),
    ("DSA Masterclass", "coding", 1, True),

    ("Web Dev Workshop", "coding", -30, False),
    ("Line Follower Robot Contest", "robotics", -20, False),
    ("Monsoon Photo Exhibition", "photography", -15, False),
    ("Parliamentary Debate", "debate", -10, False),
    ("Band Auditions", "music", -45, False),
    ("Entrepreneurship Summit", "ecell", -60, False),
    ("Open Mic Night", "music", -5, False),
]


class Command(BaseCommand):
    help = "Seed the database with realistic test data"

    def handle(self, *args, **options):
        self.stdout.write("Seeding database...")

        # ---------------- DEFAULT ADMIN ----------------
        admin, _ = User.objects.get_or_create(
            email="admin@clubsphere.com",
            defaults={
                "full_name": "Super Admin",
                "role": User.Role.ADMIN,
                "is_staff": True,
                "is_superuser": True,
                "is_verified": True,
                "roll_number": "ADMIN001",
            },
        )
        admin.set_password("admin123")
        admin.save()

        # ---------------- YOUR ADMIN ----------------
        my_admin, _ = User.objects.get_or_create(
            email="vyasvineet7@gmail.com",
            defaults={
                "full_name": "Vineet",
                "role": User.Role.ADMIN,
                "is_staff": True,
                "is_superuser": True,
                "is_verified": True,
                "roll_number": "ADMIN002",
            },
        )
        my_admin.role = User.Role.ADMIN
        my_admin.is_staff = True
        my_admin.is_superuser = True
        my_admin.is_verified = True
        my_admin.set_password("vineet123")
        my_admin.save()

        # ---------------- FRIEND ADMIN 1 ----------------
        admin1, _ = User.objects.get_or_create(
            email="deepanshu052005@gmail.com",
            defaults={
                "full_name": "Deepanshu",
                "role": User.Role.ADMIN,
                "is_staff": True,
                "is_superuser": True,
                "is_verified": True,
                "roll_number": "ADMIN003",
            },
        )
        admin1.role = User.Role.ADMIN
        admin1.is_staff = True
        admin1.is_superuser = True
        admin1.is_verified = True
        admin1.set_password("deepanshu123")
        admin1.save()

        # ---------------- FRIEND ADMIN 2 ----------------
        admin2, _ = User.objects.get_or_create(
            email="joshitaniya093@gmail.com",
            defaults={
                "full_name": "Taniya",
                "role": User.Role.ADMIN,
                "is_staff": True,
                "is_superuser": True,
                "is_verified": True,
                "roll_number": "ADMIN004",
            },
        )
        admin2.role = User.Role.ADMIN
        admin2.is_staff = True
        admin2.is_superuser = True
        admin2.is_verified = True
        admin2.set_password("taniya123")
        admin2.save()

        # ---------------- FRIEND ADMIN 2 ----------------
        admin3, _ = User.objects.get_or_create(
            email="tamannaregar2@gmail.com",
            defaults={
                "full_name": "Tamanna",
                "role": User.Role.ADMIN,
                "is_staff": True,
                "is_superuser": True,
                "is_verified": True,
                "roll_number": "ADMIN005",
            },
        )
        admin3.role = User.Role.ADMIN
        admin3.is_staff = True
        admin3.is_superuser = True
        admin3.is_verified = True
        admin3.set_password("tamanna123")
        admin3.save()

        # ---------------- CLUB HEADS ----------------
        head_users = []
        for full_name, email, roll in CLUB_HEADS:
            u, _ = User.objects.get_or_create(
                email=email,
                defaults={
                    "full_name": full_name,
                    "role": User.Role.CLUB_HEAD,
                    "is_verified": True,
                    "roll_number": roll,
                },
            )
            u.set_password("head123")
            u.save()
            head_users.append(u)

        # ---------------- STUDENTS ----------------
        student_users = []
        for full_name, email, roll in STUDENTS:
            u, _ = User.objects.get_or_create(
                email=email,
                defaults={
                    "full_name": full_name,
                    "role": User.Role.STUDENT,
                    "is_verified": True,
                    "roll_number": roll,
                    "points": random.randint(0, 80),
                },
            )
            u.set_password("student123")
            u.save()
            student_users.append(u)

        # ---------------- CLUBS ----------------
        clubs = []
        for i, club_data in enumerate(CLUBS):
            head = head_users[i % len(head_users)]
            club, _ = Club.objects.get_or_create(
                name=club_data["name"],
                defaults={
                    "description": club_data["description"],
                    "created_by": head,
                },
            )
            clubs.append(club)
            Membership.objects.get_or_create(user=head, club=club)

        club_map = {
            "coding": clubs[0],
            "robotics": clubs[1],
            "photography": clubs[2],
            "debate": clubs[3],
            "music": clubs[4],
            "ecell": clubs[5],
        }

        # ---------------- MEMBERSHIPS ----------------
        for student in student_users:
            joined = random.sample(clubs, k=random.randint(2, 4))
            for club in joined:
                Membership.objects.get_or_create(user=student, club=club)

        # ---------------- EVENTS ----------------
        events = []
        now = timezone.now()

        for title, club_key, day_offset, is_upcoming in EVENTS:
            club = club_map[club_key]
            status = Event.Status.UPCOMING if is_upcoming else Event.Status.COMPLETED
            event_date = now + timedelta(days=day_offset)

            ev, _ = Event.objects.get_or_create(
                title=title,
                defaults={
                    "description": f"Join us for {title}",
                    "event_date": event_date,
                    "club": club,
                    "capacity": random.randint(30, 100),
                    "created_by": club.created_by,
                    "status": status,
                },
            )
            events.append(ev)

             # ---------------- UPCOMING EVENT NOTIFICATIONS ----------------
for event in events:
    if event.status == Event.Status.UPCOMING:
        for student in student_users:
            Notification.objects.get_or_create(
                user=student,
                message=f"New Event: {event.title} is coming soon!",
                type="event",
            )

        # ---------------- REGISTRATIONS + NOTIFICATIONS ----------------
        reg_count = 0

        for event in events:
            eligible = [
                s for s in student_users
                if Membership.objects.filter(user=s, club=event.club).exists()
            ]

            participants = random.sample(
                eligible,
                k=min(len(eligible), random.randint(3, 7))
            )

            for student in participants:
                if EventRegistration.objects.filter(user=student, event=event).exists():
                    continue

                if event.status == Event.Status.COMPLETED:
                    status = EventRegistration.Status.APPROVED
                    student.points += 10
                    student.save(update_fields=["points"])
                else:
                    status = random.choice([
                        EventRegistration.Status.PENDING,
                        EventRegistration.Status.APPROVED,
                        EventRegistration.Status.REJECTED,
                    ])

                EventRegistration.objects.create(
                    user=student,
                    event=event,
                    status=status
                )

                reg_count += 1

                # Notification
                Notification.objects.create(
                    user=student,
                    message=f"{event.title} → {status}",
                    type=status.lower(),
                )

        self.stdout.write(self.style.SUCCESS("\n DONE: Seed data loaded"))

       