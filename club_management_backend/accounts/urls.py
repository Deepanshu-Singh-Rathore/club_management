from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RequestOTPView,
    VerifyOTPView,
    UserProfileView,
    RegisterView,
    LoginView,
    LeaderboardView,
    AdminUserListView,
    AdminUserDetailView,
    AdminStatsView,
)

urlpatterns = [
    # Auth
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('refresh/', TokenRefreshView.as_view(), name='token-refresh'),

    # OTP flow
    path('request-otp/', RequestOTPView.as_view(), name='request-otp'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),

    # Profile
    path('me/', UserProfileView.as_view(), name='user-profile'),

    # Leaderboard
    path('leaderboard/', LeaderboardView.as_view(), name='leaderboard'),

    # Admin
    path('admin/stats/', AdminStatsView.as_view(), name='admin-stats'),
    path('admin/users/', AdminUserListView.as_view(), name='admin-user-list'),
    path('admin/users/<uuid:pk>/', AdminUserDetailView.as_view(), name='admin-user-detail'),
]
