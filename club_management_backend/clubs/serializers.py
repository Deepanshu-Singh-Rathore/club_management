from rest_framework import serializers
from django.utils import timezone
from .models import EventRegistration
from rest_framework.decorators import action
from accounts.serializers import UserSerializer
from .models import Club, Membership, Event, Notification


# ---------------------------------------------------------------------------
# Club Serializers
# ---------------------------------------------------------------------------

class ClubSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    member_count = serializers.SerializerMethodField()

    class Meta:
        model = Club
        fields = (
            'id',
            'name',
            'description',
            'created_by',
            'member_count',
            'created_at',
        )
        read_only_fields = ('id', 'created_by', 'created_at')

    def get_member_count(self, obj):
        return obj.memberships.count()


class ClubCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Club
        fields = ('name', 'description')


# ---------------------------------------------------------------------------
# Membership Serializer
# ---------------------------------------------------------------------------

class MembershipSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    club = ClubSerializer(read_only=True)

    class Meta:
        model = Membership
        fields = ('id', 'user', 'club', 'joined_at')
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Event Serializers
# ---------------------------------------------------------------------------

class EventSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    club_name = serializers.CharField(source='club.name', read_only=True)

    class Meta:
        model = Event
        fields = (
            'id',
            'title',
            'description',
            'event_date',
            'status',
            'capacity',
            'club',
            'club_name',
            'created_by',
            'created_at',
        )
        read_only_fields = (
            'id',
            'created_by',
            'created_at',
            'club_name',
        )


class EventCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ('title', 'description', 'event_date', 'club', 'capacity')

    def validate_event_date(self, value):
        """Prevent creating events in the past."""
        if value < timezone.now():
            raise serializers.ValidationError("Event date cannot be in the past.")
        return value

class EventRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EventRegistration
        fields = '__all__'
        read_only_fields = ('id', 'user', 'status', 'created_at')


@action(detail=True, methods=['get'])
def pending(self, request, pk=None):
    event = self.get_object()

    pending_users = EventRegistration.objects.filter(
        event=event,
        status='pending'
    )

    serializer = EventRegistrationSerializer(pending_users, many=True)
    return Response(serializer.data)

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'
        