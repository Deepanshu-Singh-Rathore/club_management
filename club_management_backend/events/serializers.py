from rest_framework import serializers

from accounts.serializers import UserSerializer
from clubs.models import Club

from .models import Event, EventRegistration


class EventSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    club_name = serializers.CharField(source='club.name', read_only=True)
    participant_count = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = (
            'id',
            'title',
            'description',
            'event_date',
            'club',
            'club_name',
            'created_by',
            'participant_count',
            'created_at',
        )
        read_only_fields = ('id', 'created_by', 'club_name', 'participant_count', 'created_at')

    def get_participant_count(self, obj):
        return obj.registrations.count()


class EventCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = ('title', 'description', 'event_date', 'club')

    def validate_club(self, value: Club):
        request = self.context.get('request')
        if request is None:
            return value
        user = request.user
        if user.role == 'club_head' and value.created_by != user:
            raise serializers.ValidationError('Club heads can create events only for their own clubs.')
        return value


class EventRegistrationSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    event = EventSerializer(read_only=True)

    class Meta:
        model = EventRegistration
        fields = ('id', 'user', 'event', 'status', 'created_at')
        read_only_fields = ('id', 'user', 'event', 'created_at')
