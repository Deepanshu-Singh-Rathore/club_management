from django.urls import path
from .views import (
    ClubListCreateView,
    ClubDetailView,
    ClubJoinView,
    ClubMembersView,
    ClubChatView,
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
    path('', ClubListCreateView.as_view()),
    path('<uuid:pk>/', ClubDetailView.as_view()),
    path('<uuid:pk>/join/', ClubJoinView.as_view()),
    path('<uuid:pk>/members/', ClubMembersView.as_view()),
    path('<uuid:pk>/chat/', ClubChatView.as_view()),

    # Events
    path('events/', EventListCreateView.as_view()),
    path('events/my/', MyEventsView.as_view()),
    path('events/<uuid:pk>/', EventDetailView.as_view()),
    path('events/<uuid:pk>/apply/', ApplyEventView.as_view()),
    path('events/<uuid:pk>/approve/', ApproveRegistrationView.as_view()),
    path('events/<uuid:pk>/reject/', RejectRegistrationView.as_view()),
    path('events/<uuid:pk>/pending/', PendingRegistrationsView.as_view()),

    # Notifications ✅ FIXED
    path('notifications/', NotificationListView.as_view()),
    path('notifications/<uuid:pk>/read/', MarkNotificationReadView.as_view()),

    # Polls
    path('polls/', EventSuggestionPollView.as_view()),
    path('polls/<uuid:pk>/', EventSuggestionPollDetailView.as_view()),
    path('polls/<uuid:pk>/close/', EventSuggestionPollDetailView.as_view()),
    path('polls/<uuid:pk>/suggest/', EventSuggestionSubmitView.as_view()),
]