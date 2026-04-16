from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly

from .models import Club, Membership, Event, EventRegistration, Notification
from .serializers import (
    ClubSerializer,
    ClubCreateSerializer,
    MembershipSerializer,
    EventSerializer,
    EventCreateSerializer,
    EventRegistrationSerializer,
    NotificationSerializer,
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


# ---------------------------------------------------------------------------
# EVENT VIEWS
# ---------------------------------------------------------------------------

class EventListCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        events = Event.objects.select_related('club', 'created_by').prefetch_related('registrations')
        club_id = request.query_params.get('club')
        if club_id:
            events = events.filter(club_id=club_id)
        return Response(EventSerializer(events, many=True).data)

    def post(self, request):
        if request.user.role not in ('club_head', 'admin'):
            return Response({'error': 'Only club_head or admin can create events'}, status=403)

        serializer = EventCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)

        event = serializer.save(created_by=request.user)
        return Response(EventSerializer(event).data, status=201)


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
            event = Event.objects.get(pk=pk)
        except Event.DoesNotExist:
            return Response({'error': 'Event not found'}, status=404)

        if EventRegistration.objects.filter(user=request.user, event=event).exists():
            return Response({'message': 'Already applied'}, status=400)

        approved_count = EventRegistration.objects.filter(event=event, status='approved').count()
        if event.capacity and approved_count >= event.capacity:
            return Response({'message': 'Event is at full capacity'}, status=400)

        EventRegistration.objects.create(user=request.user, event=event, status='pending')

        if event.created_by:
            Notification.objects.create(
                user=event.created_by,
                message=f'{request.user.full_name or request.user.email} applied for "{event.title}"',
                type='apply',
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
            .select_related('user', 'event')
        )
        return Response(EventRegistrationSerializer(regs, many=True).data)


# ---------------------------------------------------------------------------
# APPROVE REGISTRATION  (awards points)
# ---------------------------------------------------------------------------

class ApproveRegistrationView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def post(self, request, pk):
        reg_id = request.data.get('registration_id')
        try:
            reg = EventRegistration.objects.select_related('user', 'event').get(
                id=reg_id, event_id=pk
            )
        except EventRegistration.DoesNotExist:
            return Response({'error': 'Registration not found'}, status=404)

        approved = EventRegistration.objects.filter(event_id=pk, status='approved').count()
        if reg.event.capacity and approved >= reg.event.capacity:
            return Response({'error': 'Event is at full capacity'}, status=400)

        reg.status = 'approved'
        reg.save()

        # Award points to the student
        points = getattr(settings, 'EVENT_APPROVAL_POINTS', 10)
        reg.user.points += points
        reg.user.save(update_fields=['points'])

        Notification.objects.create(
            user=reg.user,
            message=f'You have been approved for "{reg.event.title}" (+{points} pts)',
            type='approved',
        )

        return Response({'message': 'Approved', 'points_awarded': points})


# ---------------------------------------------------------------------------
# REJECT REGISTRATION
# ---------------------------------------------------------------------------

class RejectRegistrationView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def post(self, request, pk):
        reg_id = request.data.get('registration_id')
        try:
            reg = EventRegistration.objects.select_related('user', 'event').get(
                id=reg_id, event_id=pk
            )
        except EventRegistration.DoesNotExist:
            return Response({'error': 'Registration not found'}, status=404)

        reg.status = 'rejected'
        reg.save()

        Notification.objects.create(
            user=reg.user,
            message=f'Your application for "{reg.event.title}" was not accepted',
            type='rejected',
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
            notif = Notification.objects.get(pk=pk, user=request.user)
        except Notification.DoesNotExist:
            return Response({'error': 'Notification not found'}, status=404)
        notif.is_read = True
        notif.save(update_fields=['is_read'])
        return Response({'message': 'Marked as read'})
