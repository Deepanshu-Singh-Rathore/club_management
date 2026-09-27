from django.urls import path
from .views import (
    ClubListCreateView,
    ClubDetailView,
    ClubJoinView,
    ClubMembersView,
    ClubChatView,
    UserClubsView,
    EventListCreateView,
    EventDetailView,
    ApplyEventView,
    PendingRegistrationsView,
    ApproveRegistrationView,
    RejectRegistrationView,
    NotificationListView,
    MarkNotificationReadView,
    MarkAllNotificationsReadView,
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
    path('<uuid:pk>/members/', ClubMembersView.as_view(), name='club-members'),
    path('<uuid:pk>/chat/', ClubChatView.as_view(), name='club-chat'),
    path('user/my/', UserClubsView.as_view(), name='user-clubs'),

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
    path('notifications/read-all/', MarkAllNotificationsReadView.as_view()),
    path('notifications/<str:pk>/read/', MarkNotificationReadView.as_view()),

    # Polls
    path('polls/', EventSuggestionPollView.as_view()),
    path('polls/<uuid:pk>/', EventSuggestionPollDetailView.as_view()),
    path('polls/<uuid:pk>/close/', EventSuggestionPollDetailView.as_view()),
    path('polls/<uuid:pk>/suggest/', EventSuggestionSubmitView.as_view()),
]