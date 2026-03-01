from rest_framework import serializers
from accounts.serializers import UserSerializer
from .models import Club, Membership, Event


class ClubSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    member_count = serializers.SerializerMethodField()

    class Meta:
        model = Club
        fields = ('id', 'name', 'description', 'created_by', 'member_count', 'created_at')
        read_only_fields = ('id', 'created_by', 'created_at')

    def get_member_count(self, obj):
        return obj.memberships.count()


class ClubCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Club
        fields = ('name', 'description')


class MembershipSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    club = ClubSerializer(read_only=True)

    class Meta:
        model = Membership
        fields = ('id', 'user', 'club', 'joined_at')
        read_only_fields = fields


class EventSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    club_name = serializers.CharField(source='club.name', read_only=True)

    class Meta:
        model = Event
        fields = ('id', 'title', 'description', 'event_date', 'club', 'club_name', 'created_by', 'created_at')
        read_only_fields = ('id', 'created_by', 'created_at', 'club_name')


class EventCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ('title', 'description', 'event_date', 'club')
