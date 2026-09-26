import random
import string
from typing import cast
from django.utils import timezone
from datetime import timedelta
from django.core.mail import send_mail
from django.conf import settings

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.cache import cache

from .models import User, OTPVerification
from .serializers import (
    RequestOTPSerializer,
    VerifyOTPSerializer,
    UserSerializer,
    UserUpdateSerializer,
    RegisterSerializer,
    LoginSerializer,
)
from .permissions import IsAdmin


def generate_otp(length: int = 6) -> str:
    return ''.join(random.choices(string.digits, k=length))


def get_tokens_for_user(user: User) -> dict:
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


# ---------------------------------------------------------------------------
# OTP flow
# ---------------------------------------------------------------------------

class RequestOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RequestOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        validated_data = cast(dict[str, str], serializer.validated_data)
        email = validated_data['email']
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'No account found with this email'}, status=400)

        OTPVerification.objects.filter(user=user, is_used=False).update(is_used=True)

        otp_code = generate_otp()
        expires_at = timezone.now() + timedelta(minutes=5)
        OTPVerification.objects.create(user=user, otp_code=otp_code, expires_at=expires_at)

        try:
            send_mail(
                subject='Your ClubSphere OTP',
                message=f'Your one-time password is: {otp_code}\nIt expires in 5 minutes.',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
            )
        except Exception:
            return Response({'error': 'Failed to send OTP email'}, status=500)

        return Response({'message': 'OTP sent successfully'})


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        validated_data = cast(dict[str, str], serializer.validated_data)
        email = validated_data['email']
        otp_code = validated_data['otp']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=400)

        otp_obj = (
            OTPVerification.objects
            .filter(user=user, is_used=False)
            .order_by('-created_at')
            .first()
        )

        if not otp_obj:
            return Response({'error': 'No active OTP found'}, status=400)
        if not otp_obj.is_valid():
            return Response({'error': 'OTP has expired'}, status=400)
        if otp_obj.otp_code != otp_code:
            return Response({'error': 'Invalid OTP'}, status=400)

        otp_obj.is_used = True
        otp_obj.save(update_fields=['is_used'])

        user.is_verified = True
        user.save(update_fields=['is_verified'])

        tokens = get_tokens_for_user(user)
        return Response({**tokens, 'user': UserSerializer(user).data})


# ---------------------------------------------------------------------------
# Register / Login
# ---------------------------------------------------------------------------

class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        user = cast(User, serializer.save())
        cache.delete('admin_users_list')
        cache.delete('admin_dashboard_stats')
        tokens = get_tokens_for_user(user)
        return Response(
            {**tokens, 'user': UserSerializer(user).data},
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data = cast(dict[str, str], serializer.validated_data)
        email = validated_data['email']
        password = validated_data['password']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'Invalid email or password'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.check_password(password):
            return Response({'error': 'Invalid email or password'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_active:
            return Response({'error': 'Account is disabled'}, status=status.HTTP_403_FORBIDDEN)

        tokens = get_tokens_for_user(user)
        return Response({**tokens, 'user': UserSerializer(user).data})


# ---------------------------------------------------------------------------
# Profile
# ---------------------------------------------------------------------------

class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserUpdateSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        cache.delete(f"jwt_user_{user.id}")
        cache.delete('admin_users_list')
        return Response(UserSerializer(request.user).data)


# ---------------------------------------------------------------------------
# Admin – User Management
# ---------------------------------------------------------------------------

class AdminUserListView(APIView):
    """GET /api/auth/admin/users/ – list all users (admin only)."""
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):
        cached = cache.get('admin_users_list')
        if cached is not None:
            return Response(cached)
        users = User.objects.all().order_by('-created_at')
        data = UserSerializer(users, many=True).data
        cache.set('admin_users_list', data, timeout=30)
        return Response(data)


class AdminUserDetailView(APIView):
    """
    GET   /api/auth/admin/users/<id>/  – get user
    PATCH /api/auth/admin/users/<id>/  – update role / active status
    DELETE /api/auth/admin/users/<id>/ – deactivate user
    """
    permission_classes = [IsAuthenticated, IsAdmin]

    def get_object(self, pk):
        try:
            return User.objects.get(pk=pk)
        except User.DoesNotExist:
            return None

    def get(self, request, pk):
        user = self.get_object(pk)
        if not user:
            return Response({'error': 'User not found'}, status=404)
        return Response(UserSerializer(user).data)

    def patch(self, request, pk):
        user = self.get_object(pk)
        if not user:
            return Response({'error': 'User not found'}, status=404)

        allowed_fields = {'role', 'is_active', 'full_name', 'points'}
        data = {k: v for k, v in request.data.items() if k in allowed_fields}

        if 'role' in data and data['role'] not in ('student', 'club_head', 'admin'):
            return Response({'error': 'Invalid role'}, status=400)

        for field, value in data.items():
            setattr(user, field, value)
        user.save(update_fields=list(data.keys()))
        cache.delete(f"jwt_user_{user.id}")
        cache.delete('admin_users_list')
        cache.delete('admin_dashboard_stats')

        return Response(UserSerializer(user).data)

    def delete(self, request, pk):
        user = self.get_object(pk)
        if not user:
            return Response({'error': 'User not found'}, status=404)
        if user == request.user:
            return Response({'error': 'Cannot deactivate your own account'}, status=400)
        user.is_active = False
        user.save(update_fields=['is_active'])
        cache.delete(f"jwt_user_{user.id}")
        cache.delete('admin_users_list')
        cache.delete('admin_dashboard_stats')
        return Response({'message': 'User deactivated'})


# ---------------------------------------------------------------------------
# Admin – Dashboard Stats
# ---------------------------------------------------------------------------

class AdminStatsView(APIView):
    """GET /api/auth/admin/stats/ – aggregate counts for the admin dashboard."""
    permission_classes = [IsAuthenticated, IsAdmin]

    def get(self, request):
        cached = cache.get('admin_dashboard_stats')
        if cached is not None:
            return Response(cached)

        from clubs.models import Club, Event, EventRegistration
        from django.db.models import Count, Q

        user_counts = User.objects.filter(is_active=True).aggregate(
            total_users=Count('id'),
            total_students=Count('id', filter=Q(role='student')),
            total_club_heads=Count('id', filter=Q(role='club_head')),
        )

        data = {
            'total_users': user_counts['total_users'] or 0,
            'total_students': user_counts['total_students'] or 0,
            'total_club_heads': user_counts['total_club_heads'] or 0,
            'total_clubs': Club.objects.count(),
            'total_events': Event.objects.count(),
            'pending_registrations': EventRegistration.objects.filter(status='pending').count(),
        }
        cache.set('admin_dashboard_stats', data, timeout=30)
        return Response(data)
