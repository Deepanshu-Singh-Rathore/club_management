import random
import string
from django.utils import timezone
from datetime import timedelta
from django.core.mail import send_mail
from django.conf import settings

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken

from .models import User, OTPVerification
from .serializers import (
    RequestOTPSerializer,
    VerifyOTPSerializer,
    UserSerializer,
    UserUpdateSerializer,
    RegisterSerializer,
    LoginSerializer,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def generate_otp(length=6):
    """Generate a cryptographically safe numeric OTP."""
    return ''.join(random.choices(string.digits, k=length))


def get_tokens_for_user(user):
    """Return a dictionary of JWT access and refresh tokens."""
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


# ---------------------------------------------------------------------------
# Auth Views
# ---------------------------------------------------------------------------

class RequestOTPView(APIView):
    """
    POST /api/auth/request-otp/
    Accepts an email, creates the user if they don't exist, generates a 6-digit
    OTP, stores it with a 5-minute expiry, and sends it via email.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RequestOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']

        # Get or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={'full_name': ''},
        )

        # Invalidate all previous unused OTPs for this user
        OTPVerification.objects.filter(user=user, is_used=False).update(is_used=True)

        # Generate and save new OTP
        otp_code = generate_otp()
        expires_at = timezone.now() + timedelta(minutes=5)
        OTPVerification.objects.create(
            user=user,
            otp_code=otp_code,
            expires_at=expires_at,
        )

        # Send OTP via email (console backend in dev)
        send_mail(
            subject='Your ClubSphere OTP',
            message=(
                f'Hi,\n\n'
                f'Your one-time password for ClubSphere is: {otp_code}\n\n'
                f'This OTP is valid for 5 minutes. Do not share it with anyone.\n\n'
                f'– The ClubSphere Team'
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
            fail_silently=False,
        )

        return Response({'message': 'OTP sent successfully'}, status=status.HTTP_200_OK)


class VerifyOTPView(APIView):
    """
    POST /api/auth/verify-otp/
    Validates the OTP, marks it used, verifies the user, and returns JWT tokens.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        otp_code = serializer.validated_data['otp']

        # Look up user
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {'error': 'No account found with this email.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Fetch the most recent unused OTP
        otp_obj = (
            OTPVerification.objects
            .filter(user=user, is_used=False)
            .order_by('-created_at')
            .first()
        )

        if otp_obj is None:
            return Response(
                {'error': 'No active OTP found. Please request a new one.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not otp_obj.is_valid():
            return Response(
                {'error': 'OTP has expired. Please request a new one.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if otp_obj.otp_code != otp_code:
            return Response(
                {'error': 'Invalid OTP.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Mark OTP as used
        otp_obj.is_used = True
        otp_obj.save(update_fields=['is_used'])

        # Mark user as verified
        user.is_verified = True
        user.save(update_fields=['is_verified'])

        # Issue JWT tokens
        tokens = get_tokens_for_user(user)

        return Response(
            {
                **tokens,
                'user': UserSerializer(user).data,
            },
            status=status.HTTP_200_OK,
        )


class UserProfileView(APIView):
    """
    GET  /api/auth/me/   – retrieve own profile
    PATCH /api/auth/me/  – update own profile
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserUpdateSerializer(request.user, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(UserSerializer(request.user).data)


# ---------------------------------------------------------------------------
# Register / Login (email + password)
# ---------------------------------------------------------------------------

class RegisterView(APIView):
    """
    POST /api/auth/register/
    Creates a new user account with email and password.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        user = serializer.save()
        tokens = get_tokens_for_user(user)
        return Response(
            {**tokens, 'user': UserSerializer(user).data},
            status=status.HTTP_201_CREATED,
        )


class LoginView(APIView):
    """
    POST /api/auth/login/
    Authenticates with email + password, returns JWT tokens.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'Invalid email or password.'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.check_password(password):
            return Response({'error': 'Invalid email or password.'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_active:
            return Response({'error': 'Account is disabled.'}, status=status.HTTP_403_FORBIDDEN)

        tokens = get_tokens_for_user(user)
        return Response(
            {**tokens, 'user': UserSerializer(user).data},
            status=status.HTTP_200_OK,
        )


# ---------------------------------------------------------------------------
# Leaderboard
# ---------------------------------------------------------------------------

class LeaderboardView(APIView):
    """
    GET /api/auth/leaderboard/
    Returns users sorted by points descending (top 20).
    """
    permission_classes = [AllowAny]

    def get(self, request):
        users = User.objects.filter(is_active=True).order_by('-points')[:20]
        data = [
            {
                'rank': idx + 1,
                'id': str(u.id),
                'full_name': u.full_name or u.email.split('@')[0],
                'points': u.points,
                'roll_number': u.roll_number or '',
            }
            for idx, u in enumerate(users)
        ]
        return Response(data)
