from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.permissions import IsClubHead, IsClubHeadOrAdmin

from .models import Event, EventRegistration
from .serializers import EventCreateSerializer, EventRegistrationSerializer, EventSerializer


class EventViewSet(viewsets.ModelViewSet):
    """Event APIs for listing, creating and student registrations."""

    queryset = Event.objects.select_related('club', 'created_by').all().order_by('event_date')

    def get_permissions(self):
        if self.action in ['list', 'retrieve', 'register']:
            return [IsAuthenticated()]
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAuthenticated(), IsClubHead()]
        if self.action in ['participants']:
            return [IsAuthenticated(), IsClubHeadOrAdmin()]
        return [IsAuthenticated()]

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return EventCreateSerializer
        return EventSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        club_id = self.request.query_params.get('club')
        if club_id:
            queryset = queryset.filter(club_id=club_id)
        return queryset

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def register(self, request, pk=None):
        if request.user.role != 'student':
            return Response({'detail': 'Only students can register for events.'}, status=status.HTTP_403_FORBIDDEN)

        event = self.get_object()
        registration, created = EventRegistration.objects.get_or_create(user=request.user, event=event)
        if not created:
            return Response({'detail': 'Already registered for this event.'}, status=status.HTTP_400_BAD_REQUEST)

        return Response(EventRegistrationSerializer(registration).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'], permission_classes=[IsAuthenticated, IsClubHeadOrAdmin])
    def participants(self, request, pk=None):
        event = self.get_object()
        if request.user.role == 'club_head' and event.club.created_by_id != request.user.id:
            return Response({'detail': 'You can view participants only for your club events.'}, status=status.HTTP_403_FORBIDDEN)

        regs = EventRegistration.objects.select_related('user', 'event').filter(event=event)
        return Response(EventRegistrationSerializer(regs, many=True).data)
