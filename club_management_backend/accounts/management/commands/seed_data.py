"""
Management command to seed the database with realistic test data.
Usage: python manage.py seed_data
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
import random

from accounts.models import User
from clubs.models import Club, ClubMessage, Membership, Event, EventRegistration, Notification


# CLUBS = [
#     {
#         "name": "Coding Club",
#         "description": "A community for students passionate about programming, competitive coding, and software development.",
#     },
#     {
#         "name": "Robotics Club",
#         "description": "Building and programming robots for competitions and exhibitions across the country.",
#     },
#     {
#         "name": "Photography Club",
#         "description": "Exploring the art of photography — from street photography to astrophotography.",
#     },
#     {
#         "name": "Debate Society",
#         "description": "Sharpening critical thinking and public speaking through structured debates and MUNs.",
#     },
#     {
#         "name": "Music Club",
#         "description": "A space for vocalists, instrumentalists, and music producers to collaborate and perform.",
#     },
#     {
#         "name": "Entrepreneurship Cell",
#         "description": "Fostering a startup culture by connecting student innovators with mentors and resources.",
#     },
# ]

# STUDENTS = [
#     ("Aarav Sharma", "aarav.sharma@college.edu", "CS2021001"),
#     ("Priya Patel", "priya.patel@college.edu", "CS2021002"),
#     ("Rohan Mehta", "rohan.mehta@college.edu", "EC2021003"),
#     ("Ananya Singh", "ananya.singh@college.edu", "ME2021004"),
#     ("Karan Gupta", "karan.gupta@college.edu", "CS2022005"),
#     ("Sneha Reddy", "sneha.reddy@college.edu", "IT2022006"),
#     ("Arjun Nair", "arjun.nair@college.edu", "CS2022007"),
#     ("Divya Iyer", "divya.iyer@college.edu", "EC2022008"),
#     ("Yash Joshi", "yash.joshi@college.edu", "ME2023009"),
#     ("Neha Verma", "neha.verma@college.edu", "CS2023010"),
#     ("Siddharth Bose", "siddharth.bose@college.edu", "IT2023011"),
#     ("Tanvi Kulkarni", "tanvi.kulkarni@college.edu", "CS2023012"),
# ]

CLUB_HEADS = [
    ("Rahul Kapoor", "rahul.kapoor@college.edu", "HEAD001"),
    ("Meera Nambiar", "meera.nambiar@college.edu", "HEAD002"),
    ("Dev Anand", "dev.anand@college.edu", "HEAD003"),
    ("Pooja Saxena", "pooja.saxena@college.edu", "HEAD004"),
    ("Vikram Tiwari", "vikram.tiwari@college.edu", "HEAD005"),
    ("Ishita Das", "ishita.das@college.edu", "HEAD006"),
]

# EVENTS = [
#     # Upcoming
#     ("Hackathon 2025", "coding", 10, True),
#     ("Python Bootcamp", "coding", 5, True),
#     ("Bot War Championship", "robotics", 7, True),
#     ("Portrait Photography Walk", "photography", 3, True),
#     ("Inter-College Debate", "debate", 14, True),
#     ("Acoustic Night", "music", 2, True),
#     ("Startup Pitch Fest", "ecell", 21, True),
#     ("DSA Masterclass", "coding", 1, True),
#     # Completed
#     ("Web Dev Workshop", "coding", -30, False),
#     ("Line Follower Robot Contest", "robotics", -20, False),
#     ("Monsoon Photo Exhibition", "photography", -15, False),
#     ("Parliamentary Debate", "debate", -10, False),
#     ("Band Auditions", "music", -45, False),
#     ("Entrepreneurship Summit", "ecell", -60, False),
#     ("Open Mic Night", "music", -5, False),
# ]
CHAT_MESSAGES = {
    "coding": [
        "Hey everyone! Who's joining the hackathon this weekend?",
        "I'm in! Already have a team of 3, need one more backend dev.",
        "I can join — I'm decent with Django and FastAPI.",
        "Great, let's connect after the DSA masterclass tomorrow.",
        "Has anyone solved the last LeetCode weekly contest? Problem 3 was brutal.",
        "Yeah I got stuck on problem 3 too. Dynamic programming with bitmask 😅",
        "The Python bootcamp slides are up on the drive, check the announcements.",
        "Thanks! Also, are we doing mock interviews this semester?",
        "Yes! Starting next month. Sign-up sheet will be shared soon.",
        "Can't wait. Also reminder that the club room is booked every Tuesday 5pm.",
    ],
    "robotics": [
        "Bot War championship registrations are open! Get your bots ready.",
        "Our line follower finally completed the track in under 10 seconds 🎉",
        "That's insane! What sensor configuration are you using?",
        "IR array with 8 sensors and PID tuning. Happy to share the code.",
        "Please do! Our bot keeps overshooting the turns.",
        "Meeting this Friday to test the arm actuator. Lab 204, 4pm.",
        "Should we order more servo motors? We're running low.",
        "I'll raise a requisition — need at least 6 MG996R servos.",
        "Also the Arduino Mega we borrowed from ECE needs to go back by Monday.",
        "Noted. I'll return it after Friday's session.",
    ],
    "photography": [
        "The monsoon exhibition photos are up on the notice board — go check them out!",
        "Absolutely loved Priya's shot of the rain on the library steps.",
        "Thank you 😊 I used a 1/1000 shutter speed to freeze the drops.",
        "Portrait walk is this Sunday 7am. Bring a prime lens if you have one.",
        "What location are we meeting at?",
        "Main gate. We'll walk towards the old campus — great textures there.",
        "Can beginners join with just a phone camera?",
        "Absolutely! Composition matters more than gear.",
        "Quick tip: golden hour is 6:20–6:50am this week. Perfect for portraits.",
        "Also we need volunteers to help curate the semester-end exhibition.",
    ],
    "debate": [
        "Motion for Friday's practice: 'This house believes AI will do more harm than good.'",
        "Interesting motion. I'll take the opposition side.",
        "Same, I want to argue opposition. Anyone taking proposition?",
        "I'll go proposition — already have some strong points on economic productivity.",
        "Don't forget the MUN applications close this Sunday.",
        "What committee should I apply for as a first-timer?",
        "UNHRC or UNEP are usually more beginner-friendly.",
        "The parliamentary debate prep sessions start Wednesday. Attendance is mandatory.",
        "Can someone share the speaking time format for the inter-college event?",
        "6 minutes constructive, 3 minutes rebuttal, 2 minutes summary.",
    ],
    "music": [
        "Acoustic Night rehearsal is tonight at 7pm in the auditorium green room.",
        "I'll be 10 mins late — coming from a lab. Please start without me.",
        "No worries, we'll warm up first. Don't forget your capo.",
        "Has the setlist been finalised?",
        "Yes! Pinned in the group — 8 songs, mix of Hindi and English.",
        "Can we add one more original? Taniya finished the bridge for her composition.",
        "Let's hear it tonight and decide.",
        "Band auditions results are out — welcome to our two new guitarists!",
        "So excited to have them 🎸 Big talent this year.",
        "Next session we'll start working on the annual fest performance. Big one!",
    ],
    "ecell": [
        "Startup Pitch Fest registrations crossed 40 teams already!",
        "Amazing turnout. Do we have enough judges confirmed?",
        "5 confirmed so far — need at least 3 more. Reaching out to alumni network.",
        "I connected with a VC from Bangalore who might join as a judge.",
        "That would be incredible. Please share their contact with Deepanshu.",
        "Workshop on 'Building an MVP in 30 days' is this Thursday, Room 301.",
        "Is it open for non-members too?",
        "Yes, open to all. Just register on the portal so we can arrange seating.",
        "Reminder: business plan submissions for the internal round close tomorrow 11:59pm.",
        "Good luck everyone — let's make this the best pitch fest yet! 🚀",
    ],
}

EVENTS = [
    # Upcoming
    ("Hackathon 2025", "coding", 10, True),
    ("Python Bootcamp", "coding", 5, True),
    ("Bot War Championship", "robotics", 7, True),
    ("Portrait Photography Walk", "photography", 3, True),
    ("Inter-College Debate", "debate", 14, True),
    ("Acoustic Night", "music", 2, True),
    ("Startup Pitch Fest", "ecell", 21, True),
    ("DSA Masterclass", "coding", 1, True),
    # Completed
    ("Web Dev Workshop", "coding", -30, False),
    ("Line Follower Robot Contest", "robotics", -20, False),
    ("Monsoon Photo Exhibition", "photography", -15, False),
    ("Parliamentary Debate", "debate", -10, False),
    ("Band Auditions", "music", -45, False),
    ("Entrepreneurship Summit", "ecell", -60, False),
    ("Open Mic Night", "music", -5, False),
]


# class Command(BaseCommand):
#     help = "Seed the database with realistic test data"

#     def handle(self, *args, **options):
#         self.stdout.write("Seeding database...")

        # --- Admin ---
      
        # # --- Club Heads ---
        # head_users = []
        # for full_name, email, roll in CLUB_HEADS:
        #     u, _ = User.objects.get_or_create(
        #         email=email,
        #         defaults={
        #             "full_name": full_name,
        #             "role": User.Role.CLUB_HEAD,
        #             "is_verified": True,
        #             "roll_number": roll,
        #         },
        #     )
        #     u.set_password("head123")
        #     u.save()
        #     head_users.append(u)
        # self.stdout.write(f"  {len(head_users)} club heads created (password: head123)")

        # # --- Students ---
        # student_users = []
        # for full_name, email, roll in STUDENTS:
        #     u, _ = User.objects.get_or_create(
        #         email=email,
        #         defaults={
        #             "full_name": full_name,
        #             "role": User.Role.STUDENT,
        #             "is_verified": True,
        #             "roll_number": roll,
        #             "points": random.randint(0, 80),
        #         },
        #     )
        #     u.set_password("student123")
        #     u.save()
        #     student_users.append(u)
        # self.stdout.write(f"  {len(student_users)} students created (password: student123)")

        # # --- Clubs ---
        # clubs = []
        # for i, club_data in enumerate(CLUBS):
        #     head = head_users[i % len(head_users)]
        #     club, _ = Club.objects.get_or_create(
        #         name=club_data["name"],
        #         defaults={"description": club_data["description"], "created_by": head},
        #     )
        #     clubs.append(club)
        #     # Club head is also a member
        #     Membership.objects.get_or_create(user=head, club=club)

        # self.stdout.write(f"  {len(clubs)} clubs created")

        # # Map shorthand to club index
        # club_map = {
        #     "coding": clubs[0],
        #     "robotics": clubs[1],
        #     "photography": clubs[2],
        #     "debate": clubs[3],
        #     "music": clubs[4],
        #     "ecell": clubs[5],
        # }

        # # --- Memberships: each student joins 2–4 clubs ---
        # for student in student_users:
        #     joined = random.sample(clubs, k=random.randint(2, 4))
        #     for club in joined:
        #         Membership.objects.get_or_create(user=student, club=club)
        # self.stdout.write("  Memberships assigned")

        # # --- Events ---
        # events = []
        # now = timezone.now()
        # for title, club_key, day_offset, is_upcoming in EVENTS:
        #     club = club_map[club_key]
        #     status = Event.Status.UPCOMING if is_upcoming else Event.Status.COMPLETED
        #     event_date = now + timedelta(days=day_offset)
        #     ev, _ = Event.objects.get_or_create(
        #         title=title,
        #         defaults={
        #             "description": f"Join us for {title}. An exciting opportunity for all club members.",
        #             "event_date": event_date,
        #             "club": club,
        #             "capacity": random.randint(30, 100),
        #             "created_by": club.created_by,
        #             "status": status,
        #         },
        #     )
        #     events.append(ev)
        # self.stdout.write(f"  {len(events)} events created")

        # # --- Event Registrations ---
        # reg_count = 0
        # for event in events:
        #     eligible = [s for s in student_users if Membership.objects.filter(user=s, club=event.club).exists()]
        #     participants = random.sample(eligible, k=min(len(eligible), random.randint(3, 7)))
        #     for student in participants:
        #         if EventRegistration.objects.filter(user=student, event=event).exists():
        #             continue
        #         if event.status == Event.Status.COMPLETED:
        #             status = EventRegistration.Status.APPROVED
        #             student.points += 10
        #             student.save(update_fields=["points"])
        #         else:
        #             status = random.choice([
        #                 EventRegistration.Status.PENDING,
        #                 EventRegistration.Status.APPROVED,
        #                 EventRegistration.Status.REJECTED,
        #             ])
        #         reg = EventRegistration.objects.create(user=student, event=event, status=status)
        #         reg_count += 1

        #         # Notification
        #         if status == EventRegistration.Status.APPROVED:
        #             Notification.objects.create(
        #                 user=student,
        #                 message=f"Your registration for '{event.title}' has been approved!",
        #                 type="approved",
        #             )
        #         elif status == EventRegistration.Status.REJECTED:
        #             Notification.objects.create(
        #                 user=student,
        #                 message=f"Your registration for '{event.title}' was not accepted this time.",
        #                 type="rejected",
        #             )
        #         else:
        #             Notification.objects.create(
        #                 user=student,
        #                 message=f"You have applied for '{event.title}'. Awaiting approval.",
        #                 type="apply",
        #             )

       