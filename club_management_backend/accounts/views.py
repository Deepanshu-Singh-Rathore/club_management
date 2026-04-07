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
)


def generate_otp(length=6):
    return ''.join(random.choices(string.digits, k=length))


def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


class RequestOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RequestOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']

        user, _ = User.objects.get_or_create(
            email=email,
            defaults={'full_name': ''}
        )

        OTPVerification.objects.filter(user=user, is_used=False).update(is_used=True)

        otp_code = generate_otp()
        expires_at = timezone.now() + timedelta(minutes=5)

        OTPVerification.objects.create(
            user=user,
            otp_code=otp_code,
            expires_at=expires_at
        )

        try:
            send_mail(
                subject='Your OTP',
                message=f'Your OTP is {otp_code}',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
            )
        except Exception:
            return Response({"error": "Failed to send OTP"}, status=500)

        return Response({
            "message": "OTP sent successfully",
            "otp": otp_code   # remove in production
        })


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data['email']
        otp_code = serializer.validated_data['otp']

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({"error": "User not found"}, status=400)

        otp_obj = OTPVerification.objects.filter(
            user=user,
            is_used=False
        ).order_by('-created_at').first()

        if not otp_obj:
            return Response({"error": "No OTP found"}, status=400)

        if not otp_obj.is_valid():
            return Response({"error": "OTP expired"}, status=400)

        if otp_obj.otp_code != otp_code:
            return Response({"error": "Invalid OTP"}, status=400)

        otp_obj.is_used = True
        otp_obj.save()

        user.is_verified = True
        user.save()

        tokens = get_tokens_for_user(user)

        return Response({
            "access": tokens["access"],
            "refresh": tokens["refresh"],
            "user": UserSerializer(user).data
        })


class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = UserUpdateSerializer(
            request.user,
            data=request.data,
            partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(UserSerializer(request.user).data)