from rest_framework import serializers
from accounts.models import User
from accounts.serializers import UserSerializer
from .models import Club, JoinRequest


class ClubSerializer(serializers.ModelSerializer):
    created_by = UserSerializer(read_only=True)
    pending_requests = serializers.SerializerMethodField()

    class Meta:
        model = Club
        fields = ('id', 'name', 'description', 'created_by', 'pending_requests', 'created_at')
        read_only_fields = ('id', 'created_by', 'created_at')

    def get_pending_requests(self, obj):
        return obj.join_requests.filter(status=JoinRequest.Status.PENDING).count()


class ClubCreateSerializer(serializers.ModelSerializer):
    created_by_id = serializers.UUIDField(write_only=True, required=False)

    class Meta:
        model = Club
        fields = ('name', 'description', 'created_by_id')

    def validate_created_by_id(self, value):
        try:
            user = User.objects.get(id=value)
        except User.DoesNotExist:
            raise serializers.ValidationError('Selected club head does not exist.')

        if user.role != User.Role.CLUB_HEAD:
            raise serializers.ValidationError('created_by_id must be a user with club_head role.')
        return value


class JoinRequestSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    club = ClubSerializer(read_only=True)
    club_id = serializers.UUIDField(write_only=True, required=True)

    class Meta:
        model = JoinRequest
        fields = ('id', 'user', 'club', 'club_id', 'status', 'created_at')
        read_only_fields = ('id', 'user', 'club', 'status', 'created_at')

    def validate_club_id(self, value):
        if not Club.objects.filter(id=value).exists():
            raise serializers.ValidationError('Club does not exist.')
        return value

    def create(self, validated_data):
        club_id = validated_data.pop('club_id')
        club = Club.objects.get(id=club_id)
        return JoinRequest.objects.create(
            user=self.context['request'].user,
            club=club,
        )
