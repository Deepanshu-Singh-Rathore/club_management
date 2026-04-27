from rest_framework import serializers
from django.utils import timezone
from accounts.serializers import UserSerializer
from .models import Club, Membership, Event, EventRegistration, Notification, ClubMessage


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
    registered_count = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = (
            'id', 'title', 'description', 'event_date', 'image_url',
            'club', 'club_name', 'capacity', 'status',
            'registered_count', 'created_by', 'created_at',
        )
        read_only_fields = ('id', 'created_by', 'created_at', 'club_name', 'registered_count')

    def get_registered_count(self, obj):
        return obj.registrations.filter(status='approved').count()


class EventCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ('title', 'description', 'event_date', 'image_url', 'club', 'capacity')


# ---------------------------------------------------------------------------
# Event Registration Serializer
# ---------------------------------------------------------------------------

class EventRegistrationSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    event = EventSerializer(read_only=True)

    class Meta:
        model = EventRegistration
        fields = ('id', 'user', 'event', 'status', 'created_at')
        read_only_fields = ('id', 'created_at')


# ---------------------------------------------------------------------------
# Notification Serializer
# ---------------------------------------------------------------------------

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ('id', 'message', 'type', 'is_read', 'created_at')
        read_only_fields = ('id', 'created_at')


# ---------------------------------------------------------------------------
# Club Chat Serializer
# ---------------------------------------------------------------------------

class ClubMessageSerializer(serializers.ModelSerializer):
    sender_id = serializers.CharField(source='sender.id', read_only=True)
    sender_name = serializers.CharField(source='sender.full_name', read_only=True)

    class Meta:
        model = ClubMessage
        fields = ('id', 'sender_id', 'sender_name', 'content', 'created_at')
        read_only_fields = ('id', 'sender_id', 'sender_name', 'created_at')
