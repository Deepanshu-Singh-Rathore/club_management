from django.urls import path
from .views import (
    ClubListCreateView,
    ClubDetailView,
    ClubJoinView,
    EventListCreateView,
    EventDetailView,
    ApplyEventView,
    PendingRegistrationsView,
    ApproveRegistrationView,
    RejectRegistrationView,
    NotificationListView,
    MarkNotificationReadView
)

urlpatterns = [
    # Clubs
    path('clubs/', ClubListCreateView.as_view(), name='club-list-create'),
    path('clubs/<uuid:pk>/', ClubDetailView.as_view(), name='club-detail'),
    path('clubs/<uuid:pk>/join/', ClubJoinView.as_view(), name='club-join'),

    # Events
    path('events/', EventListCreateView.as_view(), name='event-list-create'),
    path('events/<uuid:pk>/', EventDetailView.as_view(), name='event-detail'),
    path('events/<uuid:pk>/apply/', ApplyEventView.as_view()),
    path('events/<uuid:pk>/approve/', ApproveRegistrationView.as_view()),
    path('events/<uuid:pk>/pending/', PendingRegistrationsView.as_view()),
    path('events/<uuid:pk>/reject/', RejectRegistrationView.as_view()),
    path('notifications/', NotificationListView.as_view()),
    path('notifications/<int:pk>/read/', MarkNotificationReadView.as_view()),
]