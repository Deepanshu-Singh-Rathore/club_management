import uuid
from django.db import models
from django.conf import settings


class Club(models.Model):
    """A college club that can be created by a club_head or admin."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200, unique=True)
    description = models.TextField(blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
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


class Membership(models.Model):
    """Many-to-many relationship between users and clubs."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='memberships',
    )
    club = models.ForeignKey(
        Club,
        on_delete=models.CASCADE,
        related_name='memberships',
    )
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'memberships'
        unique_together = ('user', 'club')
        ordering = ['-joined_at']

    def __str__(self):
        return f'{self.user.email} → {self.club.name}'


class Event(models.Model):
    """An event organised by a club."""

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
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='events_created',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'events'
        ordering = ['event_date']

    def __str__(self):
        return f'{self.title} ({self.club.name})'
