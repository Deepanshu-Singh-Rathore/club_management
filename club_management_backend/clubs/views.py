from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly

from accounts.permissions import IsClubHeadOrAdmin, IsOwnerOrAdmin

from .models import Club, Membership, Event
from .serializers import (
    ClubSerializer,
    ClubCreateSerializer,
    MembershipSerializer,
    EventSerializer,
    EventCreateSerializer,
)


# ---------------------------------------------------------------------------
# Club Views
# ---------------------------------------------------------------------------

class ClubListCreateView(APIView):
    """
    GET  /api/clubs/  – list all clubs (public)
    POST /api/clubs/  – create a club (club_head or admin only)
    """

    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        clubs = Club.objects.all().select_related('created_by').prefetch_related('memberships')
        serializer = ClubSerializer(clubs, many=True)
        return Response(serializer.data)

    def post(self, request):
        # Only club_head or admin may create clubs
        if request.user.role not in ('club_head', 'admin'):
            return Response(
                {'error': 'Only club heads or admins can create clubs.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = ClubCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        club = serializer.save(created_by=request.user)
        return Response(ClubSerializer(club).data, status=status.HTTP_201_CREATED)


class ClubDetailView(APIView):
    """
    GET    /api/clubs/{id}/  – retrieve a club
    PUT    /api/clubs/{id}/  – update (owner or admin)
    DELETE /api/clubs/{id}/  – delete (admin only)
    """

    permission_classes = [IsAuthenticated]

    def _get_club(self, pk):
        try:
            return Club.objects.get(pk=pk)
        except Club.DoesNotExist:
            return None

    def get(self, request, pk):
        club = self._get_club(pk)
        if not club:
            return Response({'error': 'Club not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(ClubSerializer(club).data)

    def put(self, request, pk):
        club = self._get_club(pk)
        if not club:
            return Response({'error': 'Club not found.'}, status=status.HTTP_404_NOT_FOUND)

        permission = IsOwnerOrAdmin()
        if not permission.has_object_permission(request, self, club):
            return Response({'error': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = ClubCreateSerializer(club, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        club = serializer.save()
        return Response(ClubSerializer(club).data)

    def delete(self, request, pk):
        club = self._get_club(pk)
        if not club:
            return Response({'error': 'Club not found.'}, status=status.HTTP_404_NOT_FOUND)

        if request.user.role != 'admin':
            return Response({'error': 'Only admins can delete clubs.'}, status=status.HTTP_403_FORBIDDEN)

        club.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ClubJoinView(APIView):
    """
    POST /api/clubs/{id}/join/  – join a club (any authenticated user)
    """

    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            club = Club.objects.get(pk=pk)
        except Club.DoesNotExist:
            return Response({'error': 'Club not found.'}, status=status.HTTP_404_NOT_FOUND)

        membership, created = Membership.objects.get_or_create(user=request.user, club=club)
        if not created:
            return Response({'message': 'You are already a member of this club.'}, status=status.HTTP_200_OK)

        return Response(
            MembershipSerializer(membership).data,
            status=status.HTTP_201_CREATED,
        )


# ---------------------------------------------------------------------------
# Event Views
# ---------------------------------------------------------------------------

class EventListCreateView(APIView):
    """
    GET  /api/events/  – list all events (any authenticated user)
    POST /api/events/  – create an event (club_head or admin only)
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        events = (
            Event.objects.all()
            .select_related('club', 'created_by')
            .order_by('event_date')
        )
        # Optional filter by club
        club_id = request.query_params.get('club')
        if club_id:
            events = events.filter(club_id=club_id)

        serializer = EventSerializer(events, many=True)
        return Response(serializer.data)

    def post(self, request):
        if request.user.role not in ('club_head', 'admin'):
            return Response(
                {'error': 'Only club heads or admins can create events.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = EventCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        # club_head may only create events for clubs they own (unless admin)
        club = serializer.validated_data['club']
        if request.user.role == 'club_head' and club.created_by != request.user:
            return Response(
                {'error': 'You can only create events for your own club.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        event = serializer.save(created_by=request.user)
        return Response(EventSerializer(event).data, status=status.HTTP_201_CREATED)


class EventDetailView(APIView):
    """
    GET    /api/events/{id}/
    PUT    /api/events/{id}/
    DELETE /api/events/{id}/
    """

    permission_classes = [IsAuthenticated]

    def _get_event(self, pk):
        try:
            return Event.objects.get(pk=pk)
        except Event.DoesNotExist:
            return None

    def get(self, request, pk):
        event = self._get_event(pk)
        if not event:
            return Response({'error': 'Event not found.'}, status=status.HTTP_404_NOT_FOUND)
        return Response(EventSerializer(event).data)

    def put(self, request, pk):
        event = self._get_event(pk)
        if not event:
            return Response({'error': 'Event not found.'}, status=status.HTTP_404_NOT_FOUND)

        permission = IsOwnerOrAdmin()
        if not permission.has_object_permission(request, self, event):
            return Response({'error': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = EventCreateSerializer(event, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        event = serializer.save()
        return Response(EventSerializer(event).data)

    def delete(self, request, pk):
        event = self._get_event(pk)
        if not event:
            return Response({'error': 'Event not found.'}, status=status.HTTP_404_NOT_FOUND)

        permission = IsOwnerOrAdmin()
        if not permission.has_object_permission(request, self, event):
            return Response({'error': 'Permission denied.'}, status=status.HTTP_403_FORBIDDEN)

        event.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
