from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly
from django.db import transaction
from accounts.models import User
from rest_framework import generics

from django.utils import timezone
from .models import Club, Membership, Event, EventRegistration, Notification, EventSuggestionPoll, EventSuggestion, ClubMessage
from .serializers import (
    ClubSerializer,
    ClubCreateSerializer,
    MembershipSerializer,
    EventSerializer,
    EventCreateSerializer,
    EventRegistrationSerializer,
    NotificationSerializer,
    ClubMessageSerializer,
)
from accounts.permissions import IsOwnerOrAdmin, IsClubHeadOrAdmin, IsStudent


# ---------------------------------------------------------------------------
# CLUB VIEWS
# ---------------------------------------------------------------------------

class ClubListCreateView(APIView):
    """
    GET  /api/clubs/   – list all clubs (public)
    POST /api/clubs/   – create a club (club_head or admin only)
    """
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        clubs = Club.objects.select_related('created_by').prefetch_related('memberships')
        return Response(ClubSerializer(clubs, many=True).data)

    def post(self, request):
        if request.user.role not in ('club_head', 'admin'):
            return Response({'error': 'Only club heads or admins can create clubs'}, status=403)

        serializer = ClubCreateSerializer(data=request.data)
        if serializer.is_valid():
            club = serializer.save(created_by=request.user)
            return Response(ClubSerializer(club).data, status=201)

        return Response(serializer.errors, status=400)


class ClubDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, pk):
        try:
            return Club.objects.get(pk=pk)
        except Club.DoesNotExist:
            return None

    def get(self, request, pk):
        club = self.get_object(pk)
        if not club:
            return Response({'error': 'Club not found'}, status=404)
        return Response(ClubSerializer(club).data)

    def put(self, request, pk):
        club = self.get_object(pk)
        if not club:
            return Response({'error': 'Club not found'}, status=404)

        if not IsOwnerOrAdmin().has_object_permission(request, self, club):
            return Response({'error': 'Permission denied'}, status=403)

        serializer = ClubCreateSerializer(club, data=request.data, partial=True)
        if serializer.is_valid():
            club = serializer.save()
            return Response(ClubSerializer(club).data)

        return Response(serializer.errors, status=400)

    def delete(self, request, pk):
        club = self.get_object(pk)
        if not club:
            return Response({'error': 'Club not found'}, status=404)

        if request.user.role != 'admin':
            return Response({'error': 'Only admin can delete clubs'}, status=403)

        club.delete()
        return Response(status=204)


class ClubJoinView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            club = Club.objects.get(pk=pk)
        except Club.DoesNotExist:
            return Response({'error': 'Club not found'}, status=404)

        membership, created = Membership.objects.get_or_create(user=request.user, club=club)

        if not created:
            return Response({'message': 'Already a member'}, status=200)

        return Response(MembershipSerializer(membership).data, status=201)


class ClubMembersView(APIView):
    """
    GET /api/clubs/<id>/members/  – list members for a specific club
    Access: admin or the club head who created the club
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            club = Club.objects.select_related('created_by').get(pk=pk)
        except Club.DoesNotExist:
            return Response({'error': 'Club not found'}, status=404)

        is_admin = request.user.role == 'admin'
        is_owner_head = request.user.role == 'club_head' and club.created_by == request.user
        if not (is_admin or is_owner_head):
            return Response({'error': 'Permission denied'}, status=403)

        memberships = Membership.objects.filter(club=club).select_related('user')
        members = [
            {
                'id': str(m.user.id),
                'full_name': m.user.full_name,
                'email': m.user.email,
                'phone_number': m.user.phone_number,
                'role': m.user.role,
            }
            for m in memberships
        ]

        return Response({
            'club_id': str(club.id),
            'club_name': club.name,
            'member_count': len(members),
            'members': members,
        })


# ---------------------------------------------------------------------------
# EVENT VIEWS
# ---------------------------------------------------------------------------

class EventListCreateView(generics.ListCreateAPIView):
    serializer_class = EventSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request, *args, **kwargs):
        events = Event.objects.select_related(
            'club', 'created_by'
        ).prefetch_related('registrations')

        club_id = request.query_params.get('club')
        if club_id:
            events = events.filter(club_id=club_id)

        return Response(EventSerializer(events, many=True).data)

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        with transaction.atomic():
            event = serializer.save()

            
            users = User.objects.filter(role__in=['student', 'club_head'])

            print("EVENT CREATED:", event.title)
            print("TOTAL USERS:", users.count())

            notifications = [
                Notification(
                    user=user,
                    message=f"New Event: {event.title}",
                    type="event",
                    event=event,
                    club=event.club,
                )
                for user in users
            ]

            Notification.objects.bulk_create(notifications)

        return Response(serializer.data, status=201)


class EventDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, pk):
        try:
            return Event.objects.select_related('club', 'created_by').get(pk=pk)
        except Event.DoesNotExist:
            return None

    def get(self, request, pk):
        event = self.get_object(pk)
        if not event:
            return Response({'error': 'Event not found'}, status=404)
        return Response(EventSerializer(event).data)

    def put(self, request, pk):
        event = self.get_object(pk)
        if not event:
            return Response({'error': 'Event not found'}, status=404)

        if request.user.role not in ('club_head', 'admin'):
            return Response({'error': 'Permission denied'}, status=403)

        serializer = EventCreateSerializer(event, data=request.data, partial=True)
        if serializer.is_valid():
            event = serializer.save()
            return Response(EventSerializer(event).data)
        return Response(serializer.errors, status=400)

    def delete(self, request, pk):
        event = self.get_object(pk)
        if not event:
            return Response({'error': 'Event not found'}, status=404)

        if request.user.role not in ('club_head', 'admin'):
            return Response({'error': 'Permission denied'}, status=403)

        event.delete()
        return Response(status=204)


# ---------------------------------------------------------------------------
# MY EVENTS – registrations for the authenticated user
# ---------------------------------------------------------------------------

class MyEventsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        regs = (
            EventRegistration.objects
            .filter(user=request.user)
            .select_related('event__club', 'event__created_by')
            .order_by('-created_at')
        )
        return Response(EventRegistrationSerializer(regs, many=True).data)


# ---------------------------------------------------------------------------
# APPLY FOR EVENT
# ---------------------------------------------------------------------------

class ApplyEventView(APIView):
    permission_classes = [IsAuthenticated, IsStudent]

    def post(self, request, pk):
        try:
            event = Event.objects.select_related('club').get(pk=pk)
        except Event.DoesNotExist:
            return Response({'error': 'Event not found'}, status=404)

        if EventRegistration.objects.filter(user=request.user, event=event).exists():
            return Response({'message': 'Already applied'}, status=400)

        approved_count = EventRegistration.objects.filter(
            event=event,
            status='approved'
        ).count()

        if event.capacity and approved_count >= event.capacity:
            return Response({'message': 'Event is at full capacity'}, status=400)

        EventRegistration.objects.create(
            user=request.user,
            event=event,
            status='pending'
        )

        admins = User.objects.filter(role='admin')

        for admin in admins:
            Notification.objects.create(
                user=admin,
                message=f'{request.user.full_name or request.user.email} applied for "{event.title}"',
                type='apply',
                event=event,
                club=event.club,
            )

        return Response({'message': 'Applied successfully'}, status=201)


# ---------------------------------------------------------------------------
# PENDING REGISTRATIONS  (club_head / admin)
# ---------------------------------------------------------------------------

class PendingRegistrationsView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def get(self, request, pk):
        regs = (
            EventRegistration.objects
            .filter(event_id=pk, status='pending')
            .select_related('user', 'event', 'event__club')
        )

        return Response(
            EventRegistrationSerializer(regs, many=True).data
        )


# ---------------------------------------------------------------------------
# APPROVE REGISTRATION  (awards points)
# ---------------------------------------------------------------------------

class ApproveRegistrationView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def post(self, request, pk):
        reg_id = request.data.get('registration_id')

        try:
            reg = EventRegistration.objects.select_related(
                'user', 'event', 'event__club'
            ).get(id=reg_id, event_id=pk)
        except EventRegistration.DoesNotExist:
            return Response({'error': 'Registration not found'}, status=404)

        approved = EventRegistration.objects.filter(
            event_id=pk,
            status='approved'
        ).count()

        if reg.event.capacity and approved >= reg.event.capacity:
            return Response({'error': 'Event is at full capacity'}, status=400)

        # ✅ Approve
        reg.status = 'approved'
        reg.save()

        # ✅ Points
        points = getattr(settings, 'EVENT_APPROVAL_POINTS', 10)
        reg.user.points += points
        reg.user.save(update_fields=['points'])

        # ✅ Notification (IMPORTANT FIX)
        Notification.objects.create(
            user=reg.user,
            message=f'You have been approved for "{reg.event.title}" (+{points} pts)',
            type='approved',
            event=reg.event,
            club=reg.event.club,
        )

        return Response({
            'message': 'Approved',
            'points_awarded': points
        })


# ---------------------------------------------------------------------------
# REJECT REGISTRATION
# ---------------------------------------------------------------------------

class RejectRegistrationView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def post(self, request, pk):
        reg_id = request.data.get('registration_id')

        try:
            reg = EventRegistration.objects.select_related(
                'user', 'event', 'event__club'
            ).get(id=reg_id, event_id=pk)
        except EventRegistration.DoesNotExist:
            return Response({'error': 'Registration not found'}, status=404)

        # ❌ Reject
        reg.status = 'rejected'
        reg.save()

        # ✅ Notification (IMPORTANT FIX)
        Notification.objects.create(
            user=reg.user,
            message=f'Your application for "{reg.event.title}" was rejected',
            type='rejected',
            event=reg.event,
            club=reg.event.club,
        )

        return Response({'message': 'Rejected'})


# ---------------------------------------------------------------------------
# NOTIFICATIONS
# ---------------------------------------------------------------------------

class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifs = Notification.objects.filter(user=request.user).order_by('-created_at')[:50]
        return Response(NotificationSerializer(notifs, many=True).data)


class MarkNotificationReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            notification = Notification.objects.get(
                pk=pk,
                user=request.user
            )
        except Notification.DoesNotExist:
            return Response({'error': 'Notification not found'}, status=404)

        notification.is_read = True
        notification.save(update_fields=['is_read'])

        return Response({'message': 'Marked as read'})


# ---------------------------------------------------------------------------
# EVENT SUGGESTION POLLS
# ---------------------------------------------------------------------------

class EventSuggestionPollView(APIView):
    """
    GET  /api/clubs/polls/        – list all polls (admin only)
    POST /api/clubs/polls/        – create a new poll (admin only)
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != 'admin':
            return Response({'error': 'Admin access required'}, status=403)
        polls = EventSuggestionPoll.objects.prefetch_related('suggestions').all()
        data = [
            {
                'id': str(p.id),
                'question': p.question,
                'is_active': p.is_active,
                'created_at': p.created_at,
                'closed_at': p.closed_at,
                'response_count': EventSuggestion.objects.filter(poll=p).count(),
                'suggestions': [
                    {'phone': s.submitter_phone, 'suggestion': s.suggestion, 'submitted_at': s.submitted_at}
                    for s in EventSuggestion.objects.filter(poll=p)
                ],
            }
            for p in polls
        ]
        return Response(data)

    def post(self, request):
        if request.user.role != 'admin':
            return Response({'error': 'Admin access required'}, status=403)
        question = request.data.get('question', '').strip()
        if not question:
            return Response({'error': 'question is required'}, status=400)
        # Close any previously active poll
        EventSuggestionPoll.objects.filter(is_active=True).update(
            is_active=False, closed_at=timezone.now()
        )
        poll = EventSuggestionPoll.objects.create(question=question, created_by=request.user)
        return Response({'id': str(poll.id), 'question': poll.question, 'is_active': poll.is_active}, status=201)


class EventSuggestionPollDetailView(APIView):
    """
    GET    /api/clubs/polls/<id>/       – get poll with suggestions (admin only)
    DELETE /api/clubs/polls/<id>/close/ – close the poll (admin only)
    """
    permission_classes = [IsAuthenticated]

    def _get_poll(self, pk):
        try:
            return EventSuggestionPoll.objects.get(pk=pk)
        except EventSuggestionPoll.DoesNotExist:
            return None

    def get(self, request, pk):
        if request.user.role != 'admin':
            return Response({'error': 'Admin access required'}, status=403)
        poll = self._get_poll(pk)
        if not poll:
            return Response({'error': 'Poll not found'}, status=404)
        data = {
            'id': str(poll.id),
            'question': poll.question,
            'is_active': poll.is_active,
            'created_at': poll.created_at,
            'closed_at': poll.closed_at,
            'suggestions': [
                {'phone': s.submitter_phone, 'suggestion': s.suggestion, 'submitted_at': s.submitted_at}
                for s in EventSuggestion.objects.filter(poll=poll)
            ],
        }
        return Response(data)

    def post(self, request, pk):
        """POST /api/clubs/polls/<id>/close/  – close the poll"""
        if request.user.role != 'admin':
            return Response({'error': 'Admin access required'}, status=403)
        poll = self._get_poll(pk)
        if not poll:
            return Response({'error': 'Poll not found'}, status=404)
        poll.is_active = False
        poll.closed_at = timezone.now()
        poll.save(update_fields=['is_active', 'closed_at'])
        return Response({'message': 'Poll closed', 'id': str(poll.id)})


# ---------------------------------------------------------------------------
# CLUB CHAT
# ---------------------------------------------------------------------------

class ClubChatView(APIView):
    """
    GET  /api/clubs/<id>/chat/  – fetch last 100 messages (members only)
    POST /api/clubs/<id>/chat/  – send a message (members only)
    """
    permission_classes = [IsAuthenticated]

    def _get_club(self, pk):
        try:
            return Club.objects.get(pk=pk)
        except Club.DoesNotExist:
            return None

    def _is_member(self, user, club):
        if user.role in ('club_head', 'admin'):
            return True
        return Membership.objects.filter(user=user, club=club).exists()

    def get(self, request, pk):
        club = self._get_club(pk)
        if not club:
            return Response({'error': 'Club not found'}, status=404)
        if not self._is_member(request.user, club):
            return Response({'error': 'Members only'}, status=403)
        messages = (
            ClubMessage.objects
            .filter(club=club)
            .select_related('sender')
            .order_by('created_at')[:100]
        )
        return Response(ClubMessageSerializer(messages, many=True).data)

    def post(self, request, pk):
        club = self._get_club(pk)
        if not club:
            return Response({'error': 'Club not found'}, status=404)
        if not self._is_member(request.user, club):
            return Response({'error': 'Members only'}, status=403)
        content = request.data.get('content', '').strip()
        if not content:
            return Response({'error': 'content is required'}, status=400)
        msg = ClubMessage.objects.create(club=club, sender=request.user, content=content)
        return Response(ClubMessageSerializer(msg).data, status=201)


class EventSuggestionSubmitView(APIView):
    """
    POST /api/clubs/polls/<id>/suggest/  – submit a suggestion (bot service account uses this)
    Body: { phone: str, suggestion: str }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            poll = EventSuggestionPoll.objects.get(pk=pk, is_active=True)
        except EventSuggestionPoll.DoesNotExist:
            return Response({'error': 'Active poll not found'}, status=404)

        phone = request.data.get('phone', '').strip()
        suggestion = request.data.get('suggestion', '').strip()
        if not suggestion:
            return Response({'error': 'suggestion is required'}, status=400)

        EventSuggestion.objects.create(poll=poll, submitter_phone=phone, suggestion=suggestion)
        return Response({'message': 'Suggestion recorded'}, status=201)
