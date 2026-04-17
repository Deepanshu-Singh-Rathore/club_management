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
    MarkNotificationReadView,
    MyEventsView,
    EventSuggestionPollView,
    EventSuggestionPollDetailView,
    EventSuggestionSubmitView,
)

urlpatterns = [
    # Clubs
    path('', ClubListCreateView.as_view(), name='club-list-create'),
    path('<uuid:pk>/', ClubDetailView.as_view(), name='club-detail'),
    path('<uuid:pk>/join/', ClubJoinView.as_view(), name='club-join'),

    # Events
    path('events/', EventListCreateView.as_view(), name='event-list-create'),
    path('events/my/', MyEventsView.as_view(), name='my-events'),
    path('events/<uuid:pk>/', EventDetailView.as_view(), name='event-detail'),
    path('events/<uuid:pk>/apply/', ApplyEventView.as_view(), name='event-apply'),
    path('events/<uuid:pk>/approve/', ApproveRegistrationView.as_view(), name='event-approve'),
    path('events/<uuid:pk>/reject/', RejectRegistrationView.as_view(), name='event-reject'),
    path('events/<uuid:pk>/pending/', PendingRegistrationsView.as_view(), name='event-pending'),

    # Notifications
    path('notifications/', NotificationListView.as_view(), name='notification-list'),
    path('notifications/<int:pk>/read/', MarkNotificationReadView.as_view(), name='notification-read'),

    # Event Suggestion Polls
    path('polls/', EventSuggestionPollView.as_view(), name='poll-list-create'),
    path('polls/<uuid:pk>/', EventSuggestionPollDetailView.as_view(), name='poll-detail'),
    path('polls/<uuid:pk>/close/', EventSuggestionPollDetailView.as_view(), name='poll-close'),
    path('polls/<uuid:pk>/suggest/', EventSuggestionSubmitView.as_view(), name='poll-suggest'),
]
