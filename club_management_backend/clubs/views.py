from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly

from .models import Club, Membership, Event, EventRegistration
from .serializers import (
    ClubSerializer,
    ClubCreateSerializer,
    MembershipSerializer,
    EventSerializer,
    EventCreateSerializer,
    EventRegistrationSerializer
)

from accounts.permissions import IsOwnerOrAdmin


# ---------------------------------------------------------------------------
# CLUB VIEWS
# ---------------------------------------------------------------------------

class ClubListCreateView(APIView):
    """
    GET  /api/clubs/  – list all clubs (public)
    POST /api/clubs/  – create a club (club_head or admin only)
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
            return Response({'error': 'Only admin can delete'}, status=403)

        club.delete()
        return Response({'message': 'Deleted'}, status=204)


class ClubJoinView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            club = Club.objects.get(pk=pk)
        except Club.DoesNotExist:
            return Response({'error': 'Club not found'}, status=404)

        membership, created = Membership.objects.get_or_create(
            user=request.user,
            club=club
        )

        if not created:
            return Response({'message': 'Already joined'}, status=200)

        return Response(MembershipSerializer(membership).data, status=201)


# ---------------------------------------------------------------------------
# EVENT VIEWS
# ---------------------------------------------------------------------------

class EventListCreateView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def get(self, request):
        events = Event.objects.select_related('club', 'created_by')
        return Response(EventSerializer(events, many=True).data)

    def post(self, request):

        
        return Response({'error': 'Only club_head or admin can create event'}, status=403)

        serializer = EventCreateSerializer(data=request.data)

        if not serializer.is_valid():
            print("❌ EVENT CREATE ERROR:", serializer.errors)  # DEBUG LINE
            return Response(serializer.errors, status=400)

        club = serializer.validated_data.get('club')

        if not club:
            return Response({"error": "club is required"}, status=400)

        event = serializer.save(
            created_by=request.user,
            club=club
        )

        return Response(EventSerializer(event).data, status=201)


# -------------------------------------------------------------------
# EVENT DETAIL
# -------------------------------------------------------------------

class EventDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, pk):
        try:
            return Event.objects.get(pk=pk)
        except Event.DoesNotExist:
            return None

    def get(self, request, pk):
        event = self.get_object(pk)
        if not event:
            return Response({"error": "Event not found"}, status=404)

        return Response(EventSerializer(event).data)


# -------------------------------------------------------------------
# APPLY EVENT (STUDENT)
# -------------------------------------------------------------------

class ApplyEventView(APIView):
    permission_classes = [IsAuthenticated, IsStudent]

    def post(self, request, pk):
        user = request.user

        try:
            event = Event.objects.get(pk=pk)
        except Event.DoesNotExist:
            return Response({"error": "Event not found"}, status=404)

        if EventRegistration.objects.filter(user=user, event=event).exists():
            return Response({"message": "Already applied"}, status=400)

        approved_count = EventRegistration.objects.filter(
            event=event,
            status="approved"
        ).count()

        if event.capacity and approved_count >= event.capacity:
            return Response({"message": "Event full"}, status=400)

        EventRegistration.objects.create(
            user=user,
            event=event,
            status="pending"
        )
        Notification.objects.create(
            user=event.created_by,
         message=f"{user.username} applied for {event.title}",
         type="apply"
        )

        return Response({"message": "Applied successfully"}, status=201)


# -------------------------------------------------------------------
# PENDING LIST (CLUB_HEAD / ADMIN)
# -------------------------------------------------------------------

class PendingRegistrationsView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def get(self, request, pk):

        return Response({"error": "Permission denied"}, status=403)

        regs = EventRegistration.objects.filter(event_id=pk, status="pending")

        return Response(EventRegistrationSerializer(regs, many=True).data)


# -------------------------------------------------------------------
# APPROVE
# -------------------------------------------------------------------

class ApproveRegistrationView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def post(self, request, pk):

        return Response({"error": "Permission denied"}, status=403)

        reg_id = request.data.get("registration_id")

        try:
            reg = EventRegistration.objects.get(id=reg_id, event_id=pk)
        except EventRegistration.DoesNotExist:
            return Response({"error": "Not found"}, status=404)

        approved = EventRegistration.objects.filter(
            event_id=pk,
            status="approved"
        ).count()

        if reg.event.capacity and approved >= reg.event.capacity:
            return Response({"error": "Capacity full"}, status=400)

        reg.status = "approved"
        reg.save()
        Notification.objects.create(
            user=reg.user,
            message=f"You are approved for {reg.event.title}",
            type="approved"
        )

        return Response({"message": "Approved"})


# -------------------------------------------------------------------
# REJECT
# -------------------------------------------------------------------

class RejectRegistrationView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def post(self, request, pk):
        
        return Response({"error": "Permission denied"}, status=403)

        reg_id = request.data.get("registration_id")

        try:
            reg = EventRegistration.objects.get(id=reg_id, event_id=pk)
        except EventRegistration.DoesNotExist:
            return Response({"error": "Not found"}, status=404)

        reg.status = "rejected"
        reg.save()

        Notification.objects.create(
            user=reg.user,
            message=f"You are rejected for {reg.event.title}",
            type="rejected"
        )

        return Response({"message": "Rejected"})

class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(
            user=request.user
        ).order_by('-created_at')

        return Response(NotificationSerializer(notifications, many=True).data)

class MarkNotificationReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        notif = Notification.objects.get(pk=pk, user=request.user)
        notif.is_read = True
        notif.save()
        return Response({"message": "Marked as read"})
