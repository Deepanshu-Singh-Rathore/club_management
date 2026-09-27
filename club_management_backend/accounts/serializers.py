from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    """Read-only serializer used in JWT responses and profile views."""

    class Meta:
        model = User
        fields = ('id', 'full_name', 'email', 'phone_number', 'roll_number', 'role', 'points', 'is_verified', 'created_at')
        read_only_fields = fields


class UserUpdateSerializer(serializers.ModelSerializer):
    """Allow users to update their own profile (non-sensitive fields only)."""

    class Meta:
        model = User
        fields = ('full_name', 'phone_number')


class RegisterSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=255)
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6, write_only=True)
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    roll_number = serializers.CharField(max_length=30, required=False, allow_blank=True)
    role = serializers.ChoiceField(choices=['student', 'admin', 'club_head'], default='student')

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('A user with this email already exists.')
        return value

    def validate_roll_number(self, value):
        if value and User.objects.filter(roll_number=value).exists():
            raise serializers.ValidationError('A user with this roll number already exists.')
        return value

    def create(self, validated_data):
        roll_number = validated_data.pop('roll_number', None) or None
        phone_number = validated_data.pop('phone_number', None) or None
        return User.objects.create_user(
            email=validated_data['email'],
            full_name=validated_data['full_name'],
            password=validated_data['password'],
            roll_number=roll_number,
            phone_number=phone_number,
            role=validated_data.get('role', 'student'),
            is_verified=True,
        )


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class RequestOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()


class VerifyOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField(min_length=6, max_length=6)




