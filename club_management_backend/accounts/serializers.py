from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    """Read-only serializer used in JWT responses and profile views."""

    class Meta:
        model = User
        fields = ('id', 'full_name', 'email', 'phone_number', 'role', 'is_verified', 'created_at')
        read_only_fields = fields


class UserUpdateSerializer(serializers.ModelSerializer):
    """Allow users to update their own profile (non-sensitive fields only)."""

    class Meta:
        model = User
        fields = ('full_name', 'phone_number')


class RequestOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()


class VerifyOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(min_length=6, max_length=6)




