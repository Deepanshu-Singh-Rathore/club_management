import uuid
from django.db import models
from django.conf import settings

User = settings.AUTH_USER_MODEL


# ---------------------------------------------------------------------------
# CLUB
# ---------------------------------------------------------------------------

class Club(models.Model):
    CATEGORY_CHOICES = (
        ('Technology', 'Technology'),
        ('Cultural', 'Cultural'),
        ('Sports', 'Sports'),
        ('Photography', 'Photography'),
        ('Music', 'Music'),
        ('Literature', 'Literature'),
        ('Entrepreneurship', 'Entrepreneurship'),
        ('Social', 'Social'),
        ('Academic', 'Academic'),
        ('Other', 'Other'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200, unique=True, db_index=True)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='Technology', db_index=True)
    banner_url = models.URLField(blank=True, null=True)
    logo_url = models.URLField(blank=True, null=True)
    is_active = models.BooleanField(default=True, db_index=True)

    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='clubs_created',
        limit_choices_to={'role__in': ['club_head', 'admin']},
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'clubs'
        ordering = ['name']

    def __str__(self):
        return self.name


# ---------------------------------------------------------------------------
# MEMBERSHIP
# ---------------------------------------------------------------------------

class Membership(models.Model):
    ROLE_CHOICES = (
        ('member', 'Member'),
        ('coordinator', 'Coordinator'),
        ('lead', 'Lead'),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='memberships')
    club = models.ForeignKey(Club, on_delete=models.CASCADE, related_name='memberships')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='member')
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'memberships'
        unique_together = ('user', 'club')

    def __str__(self):
        return f"{self.user} - {self.club.name}"


# ---------------------------------------------------------------------------
# EVENT
# ---------------------------------------------------------------------------

class Event(models.Model):
    class Status(models.TextChoices):
        UPCOMING = 'upcoming', 'Upcoming'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    title = models.CharField(max_length=300)
    description = models.TextField(blank=True)

    event_date = models.DateTimeField(db_index=True)
    image_url = models.URLField(blank=True, null=True)
    venue = models.CharField(max_length=200, default='Campus Auditorium')
    category = models.CharField(max_length=50, default='General', db_index=True)
    registration_deadline = models.DateTimeField(null=True, blank=True)
    schedule = models.TextField(blank=True, default='')

    club = models.ForeignKey(
        Club,
        on_delete=models.CASCADE,
        related_name='events',
    )

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.UPCOMING,
        db_index=True,
    )

    capacity = models.IntegerField(default=0)

    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'events'
        ordering = ['-event_date']

    def __str__(self):
        return self.title


# ---------------------------------------------------------------------------
# EVENT REGISTRATION
# ---------------------------------------------------------------------------

class EventRegistration(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        APPROVED = 'approved', 'Approved'
        REJECTED = 'rejected', 'Rejected'

    class AttendanceStatus(models.TextChoices):
        REGISTERED = 'registered', 'Registered'
        CHECKED_IN = 'checked_in', 'Checked In'
        CANCELLED = 'cancelled', 'Cancelled'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='event_registrations')
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='registrations')

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True,
    )

    ticket_id = models.CharField(max_length=32, unique=True, null=True, blank=True, db_index=True)
    attendance_status = models.CharField(
        max_length=20,
        choices=AttendanceStatus.choices,
        default=AttendanceStatus.REGISTERED,
        db_index=True,
    )
    attended_at = models.DateTimeField(null=True, blank=True)
    checked_in_by = models.ForeignKey(
        User,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='checked_in_registrations'
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'event_registrations'
        unique_together = ('user', 'event')

    def save(self, *args, **kwargs):
        if not self.ticket_id:
            self.ticket_id = f"CS-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user} - {self.event.title} ({self.status})"


# ---------------------------------------------------------------------------
# EVENT SUGGESTION POLL
# ---------------------------------------------------------------------------

class EventSuggestionPoll(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    question = models.TextField()
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='polls_created')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    closed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'event_suggestion_polls'
        ordering = ['-created_at']

    def __str__(self):
        return f"Poll: {self.question[:60]}"


class EventSuggestion(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    poll = models.ForeignKey(EventSuggestionPoll, on_delete=models.CASCADE, related_name='suggestions')
    submitter_phone = models.CharField(max_length=30)
    suggestion = models.TextField()
    submitted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'event_suggestions'
        ordering = ['submitted_at']

    def __str__(self):
        return f"{self.submitter_phone}: {self.suggestion[:60]}"


# ---------------------------------------------------------------------------
# CLUB CHAT
# ---------------------------------------------------------------------------

class ClubMessage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    club = models.ForeignKey(Club, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='club_messages')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'club_messages'
        ordering = ['created_at']

    def __str__(self):
        return f"{self.sender}: {self.content[:30]}"


# ---------------------------------------------------------------------------
# COMMUNITY FEED & POSTS
# ---------------------------------------------------------------------------

class ClubPost(models.Model):
    POST_TYPES = (
        ('announcement', 'Announcement'),
        ('general', 'General'),
        ('event', 'Event'),
    )

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    club = models.ForeignKey(Club, on_delete=models.CASCADE, related_name='posts')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='club_posts')
    title = models.CharField(max_length=300)
    content = models.TextField()
    post_type = models.CharField(max_length=30, choices=POST_TYPES, default='general', db_index=True)
    image_url = models.URLField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'club_posts'
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.club.name}] {self.title}"


class ClubPostLike(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    post = models.ForeignKey(ClubPost, on_delete=models.CASCADE, related_name='likes')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='post_likes')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'club_post_likes'
        unique_together = ('post', 'user')


class ClubPostComment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    post = models.ForeignKey(ClubPost, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='post_comments')
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'club_post_comments'
        ordering = ['created_at']


# ---------------------------------------------------------------------------
# ACHIEVEMENTS
# ---------------------------------------------------------------------------

class UserAchievement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='achievements')
    badge_code = models.CharField(max_length=50, db_index=True)
    title = models.CharField(max_length=100)
    description = models.CharField(max_length=255)
    icon = models.CharField(max_length=50, default='trophy')
    unlocked_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'user_achievements'
        unique_together = ('user', 'badge_code')
        ordering = ['-unlocked_at']

    def __str__(self):
        return f"{self.user.email} - {self.title}"


# ---------------------------------------------------------------------------
# NOTIFICATION
# ---------------------------------------------------------------------------

class Notification(models.Model):
    TYPE_CHOICES = (
        ('apply', 'Apply'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('event', 'Event'),
        ('announcement', 'Announcement'),
        ('achievement', 'Achievement'),
        ('checkin', 'Check-in'),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    message = models.TextField()
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    is_read = models.BooleanField(default=False, db_index=True)

    event = models.ForeignKey(Event, null=True, blank=True, on_delete=models.CASCADE)
    club = models.ForeignKey(Club, null=True, blank=True, on_delete=models.CASCADE)
    post = models.ForeignKey(ClubPost, null=True, blank=True, on_delete=models.CASCADE)

    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        db_table = 'notifications'
        ordering = ['-created_at']