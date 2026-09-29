from django.urls import path
from .views import (
    ClubListCreateView,
    ClubDetailView,
    ClubJoinView,
    ClubLeaveView,
    ClubMembersView,
    ClubAnalyticsView,
    ClubPostsView,
    ClubFeedView,
    ClubPostLikeView,
    ClubPostCommentsView,
    ClubChatView,
    UserClubsView,
    EventListCreateView,
    EventDetailView,
    ApplyEventView,
    CancelRegistrationView,
    CheckInAttendanceView,
    EventRegistrationsListView,
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
    AnnouncementsListView,
    GlobalSearchView,
    RecommendationsView,
    AchievementsListView,
)

urlpatterns = [
    # Global & Discovery
    path('search/', GlobalSearchView.as_view(), name='global-search'),
    path('recommendations/', RecommendationsView.as_view(), name='recommendations'),
    path('achievements/', AchievementsListView.as_view(), name='achievements'),
    path('announcements/', AnnouncementsListView.as_view(), name='announcements'),
    path('feed/', ClubFeedView.as_view(), name='club-feed'),

    # Clubs
    path('', ClubListCreateView.as_view(), name='club-list-create'),
    path('user/my/', UserClubsView.as_view(), name='user-clubs'),
    path('<uuid:pk>/', ClubDetailView.as_view(), name='club-detail'),
    path('<uuid:pk>/join/', ClubJoinView.as_view(), name='club-join'),
    path('<uuid:pk>/leave/', ClubLeaveView.as_view(), name='club-leave'),
    path('<uuid:pk>/members/', ClubMembersView.as_view(), name='club-members'),
    path('<uuid:pk>/analytics/', ClubAnalyticsView.as_view(), name='club-analytics'),
    path('<uuid:pk>/posts/', ClubPostsView.as_view(), name='club-posts'),
    path('<uuid:pk>/chat/', ClubChatView.as_view(), name='club-chat'),

    # Community Posts & Interactions
    path('posts/<uuid:pk>/like/', ClubPostLikeView.as_view(), name='post-like'),
    path('posts/<uuid:pk>/comments/', ClubPostCommentsView.as_view(), name='post-comments'),

    # Events
    path('events/', EventListCreateView.as_view(), name='event-list-create'),
    path('events/my/', MyEventsView.as_view(), name='event-my'),
    path('events/<uuid:pk>/', EventDetailView.as_view(), name='event-detail'),
    path('events/<uuid:pk>/apply/', ApplyEventView.as_view(), name='event-apply'),
    path('events/<uuid:pk>/cancel/', CancelRegistrationView.as_view(), name='event-cancel'),
    path('events/<uuid:pk>/check-in/', CheckInAttendanceView.as_view(), name='event-check-in'),
    path('events/<uuid:pk>/registrations/', EventRegistrationsListView.as_view(), name='event-registrations'),
    path('events/<uuid:pk>/approve/', ApproveRegistrationView.as_view(), name='event-approve'),
    path('events/<uuid:pk>/reject/', RejectRegistrationView.as_view(), name='event-reject'),
    path('events/<uuid:pk>/pending/', PendingRegistrationsView.as_view(), name='event-pending'),

    # Notifications
    path('notifications/', NotificationListView.as_view(), name='notifications'),
    path('notifications/read-all/', MarkAllNotificationsReadView.as_view(), name='notifications-read-all'),
    path('notifications/<str:pk>/read/', MarkNotificationReadView.as_view(), name='notification-read'),

    # Polls (Legacy & WhatsApp Bot)
    path('polls/', EventSuggestionPollView.as_view(), name='polls'),
    path('polls/<uuid:pk>/', EventSuggestionPollDetailView.as_view(), name='poll-detail'),
    path('polls/<uuid:pk>/close/', EventSuggestionPollDetailView.as_view(), name='poll-close'),
    path('polls/<uuid:pk>/suggest/', EventSuggestionSubmitView.as_view(), name='poll-suggest'),
]