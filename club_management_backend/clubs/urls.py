from django.urls import path
from .views import (
    ClubListCreateView,
    ClubDetailView,
    ClubJoinView,
    EventListCreateView,
    EventDetailView,
)

urlpatterns = [
    # Clubs
    path('clubs/', ClubListCreateView.as_view(), name='club-list-create'),
    path('clubs/<uuid:pk>/', ClubDetailView.as_view(), name='club-detail'),
    path('clubs/<uuid:pk>/join/', ClubJoinView.as_view(), name='club-join'),
    # Events
    path('events/', EventListCreateView.as_view(), name='event-list-create'),
    path('events/<uuid:pk>/', EventDetailView.as_view(), name='event-detail'),
]

