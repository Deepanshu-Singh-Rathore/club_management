import uuid
from django.db import models
from django.conf import settings

User = settings.AUTH_USER_MODEL


# ---------------------------------------------------------------------------
# CLUB
# ---------------------------------------------------------------------------

class Club(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200, unique=True)
    description = models.TextField(blank=True)

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


# ---------------------------------------------------------------------------
# MEMBERSHIP
# ---------------------------------------------------------------------------

class Membership(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='memberships')
    club = models.ForeignKey(Club, on_delete=models.CASCADE, related_name='memberships')
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'memberships'
        unique_together = ('user', 'club')


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

    event_date = models.DateTimeField()
    image_url = models.URLField(blank=True, null=True)
    club = models.ForeignKey(
        Club,
        on_delete=models.CASCADE,
        related_name='events',
    )

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.UPCOMING,
    )
    capacity = models.IntegerField(default=0)

    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)

    created_at = models.DateTimeField(auto_now_add=True)


# ---------------------------------------------------------------------------
# EVENT REGISTRATION
# ---------------------------------------------------------------------------

class EventRegistration(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        APPROVED = 'approved', 'Approved'
        REJECTED = 'rejected', 'Rejected'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='event_registrations')
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='registrations')

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING   # ✅ FIX HERE
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'event')

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


class Notification(models.Model):
    TYPE_CHOICES = (
        ("apply", "Apply"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="notifications")
    message = models.TextField()
    type = models.CharField(max_length=20, choices=TYPE_CHOICES)
    is_read = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user} - {self.type}"