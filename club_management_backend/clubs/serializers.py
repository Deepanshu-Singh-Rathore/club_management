from rest_framework import serializers
from django.utils import timezone
from accounts.serializers import UserSerializer
from .models import (
    Club,
    Membership,
    Event,
    EventRegistration,
    Notification,
    ClubMessage,
    ClubPost,
    ClubPostLike,
    ClubPostComment,
    UserAchievement,
)


# ---------------------------------------------------------------------------
# Club Serializers
# ---------------------------------------------------------------------------

class ClubSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    member_count = serializers.SerializerMethodField()
    events_count = serializers.SerializerMethodField()

    class Meta:
        model = Club
        fields = (
            'id',
            'name',
            'description',
            'category',
            'banner_url',
            'logo_url',
            'is_active',
            'created_by',
            'member_count',
            'events_count',
            'created_at',
        )
        read_only_fields = ('id', 'created_by', 'created_at', 'member_count', 'events_count')

    def get_member_count(self, obj):
        if hasattr(obj, 'member_count_annotated'):
            return obj.member_count_annotated
        if hasattr(obj, '_prefetched_objects_cache') and 'memberships' in obj._prefetched_objects_cache:
            return len(obj.memberships.all())
        return obj.memberships.count()

    def get_events_count(self, obj):
        if hasattr(obj, 'events_count_annotated'):
            return obj.events_count_annotated
        if hasattr(obj, '_prefetched_objects_cache') and 'events' in obj._prefetched_objects_cache:
            return len(obj.events.all())
        return obj.events.count()


class ClubCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Club
        fields = ('name', 'description', 'category', 'banner_url', 'logo_url')


# ---------------------------------------------------------------------------
# Membership Serializer
# ---------------------------------------------------------------------------

class MembershipSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    club = ClubSerializer(read_only=True)

    class Meta:
        model = Membership
        fields = ('id', 'user', 'club', 'role', 'joined_at')
        read_only_fields = ('id', 'user', 'club', 'joined_at')


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
            'venue', 'category', 'registration_deadline', 'schedule',
            'club', 'club_name', 'capacity', 'status',
            'registered_count', 'created_by', 'created_at',
        )
        read_only_fields = ('id', 'created_by', 'created_at', 'club_name', 'registered_count')

    def get_registered_count(self, obj):
        if hasattr(obj, 'approved_registrations_count'):
            return obj.approved_registrations_count
        if hasattr(obj, '_prefetched_objects_cache') and 'registrations' in obj._prefetched_objects_cache:
            return sum(1 for r in obj.registrations.all() if r.status == 'approved')
        return obj.registrations.filter(status='approved').count()


class EventCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = (
            'title', 'description', 'event_date', 'image_url',
            'venue', 'category', 'registration_deadline', 'schedule',
            'club', 'capacity', 'status',
        )


# ---------------------------------------------------------------------------
# Event Registration Serializer
# ---------------------------------------------------------------------------

class EventRegistrationSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    event = EventSerializer(read_only=True)

    class Meta:
        model = EventRegistration
        fields = (
            'id', 'user', 'event', 'status',
            'ticket_id', 'attendance_status', 'attended_at', 'created_at',
        )
        read_only_fields = ('id', 'ticket_id', 'created_at')


# ---------------------------------------------------------------------------
# Community Posts Serializers
# ---------------------------------------------------------------------------

class ClubPostCommentSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.full_name', read_only=True)
    author_email = serializers.CharField(source='author.email', read_only=True)

    class Meta:
        model = ClubPostComment
        fields = ('id', 'post', 'author', 'author_name', 'author_email', 'content', 'created_at')
        read_only_fields = ('id', 'author', 'created_at')


class ClubPostSerializer(serializers.ModelSerializer):
    club_name = serializers.CharField(source='club.name', read_only=True)
    author_name = serializers.CharField(source='author.full_name', read_only=True)
    author_role = serializers.CharField(source='author.role', read_only=True)
    likes_count = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    is_liked = serializers.SerializerMethodField()

    class Meta:
        model = ClubPost
        fields = (
            'id', 'club', 'club_name', 'author', 'author_name', 'author_role',
            'title', 'content', 'post_type', 'image_url',
            'likes_count', 'comments_count', 'is_liked',
            'created_at', 'updated_at',
        )
        read_only_fields = (
            'id', 'club_name', 'author', 'author_name', 'author_role',
            'likes_count', 'comments_count', 'is_liked', 'created_at', 'updated_at',
        )

    def get_likes_count(self, obj):
        if hasattr(obj, 'likes_count_annotated'):
            return obj.likes_count_annotated
        return obj.likes.count()

    def get_comments_count(self, obj):
        if hasattr(obj, 'comments_count_annotated'):
            return obj.comments_count_annotated
        return obj.comments.count()

    def get_is_liked(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        if hasattr(obj, '_prefetched_objects_cache') and 'likes' in obj._prefetched_objects_cache:
            return any(l.user_id == request.user.id for l in obj.likes.all())
        return obj.likes.filter(user=request.user).exists()


class ClubPostCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClubPost
        fields = ('title', 'content', 'post_type', 'image_url')


# ---------------------------------------------------------------------------
# Achievements Serializer
# ---------------------------------------------------------------------------

class UserAchievementSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserAchievement
        fields = ('id', 'badge_code', 'title', 'description', 'icon', 'unlocked_at')
        read_only_fields = fields


# ---------------------------------------------------------------------------
# Notification Serializer
# ---------------------------------------------------------------------------

class NotificationSerializer(serializers.ModelSerializer):
    event_id = serializers.CharField(source='event.id', read_only=True)
    club_id = serializers.CharField(source='club.id', read_only=True)
    post_id = serializers.CharField(source='post.id', read_only=True)
    registration_id = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = (
            'id',
            'message',
            'type',
            'is_read',
            'created_at',
            'event_id',
            'club_id',
            'post_id',
            'registration_id',
        )

    def get_registration_id(self, obj):
        if obj.type != 'apply' or obj.event is None:
            return None
        reg = EventRegistration.objects.filter(
            event=obj.event,
            status='pending'
        ).order_by('-created_at').first()
        return str(reg.id) if reg else None


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
