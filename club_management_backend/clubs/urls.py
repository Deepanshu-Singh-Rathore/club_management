from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import ClubViewSet, JoinRequestViewSet

router = DefaultRouter()
router.register(r'clubs', ClubViewSet, basename='club')
router.register(r'join-requests', JoinRequestViewSet, basename='join-request')

urlpatterns = [
    path('', include(router.urls)),
]

