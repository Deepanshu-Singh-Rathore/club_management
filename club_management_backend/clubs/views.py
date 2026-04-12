from rest_framework import status, viewsets, mixins
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from rest_framework.response import Response

from accounts.permissions import IsAdmin, IsClubHeadOrAdmin
from .models import Club, JoinRequest
from .serializers import ClubSerializer, ClubCreateSerializer, JoinRequestSerializer


# ---------------------------------------------------------------------------
# Club Views
# ---------------------------------------------------------------------------

class ClubViewSet(viewsets.ModelViewSet):
    """Club APIs: list/retrieve for all, create for admin only."""

    queryset = Club.objects.select_related('created_by').all().order_by('name')

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        if self.action == 'create':
            return [IsAuthenticated(), IsAdmin()]
        return [IsAuthenticated(), IsAdmin()]

    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return ClubCreateSerializer
        return ClubSerializer

    def perform_create(self, serializer):
        created_by_id = serializer.validated_data.pop('created_by_id', None)
        if created_by_id:
            serializer.save(created_by_id=created_by_id)
            return
        serializer.save(created_by=self.request.user)


class JoinRequestViewSet(
    mixins.CreateModelMixin,
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    viewsets.GenericViewSet,
):
    """Join request APIs for students and club heads/admin approvals."""

    serializer_class = JoinRequestSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'admin':
            return JoinRequest.objects.select_related('user', 'club').all()
        if user.role == 'club_head':
            return JoinRequest.objects.select_related('user', 'club').filter(club__created_by=user)
        return JoinRequest.objects.select_related('user', 'club').filter(user=user)

    def create(self, request, *args, **kwargs):
        if request.user.role != 'student':
            return Response({'detail': 'Only students can send join requests.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        club_id = serializer.validated_data.get('club_id')
        exists = JoinRequest.objects.filter(user=request.user, club_id=club_id).exists()
        if exists:
            return Response({'detail': 'Join request already exists for this club.'}, status=status.HTTP_400_BAD_REQUEST)

        join_request = serializer.save()
        output = JoinRequestSerializer(join_request).data
        return Response(output, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsClubHeadOrAdmin])
    def approve(self, request, pk=None):
        join_request = self.get_object()
        if request.user.role == 'club_head' and join_request.club.created_by_id != request.user.id:
            return Response({'detail': 'You can approve only your club requests.'}, status=status.HTTP_403_FORBIDDEN)
        if join_request.status != JoinRequest.Status.PENDING:
            return Response({'detail': 'Only pending requests can be approved.'}, status=status.HTTP_400_BAD_REQUEST)
        join_request.status = JoinRequest.Status.APPROVED
        join_request.save(update_fields=['status'])
        return Response(JoinRequestSerializer(join_request).data)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated, IsClubHeadOrAdmin])
    def reject(self, request, pk=None):
        join_request = self.get_object()
        if request.user.role == 'club_head' and join_request.club.created_by_id != request.user.id:
            return Response({'detail': 'You can reject only your club requests.'}, status=status.HTTP_403_FORBIDDEN)
        if join_request.status != JoinRequest.Status.PENDING:
            return Response({'detail': 'Only pending requests can be rejected.'}, status=status.HTTP_400_BAD_REQUEST)
        join_request.status = JoinRequest.Status.REJECTED
        join_request.save(update_fields=['status'])
        return Response(JoinRequestSerializer(join_request).data)
