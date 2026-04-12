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


class JoinRequest(models.Model):
    """Request from a student to join a club."""

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        APPROVED = 'approved', 'Approved'
        REJECTED = 'rejected', 'Rejected'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='join_requests',
    )
    club = models.ForeignKey(
        Club,
        on_delete=models.CASCADE,
        related_name='join_requests',
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'join_requests'
        ordering = ['-created_at']
        unique_together = ('user', 'club')

    def __str__(self):
        return f'{self.user.email} -> {self.club.name} ({self.status})'
