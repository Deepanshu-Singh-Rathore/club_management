from django.conf import settings
from django.core.cache import cache
from django.db.models import Count, Q, F
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAuthenticatedOrReadOnly
from django.db import transaction
from django.utils import timezone
from datetime import timedelta

from accounts.models import User
from .models import (
    Club,
    Membership,
    Event,
    EventRegistration,
    Notification,
    EventSuggestionPoll,
    EventSuggestion,
    ClubMessage,
    ClubPost,
    ClubPostLike,
    ClubPostComment,
    UserAchievement,
)
from .serializers import (
    ClubSerializer,
    ClubCreateSerializer,
    MembershipSerializer,
    EventSerializer,
    EventCreateSerializer,
    EventRegistrationSerializer,
    NotificationSerializer,
    ClubMessageSerializer,
    ClubPostSerializer,
    ClubPostCreateSerializer,
    ClubPostCommentSerializer,
    UserAchievementSerializer,
)
from accounts.permissions import IsOwnerOrAdmin, IsClubHeadOrAdmin, IsStudent


# ---------------------------------------------------------------------------
# ACHIEVEMENT EVALUATION HELPER
# ---------------------------------------------------------------------------

def evaluate_user_achievements(user):
    """
    Evaluates and automatically awards achievements based on actual activity.
    Fast and safe; executed after key user actions.
    """
    if not user or not user.is_authenticated:
        return

    # 1. First Event
    regs_count = EventRegistration.objects.filter(user=user, status='approved').count()
    if regs_count >= 1:
        ach, created = UserAchievement.objects.get_or_create(
            user=user,
            badge_code='first_event',
            defaults={
                'title': 'First Event',
                'description': 'Attended or registered for your first campus event.',
                'icon': 'star',
            }
        )
        if created:
            Notification.objects.create(
                user=user,
                message='🏆 Achievement Unlocked: First Event!',
                type='achievement',
            )

    # 2. Club Explorer (Joined 3+ clubs)
    clubs_joined = Membership.objects.filter(user=user).count()
    if clubs_joined >= 3:
        ach, created = UserAchievement.objects.get_or_create(
            user=user,
            badge_code='club_explorer',
            defaults={
                'title': 'Club Explorer',
                'description': 'Became a member of 3 or more campus clubs.',
                'icon': 'compass',
            }
        )
        if created:
            Notification.objects.create(
                user=user,
                message='🏆 Achievement Unlocked: Club Explorer!',
                type='achievement',
            )

    # 3. Event Enthusiast (Registered for 5+ events)
    if regs_count >= 5:
        ach, created = UserAchievement.objects.get_or_create(
            user=user,
            badge_code='event_enthusiast',
            defaults={
                'title': 'Event Enthusiast',
                'description': 'Registered for 5 or more campus events.',
                'icon': 'trophy',
            }
        )
        if created:
            Notification.objects.create(
                user=user,
                message='🏆 Achievement Unlocked: Event Enthusiast!',
                type='achievement',
            )

    # 4. Community Voice (3+ messages or comments)
    msgs = ClubMessage.objects.filter(sender=user).count()
    comments = ClubPostComment.objects.filter(author=user).count()
    if (msgs + comments) >= 3:
        ach, created = UserAchievement.objects.get_or_create(
            user=user,
            badge_code='community_voice',
            defaults={
                'title': 'Community Voice',
                'description': 'Actively participated in club discussions.',
                'icon': 'chat',
            }
        )
        if created:
            Notification.objects.create(
                user=user,
                message='🏆 Achievement Unlocked: Community Voice!',
                type='achievement',
            )


# ---------------------------------------------------------------------------
# CLUB VIEWS
# ---------------------------------------------------------------------------

class ClubListCreateView(APIView):
    """
    GET  /api/clubs/   – list all clubs with filtering & sorting
    POST /api/clubs/   – create a club (club_head or admin only)
    """
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        category = request.query_params.get('category', '').strip()
        search = request.query_params.get('search', '').strip()
        sort = request.query_params.get('sort', 'name').strip()

        # Cache key based on filter params
        cache_key = f'clubs_list_{category}_{search}_{sort}'
        cached_data = cache.get(cache_key)
        if cached_data is not None:
            return Response(cached_data)

        clubs = (
            Club.objects
            .select_related('created_by')
            .annotate(
                member_count_annotated=Count('memberships', distinct=True),
                events_count_annotated=Count('events', distinct=True)
            )
            .filter(is_active=True)
        )

        if category and category.lower() != 'all':
            clubs = clubs.filter(category__iexact=category)

        if search:
            clubs = clubs.filter(
                Q(name__icontains=search) | Q(description__icontains=search)
            )

        if sort == 'popular':
            clubs = clubs.order_by('-member_count_annotated', 'name')
        elif sort == 'newest':
            clubs = clubs.order_by('-created_at')
        else:
            clubs = clubs.order_by('name')

        data = ClubSerializer(clubs, many=True).data
        cache.set(cache_key, data, timeout=60)
        return Response(data)

    def post(self, request):
        if request.user.role not in ('club_head', 'admin'):
            return Response({'error': 'Only club heads or admins can create clubs'}, status=403)

        serializer = ClubCreateSerializer(data=request.data)
        if serializer.is_valid():
            club = serializer.save(created_by=request.user)
            Membership.objects.create(user=request.user, club=club, role='lead')
            # Invalidate caches
            cache.clear()
            return Response(ClubSerializer(club).data, status=201)

        return Response(serializer.errors, status=400)


class ClubDetailView(APIView):
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_object(self, pk):
        return (
            Club.objects
            .select_related('created_by')
            .annotate(
                member_count_annotated=Count('memberships', distinct=True),
                events_count_annotated=Count('events', distinct=True)
            )
            .filter(pk=pk)
            .first()
        )

    def get(self, request, pk):
        cache_key = f'club_detail_{pk}'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        club = self.get_object(pk)
        if not club:
            return Response({'error': 'Club not found'}, status=404)
        data = ClubSerializer(club).data
        cache.set(cache_key, data, timeout=60)
        return Response(data)

    def put(self, request, pk):
        club = self.get_object(pk)
        if not club:
            return Response({'error': 'Club not found'}, status=404)

        if not IsOwnerOrAdmin().has_object_permission(request, self, club):
            return Response({'error': 'Permission denied'}, status=403)

        serializer = ClubCreateSerializer(club, data=request.data, partial=True)
        if serializer.is_valid():
            club = serializer.save()
            cache.delete(f'club_detail_{pk}')
            cache.clear()
            return Response(ClubSerializer(club).data)

        return Response(serializer.errors, status=400)

    def delete(self, request, pk):
        club = self.get_object(pk)
        if not club:
            return Response({'error': 'Club not found'}, status=404)

        if request.user.role != 'admin':
            return Response({'error': 'Only admin can delete clubs'}, status=403)

        club.delete()
        cache.clear()
        return Response(status=204)


class ClubJoinView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            club = Club.objects.get(pk=pk, is_active=True)
        except Club.DoesNotExist:
            return Response({'error': 'Club not found'}, status=404)

        membership, created = Membership.objects.get_or_create(
            user=request.user, club=club, defaults={'role': 'member'}
        )

        if not created:
            return Response({'message': 'Already a member'}, status=200)

        # Evaluate achievements
        evaluate_user_achievements(request.user)

        # Notify club creator
        if club.created_by and club.created_by != request.user:
            Notification.objects.create(
                user=club.created_by,
                message=f"{request.user.full_name or request.user.email} joined {club.name}",
                type='announcement',
                club=club,
            )

        cache.delete(f'club_detail_{pk}')
        cache.delete(f'club_members_{pk}')
        cache.delete(f'user_clubs_{request.user.id}')
        cache.delete(f'recommendations_{request.user.id}')
        return Response(MembershipSerializer(membership).data, status=201)


class ClubLeaveView(APIView):
    """POST /api/clubs/<id>/leave/ – leave a club"""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            membership = Membership.objects.get(user=request.user, club_id=pk)
            membership.delete()
            cache.delete(f'club_detail_{pk}')
            cache.delete(f'club_members_{pk}')
            cache.delete(f'user_clubs_{request.user.id}')
            cache.delete(f'recommendations_{request.user.id}')
            return Response({'message': 'Successfully left the club'})
        except Membership.DoesNotExist:
            return Response({'error': 'You are not a member of this club'}, status=400)


class ClubMembersView(APIView):
    """
    GET    /api/clubs/<id>/members/ – list members
    POST   /api/clubs/<id>/members/<user_id>/role/ – update member role
    DELETE /api/clubs/<id>/members/<user_id>/ – remove member
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            club = Club.objects.select_related('created_by').get(pk=pk)
        except Club.DoesNotExist:
            return Response({'error': 'Club not found'}, status=404)

        search = request.query_params.get('search', '').strip()
        memberships = Membership.objects.filter(club=club).select_related('user').order_by('-joined_at')

        if search:
            memberships = memberships.filter(
                Q(user__full_name__icontains=search) |
                Q(user__email__icontains=search) |
                Q(user__roll_number__icontains=search)
            )

        members = [
            {
                'id': str(m.user.id),
                'full_name': m.user.full_name or m.user.email.split('@')[0],
                'email': m.user.email,
                'phone_number': m.user.phone_number,
                'roll_number': m.user.roll_number,
                'department': m.user.department,
                'role': m.role,
                'user_system_role': m.user.role,
                'joined_at': m.joined_at.isoformat(),
            }
            for m in memberships
        ]

        data = {
            'club_id': str(club.id),
            'club_name': club.name,
            'member_count': len(members),
            'members': members,
        }
        return Response(data)

    def delete(self, request, pk):
        """Remove member from club: pass ?user_id=<uuid> in query or body"""
        user_id = request.data.get('user_id') or request.query_params.get('user_id')
        if not user_id:
            return Response({'error': 'user_id is required'}, status=400)

        try:
            club = Club.objects.get(pk=pk)
        except Club.DoesNotExist:
            return Response({'error': 'Club not found'}, status=404)

        is_admin = request.user.role == 'admin'
        is_owner = request.user.role == 'club_head' and club.created_by == request.user
        if not (is_admin or is_owner):
            return Response({'error': 'Permission denied'}, status=403)

        Membership.objects.filter(club=club, user_id=user_id).delete()
        cache.delete(f'club_detail_{pk}')
        cache.delete(f'club_members_{pk}')
        return Response({'message': 'Member removed'})


class UserClubsView(APIView):
    """
    GET /api/clubs/user/my/ – list clubs the authenticated user is a member of
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        cache_key = f'user_clubs_{request.user.id}'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        memberships = (
            Membership.objects
            .filter(user=request.user)
            .select_related('club__created_by')
            .annotate(club_member_count=Count('club__memberships'))
            .order_by('-joined_at')
        )
        clubs = [
            {
                'id': str(m.club.id),
                'name': m.club.name,
                'description': m.club.description,
                'category': m.club.category,
                'banner_url': m.club.banner_url,
                'logo_url': m.club.logo_url,
                'member_count': m.club_member_count,
                'role': m.role,
                'created_by': {
                    'full_name': m.club.created_by.full_name if m.club.created_by else None,
                } if m.club.created_by else None,
                'joined_at': m.joined_at.isoformat(),
            }
            for m in memberships
        ]
        cache.set(cache_key, clubs, timeout=60)
        return Response(clubs)


# ---------------------------------------------------------------------------
# EVENT VIEWS
# ---------------------------------------------------------------------------

class EventListCreateView(APIView):
    """
    GET  /api/clubs/events/   – list events with category, club, date period, and search filters
    POST /api/clubs/events/   – create event (club_head / admin)
    """
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        club_id = request.query_params.get('club')
        category = request.query_params.get('category')
        period = request.query_params.get('period')  # upcoming, past, today
        search = request.query_params.get('search')
        status_filter = request.query_params.get('status')

        cache_key = f'events_{club_id}_{category}_{period}_{search}_{status_filter}'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        events = (
            Event.objects
            .select_related('club', 'created_by')
            .annotate(
                approved_registrations_count=Count('registrations', filter=Q(registrations__status='approved'))
            )
        )

        now = timezone.now()

        if period == 'upcoming':
            events = events.filter(event_date__gte=now).order_by('event_date')
        elif period == 'past':
            events = events.filter(event_date__lt=now).order_by('-event_date')
        elif period == 'today':
            today_start = now.replace(hour=0, minute=0, second=0)
            today_end = now.replace(hour=23, minute=59, second=59)
            events = events.filter(event_date__range=(today_start, today_end)).order_by('event_date')
        else:
            events = events.order_by('-event_date')

        if club_id:
            events = events.filter(club_id=club_id)

        if category and category.lower() != 'all':
            events = events.filter(category__iexact=category)

        if status_filter:
            events = events.filter(status=status_filter)

        if search:
            events = events.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search) |
                Q(venue__icontains=search)
            )

        data = EventSerializer(events, many=True).data
        cache.set(cache_key, data, timeout=60)
        return Response(data)

    def post(self, request):
        if request.user.role not in ('club_head', 'admin'):
            return Response({'error': 'Only club heads or admins can create events'}, status=403)

        serializer = EventCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        with transaction.atomic():
            event = serializer.save(created_by=request.user)

            # Send notification to club members or students
            members = Membership.objects.filter(club=event.club).select_related('user')
            notif_users = [m.user for m in members if m.user != request.user]
            if not notif_users:
                notif_users = list(User.objects.filter(role='student')[:30])

            notifications = [
                Notification(
                    user=user,
                    message=f"New Event by {event.club.name}: {event.title}",
                    type="event",
                    event=event,
                    club=event.club,
                )
                for user in notif_users
            ]
            if notifications:
                Notification.objects.bulk_create(notifications)

            cache.clear()

        return Response(EventSerializer(event).data, status=201)


class EventDetailView(APIView):
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_object(self, pk):
        return (
            Event.objects
            .select_related('club', 'created_by')
            .annotate(
                approved_registrations_count=Count('registrations', filter=Q(registrations__status='approved'))
            )
            .filter(pk=pk)
            .first()
        )

    def get(self, request, pk):
        cache_key = f'event_detail_{pk}'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        event = self.get_object(pk)
        if not event:
            return Response({'error': 'Event not found'}, status=404)

        data = EventSerializer(event).data
        cache.set(cache_key, data, timeout=60)
        return Response(data)

    def put(self, request, pk):
        event = self.get_object(pk)
        if not event:
            return Response({'error': 'Event not found'}, status=404)

        if request.user.role not in ('club_head', 'admin'):
            return Response({'error': 'Permission denied'}, status=403)

        serializer = EventCreateSerializer(event, data=request.data, partial=True)
        if serializer.is_valid():
            event = serializer.save()
            cache.clear()
            return Response(EventSerializer(event).data)
        return Response(serializer.errors, status=400)

    def delete(self, request, pk):
        event = self.get_object(pk)
        if not event:
            return Response({'error': 'Event not found'}, status=404)

        if request.user.role not in ('club_head', 'admin'):
            return Response({'error': 'Permission denied'}, status=403)

        event.status = Event.Status.CANCELLED
        event.save(update_fields=['status'])

        # Notify registered users of cancellation
        registrations = EventRegistration.objects.filter(event=event).select_related('user')
        notifs = [
            Notification(
                user=reg.user,
                message=f'Event "{event.title}" has been cancelled.',
                type='event',
                event=event,
                club=event.club,
            )
            for reg in registrations
        ]
        if notifs:
            Notification.objects.bulk_create(notifs)

        cache.clear()
        return Response({'message': 'Event cancelled successfully'})


# ---------------------------------------------------------------------------
# MY EVENTS – registrations for the authenticated user
# ---------------------------------------------------------------------------

class MyEventsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        cache_key = f'my_registrations_{request.user.id}'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        regs = (
            EventRegistration.objects
            .filter(user=request.user)
            .select_related('user', 'event__club', 'event__created_by')
            .order_by('-created_at')
        )
        data = EventRegistrationSerializer(regs, many=True).data
        cache.set(cache_key, data, timeout=60)
        return Response(data)


# ---------------------------------------------------------------------------
# APPLY FOR EVENT (Registration)
# ---------------------------------------------------------------------------

class ApplyEventView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            event = Event.objects.select_related('club').get(pk=pk)
        except Event.DoesNotExist:
            return Response({'error': 'Event not found'}, status=404)

        if event.status == Event.Status.CANCELLED:
            return Response({'error': 'This event has been cancelled'}, status=400)

        now = timezone.now()
        if event.registration_deadline and now > event.registration_deadline:
            return Response({'error': 'Registration deadline has passed'}, status=400)

        if EventRegistration.objects.filter(user=request.user, event=event).exists():
            return Response({'error': 'You are already registered for this event'}, status=400)

        approved_count = EventRegistration.objects.filter(
            event=event,
            status='approved'
        ).count()

        if event.capacity and approved_count >= event.capacity:
            return Response({'error': 'Registration is full. Event reached maximum capacity.'}, status=400)

        reg = EventRegistration.objects.create(
            user=request.user,
            event=event,
            status='approved',  # Direct approval for student-friendly campus experience
            attendance_status='registered',
        )

        # Award points & evaluate achievements
        request.user.points += getattr(settings, 'EVENT_APPROVAL_POINTS', 10)
        request.user.save(update_fields=['points'])
        evaluate_user_achievements(request.user)

        # Notify student with confirmation
        Notification.objects.create(
            user=request.user,
            message=f'You are confirmed for "{event.title}"! Ticket ID: {reg.ticket_id}',
            type='approved',
            event=event,
            club=event.club,
        )

        # Invalidate caches
        cache.delete(f'my_registrations_{request.user.id}')
        cache.delete(f'event_detail_{pk}')
        cache.delete(f'notifications_{request.user.id}')
        cache.delete('admin_dashboard_stats')

        return Response({
            'message': 'You are successfully registered!',
            'ticket_id': reg.ticket_id,
            'registration': EventRegistrationSerializer(reg).data,
        }, status=201)


class CancelRegistrationView(APIView):
    """POST /api/clubs/events/<id>/cancel/ – cancel registration"""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            reg = EventRegistration.objects.get(user=request.user, event_id=pk)
        except EventRegistration.DoesNotExist:
            return Response({'error': 'Registration not found'}, status=404)

        if reg.attendance_status == 'checked_in':
            return Response({'error': 'Cannot cancel an event you already checked into'}, status=400)

        reg.attendance_status = 'cancelled'
        reg.status = 'rejected'
        reg.save(update_fields=['attendance_status', 'status'])

        cache.delete(f'my_registrations_{request.user.id}')
        cache.delete(f'event_detail_{pk}')
        return Response({'message': 'Registration cancelled successfully'})


# ---------------------------------------------------------------------------
# EVENT ATTENDANCE & CHECK-IN (QR Code & Ticket Verification)
# ---------------------------------------------------------------------------

class CheckInAttendanceView(APIView):
    """
    POST /api/clubs/events/<id>/check-in/
    Body: { "ticket_id": str } or { "registration_id": str }
    Verifies ticket, confirms event, marks attendance, prevents duplicate check-in.
    """
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def post(self, request, pk):
        ticket_id = request.data.get('ticket_id', '').strip()
        reg_id = request.data.get('registration_id', '').strip()

        try:
            event = Event.objects.get(pk=pk)
        except Event.DoesNotExist:
            return Response({'error': 'Event not found'}, status=404)

        # Check authorization
        if request.user.role == 'club_head' and event.club.created_by != request.user and event.created_by != request.user:
            return Response({'error': 'Permission denied: only event organizer or admin can check in attendees'}, status=403)

        reg_query = EventRegistration.objects.select_related('user', 'event').filter(event=event)
        if ticket_id:
            reg = reg_query.filter(ticket_id__iexact=ticket_id).first()
        elif reg_id:
            reg = reg_query.filter(id=reg_id).first()
        else:
            return Response({'error': 'Either ticket_id or registration_id must be provided'}, status=400)

        if not reg:
            return Response({'error': 'Valid registration ticket not found for this event'}, status=404)

        if reg.attendance_status == 'checked_in':
            return Response({
                'message': f"Attendee already checked in at {reg.attended_at.strftime('%H:%M, %d %b %Y') if reg.attended_at else 'earlier'}",
                'attendee': reg.user.full_name or reg.user.email,
                'already_checked_in': True,
                'ticket_id': reg.ticket_id,
            }, status=200)

        reg.attendance_status = 'checked_in'
        reg.attended_at = timezone.now()
        reg.checked_in_by = request.user
        reg.status = 'approved'
        reg.save(update_fields=['attendance_status', 'attended_at', 'checked_in_by', 'status'])

        # Notify student
        Notification.objects.create(
            user=reg.user,
            message=f'Checked in for "{event.title}". Welcome!',
            type='checkin',
            event=event,
            club=event.club,
        )

        return Response({
            'message': f'Check-in successful! Welcome {reg.user.full_name or reg.user.email}',
            'attendee': reg.user.full_name or reg.user.email,
            'roll_number': reg.user.roll_number,
            'ticket_id': reg.ticket_id,
            'attended_at': reg.attended_at.isoformat(),
        }, status=200)


class EventRegistrationsListView(APIView):
    """
    GET /api/clubs/events/<id>/registrations/ – list all registrations with attendance status
    """
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def get(self, request, pk):
        try:
            event = Event.objects.get(pk=pk)
        except Event.DoesNotExist:
            return Response({'error': 'Event not found'}, status=404)

        status_param = request.query_params.get('status')
        attendance_param = request.query_params.get('attendance')

        regs = (
            EventRegistration.objects
            .filter(event=event)
            .select_related('user')
            .order_by('-created_at')
        )

        if status_param:
            regs = regs.filter(status=status_param)
        if attendance_param:
            regs = regs.filter(attendance_status=attendance_param)

        data = [
            {
                'id': str(r.id),
                'ticket_id': r.ticket_id,
                'status': r.status,
                'attendance_status': r.attendance_status,
                'attended_at': r.attended_at.isoformat() if r.attended_at else None,
                'user': {
                    'id': str(r.user.id),
                    'full_name': r.user.full_name or r.user.email.split('@')[0],
                    'email': r.user.email,
                    'roll_number': r.user.roll_number,
                    'department': r.user.department,
                },
                'created_at': r.created_at.isoformat(),
            }
            for r in regs
        ]

        total_registered = len(data)
        checked_in = sum(1 for r in data if r['attendance_status'] == 'checked_in')

        return Response({
            'event_id': str(event.id),
            'event_title': event.title,
            'capacity': event.capacity,
            'total_registered': total_registered,
            'checked_in_count': checked_in,
            'registrations': data,
        })


# Legacy pending / approve / reject support
class PendingRegistrationsView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def get(self, request, pk):
        regs = (
            EventRegistration.objects
            .filter(event_id=pk, status='pending')
            .select_related('user', 'event', 'event__club')
        )
        return Response(EventRegistrationSerializer(regs, many=True).data)


class ApproveRegistrationView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def post(self, request, pk):
        reg_id = request.data.get('registration_id')
        try:
            reg = EventRegistration.objects.select_related('user', 'event', 'event__club').get(id=reg_id, event_id=pk)
        except EventRegistration.DoesNotExist:
            return Response({'error': 'Registration not found'}, status=404)

        reg.status = 'approved'
        reg.attendance_status = 'registered'
        reg.save(update_fields=['status', 'attendance_status'])

        Notification.objects.create(
            user=reg.user,
            message=f'Your registration for "{reg.event.title}" has been approved! Ticket ID: {reg.ticket_id}',
            type='approved',
            event=reg.event,
            club=reg.event.club,
        )
        cache.clear()
        return Response({'message': 'Approved'})


class RejectRegistrationView(APIView):
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def post(self, request, pk):
        reg_id = request.data.get('registration_id')
        try:
            reg = EventRegistration.objects.select_related('user', 'event', 'event__club').get(id=reg_id, event_id=pk)
        except EventRegistration.DoesNotExist:
            return Response({'error': 'Registration not found'}, status=404)

        reg.status = 'rejected'
        reg.save(update_fields=['status'])

        Notification.objects.create(
            user=reg.user,
            message=f'Your application for "{reg.event.title}" was not approved',
            type='rejected',
            event=reg.event,
            club=reg.event.club,
        )
        cache.clear()
        return Response({'message': 'Rejected'})


# ---------------------------------------------------------------------------
# COMMUNITY FEED & POSTS
# ---------------------------------------------------------------------------

class ClubFeedView(APIView):
    """
    GET /api/clubs/feed/ – campus-wide or joined clubs feed
    """
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        post_type = request.query_params.get('type')  # announcement, general, event
        club_id = request.query_params.get('club')

        posts = (
            ClubPost.objects
            .select_related('club', 'author')
            .prefetch_related('likes', 'comments')
            .annotate(
                likes_count_annotated=Count('likes', distinct=True),
                comments_count_annotated=Count('comments', distinct=True),
            )
            .order_by('-created_at')
        )

        if post_type:
            posts = posts.filter(post_type=post_type)
        if club_id:
            posts = posts.filter(club_id=club_id)

        serializer = ClubPostSerializer(posts[:50], many=True, context={'request': request})
        return Response(serializer.data)


class ClubPostsView(APIView):
    """
    GET  /api/clubs/<id>/posts/ – get posts for a club
    POST /api/clubs/<id>/posts/ – create post (admin / club head)
    """
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request, pk):
        posts = (
            ClubPost.objects
            .filter(club_id=pk)
            .select_related('club', 'author')
            .prefetch_related('likes', 'comments')
            .annotate(
                likes_count_annotated=Count('likes', distinct=True),
                comments_count_annotated=Count('comments', distinct=True),
            )
            .order_by('-created_at')
        )
        serializer = ClubPostSerializer(posts[:40], many=True, context={'request': request})
        return Response(serializer.data)

    def post(self, request, pk):
        if not request.user.is_authenticated:
            return Response({'error': 'Authentication required'}, status=401)

        try:
            club = Club.objects.get(pk=pk)
        except Club.DoesNotExist:
            return Response({'error': 'Club not found'}, status=404)

        is_admin = request.user.role == 'admin'
        is_owner = request.user.role == 'club_head' and club.created_by == request.user
        is_lead = Membership.objects.filter(club=club, user=request.user, role__in=['lead', 'coordinator']).exists()

        if not (is_admin or is_owner or is_lead):
            return Response({'error': 'Only club leads or admins can publish posts'}, status=403)

        serializer = ClubPostCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        post = serializer.save(club=club, author=request.user)

        # If announcement, notify club members
        if post.post_type == 'announcement':
            members = Membership.objects.filter(club=club).select_related('user')
            notifs = [
                Notification(
                    user=m.user,
                    message=f"[{club.name}] Announcement: {post.title}",
                    type="announcement",
                    club=club,
                    post=post,
                )
                for m in members if m.user != request.user
            ]
            if notifs:
                Notification.objects.bulk_create(notifs)

        return Response(ClubPostSerializer(post, context={'request': request}).data, status=201)


class ClubPostLikeView(APIView):
    """POST /api/clubs/posts/<id>/like/ – toggle like"""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            post = ClubPost.objects.get(pk=pk)
        except ClubPost.DoesNotExist:
            return Response({'error': 'Post not found'}, status=404)

        like = ClubPostLike.objects.filter(post=post, user=request.user).first()
        if like:
            like.delete()
            is_liked = False
        else:
            ClubPostLike.objects.create(post=post, user=request.user)
            is_liked = True

        count = post.likes.count()
        return Response({'is_liked': is_liked, 'likes_count': count})


class ClubPostCommentsView(APIView):
    """
    GET  /api/clubs/posts/<id>/comments/ – list comments
    POST /api/clubs/posts/<id>/comments/ – add comment
    """
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request, pk):
        comments = (
            ClubPostComment.objects
            .filter(post_id=pk)
            .select_related('author')
            .order_by('created_at')[:100]
        )
        return Response(ClubPostCommentSerializer(comments, many=True).data)

    def post(self, request, pk):
        if not request.user.is_authenticated:
            return Response({'error': 'Authentication required'}, status=401)

        try:
            post = ClubPost.objects.get(pk=pk)
        except ClubPost.DoesNotExist:
            return Response({'error': 'Post not found'}, status=404)

        content = request.data.get('content', '').strip()
        if not content:
            return Response({'error': 'Comment content cannot be empty'}, status=400)

        comment = ClubPostComment.objects.create(
            post=post,
            author=request.user,
            content=content,
        )

        evaluate_user_achievements(request.user)
        return Response(ClubPostCommentSerializer(comment).data, status=201)


# ---------------------------------------------------------------------------
# ANNOUNCEMENTS VIEW
# ---------------------------------------------------------------------------

class AnnouncementsListView(APIView):
    """GET /api/clubs/announcements/ – get recent campus announcements"""
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        cache_key = 'recent_announcements'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        announcements = (
            ClubPost.objects
            .filter(post_type='announcement')
            .select_related('club', 'author')
            .order_by('-created_at')[:10]
        )
        data = [
            {
                'id': str(a.id),
                'title': a.title,
                'content': a.content,
                'club_id': str(a.club.id),
                'club_name': a.club.name,
                'author_name': a.author.full_name or a.author.email.split('@')[0],
                'created_at': a.created_at.isoformat(),
            }
            for a in announcements
        ]
        cache.set(cache_key, data, timeout=60)
        return Response(data)


# ---------------------------------------------------------------------------
# GLOBAL SEARCH
# ---------------------------------------------------------------------------

class GlobalSearchView(APIView):
    """
    GET /api/clubs/search/?q=...
    Groups results into clubs, events, and announcements with debounced performance.
    """
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get(self, request):
        query = request.query_params.get('q', '').strip()
        if not query or len(query) < 2:
            return Response({'clubs': [], 'events': [], 'announcements': []})

        cache_key = f'search_{query.lower()}'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        # 1. Clubs
        clubs = (
            Club.objects
            .filter(is_active=True)
            .filter(Q(name__icontains=query) | Q(description__icontains=query) | Q(category__icontains=query))
            .annotate(member_count_annotated=Count('memberships'))
            .order_by('-member_count_annotated')[:6]
        )
        clubs_data = [
            {
                'id': str(c.id),
                'name': c.name,
                'category': c.category,
                'description': c.description[:120] if c.description else '',
                'member_count': c.member_count_annotated,
                'logo_url': c.logo_url,
            }
            for c in clubs
        ]

        # 2. Events
        events = (
            Event.objects
            .filter(Q(title__icontains=query) | Q(description__icontains=query) | Q(venue__icontains=query) | Q(category__icontains=query))
            .select_related('club')
            .order_by('-event_date')[:6]
        )
        events_data = [
            {
                'id': str(e.id),
                'title': e.title,
                'club_name': e.club.name,
                'event_date': e.event_date.isoformat(),
                'venue': e.venue,
                'status': e.status,
                'category': e.category,
            }
            for e in events
        ]

        # 3. Announcements
        posts = (
            ClubPost.objects
            .filter(post_type='announcement')
            .filter(Q(title__icontains=query) | Q(content__icontains=query))
            .select_related('club')
            .order_by('-created_at')[:4]
        )
        announcements_data = [
            {
                'id': str(p.id),
                'title': p.title,
                'club_name': p.club.name,
                'created_at': p.created_at.isoformat(),
            }
            for p in posts
        ]

        result = {
            'clubs': clubs_data,
            'events': events_data,
            'announcements': announcements_data,
        }
        cache.set(cache_key, result, timeout=60)
        return Response(result)


# ---------------------------------------------------------------------------
# RECOMMENDATIONS
# ---------------------------------------------------------------------------

class RecommendationsView(APIView):
    """
    GET /api/clubs/recommendations/
    Fast heuristic recommendations based on user memberships, attended event categories, and popularity.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        cache_key = f'recommendations_{user.id}'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        # User's joined clubs
        joined_club_ids = list(Membership.objects.filter(user=user).values_list('club_id', flat=True))

        # Categories the user is interested in from registrations or memberships
        attended_categories = list(
            EventRegistration.objects
            .filter(user=user)
            .values_list('event__category', flat=True)
            .distinct()
        )

        # 1. Recommended Clubs (not yet joined)
        rec_clubs_query = (
            Club.objects
            .filter(is_active=True)
            .exclude(id__in=joined_club_ids)
            .annotate(
                member_count_annotated=Count('memberships', distinct=True),
                events_count_annotated=Count('events', distinct=True)
            )
        )

        if attended_categories:
            matching_clubs = list(rec_clubs_query.filter(category__in=attended_categories).order_by('-member_count_annotated')[:4])
        else:
            matching_clubs = []

        if len(matching_clubs) < 4:
            popular_clubs = list(rec_clubs_query.exclude(id__in=[c.id for c in matching_clubs]).order_by('-member_count_annotated')[:(4 - len(matching_clubs))])
            recommended_clubs = matching_clubs + popular_clubs
        else:
            recommended_clubs = matching_clubs

        # 2. Trending / Recommended Events
        now = timezone.now()
        registered_event_ids = list(EventRegistration.objects.filter(user=user).values_list('event_id', flat=True))

        upcoming_events = (
            Event.objects
            .filter(event_date__gte=now, status='upcoming')
            .exclude(id__in=registered_event_ids)
            .select_related('club')
            .annotate(
                approved_registrations_count=Count('registrations', filter=Q(registrations__status='approved'))
            )
            .order_by('-approved_registrations_count', 'event_date')[:6]
        )

        data = {
            'recommended_clubs': ClubSerializer(recommended_clubs, many=True).data,
            'trending_events': EventSerializer(upcoming_events, many=True).data,
        }
        cache.set(cache_key, data, timeout=120)
        return Response(data)


# ---------------------------------------------------------------------------
# ACHIEVEMENTS VIEW
# ---------------------------------------------------------------------------

class AchievementsListView(APIView):
    """
    GET /api/clubs/achievements/ – user's achievements and available badges
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        evaluate_user_achievements(user)

        user_achievements = {
            a.badge_code: a.unlocked_at.isoformat()
            for a in UserAchievement.objects.filter(user=user)
        }

        regs_count = EventRegistration.objects.filter(user=user, status='approved').count()
        clubs_joined = Membership.objects.filter(user=user).count()
        msgs = ClubMessage.objects.filter(sender=user).count()
        comments = ClubPostComment.objects.filter(author=user).count()
        comm_count = msgs + comments

        all_badges = [
            {
                'badge_code': 'first_event',
                'title': 'First Event',
                'description': 'Attended or registered for your first campus event.',
                'icon': 'star',
                'is_unlocked': 'first_event' in user_achievements,
                'unlocked_at': user_achievements.get('first_event'),
                'current': min(regs_count, 1),
                'target': 1,
            },
            {
                'badge_code': 'club_explorer',
                'title': 'Club Explorer',
                'description': 'Became a member of 3 or more campus clubs.',
                'icon': 'compass',
                'is_unlocked': 'club_explorer' in user_achievements,
                'unlocked_at': user_achievements.get('club_explorer'),
                'current': min(clubs_joined, 3),
                'target': 3,
            },
            {
                'badge_code': 'event_enthusiast',
                'title': 'Event Enthusiast',
                'description': 'Registered for 5 or more campus events.',
                'icon': 'trophy',
                'is_unlocked': 'event_enthusiast' in user_achievements,
                'unlocked_at': user_achievements.get('event_enthusiast'),
                'current': min(regs_count, 5),
                'target': 5,
            },
            {
                'badge_code': 'community_voice',
                'title': 'Community Voice',
                'description': 'Actively participated in club discussions.',
                'icon': 'chat',
                'is_unlocked': 'community_voice' in user_achievements,
                'unlocked_at': user_achievements.get('community_voice'),
                'current': min(comm_count, 3),
                'target': 3,
            },
            {
                'badge_code': 'early_bird',
                'title': 'Early Bird',
                'description': 'Registered early for an upcoming event.',
                'icon': 'alarm',
                'is_unlocked': 'early_bird' in user_achievements,
                'unlocked_at': user_achievements.get('early_bird'),
                'current': 1 if 'early_bird' in user_achievements else 0,
                'target': 1,
            },
        ]

        unlocked_count = sum(1 for b in all_badges if b['is_unlocked'])

        return Response({
            'unlocked_count': unlocked_count,
            'total_count': len(all_badges),
            'badges': all_badges,
        })


# ---------------------------------------------------------------------------
# CLUB ANALYTICS / ADMIN VIEW
# ---------------------------------------------------------------------------

class ClubAnalyticsView(APIView):
    """
    GET /api/clubs/<id>/analytics/ – aggregated stats for club head dashboard
    """
    permission_classes = [IsAuthenticated, IsClubHeadOrAdmin]

    def get(self, request, pk):
        try:
            club = Club.objects.get(pk=pk)
        except Club.DoesNotExist:
            return Response({'error': 'Club not found'}, status=404)

        if request.user.role == 'club_head' and club.created_by != request.user:
            return Response({'error': 'Permission denied'}, status=403)

        now = timezone.now()
        total_members = Membership.objects.filter(club=club).count()
        upcoming_events = Event.objects.filter(club=club, status='upcoming', event_date__gte=now).count()
        past_events = Event.objects.filter(club=club, status='completed').count()

        registrations_stats = EventRegistration.objects.filter(event__club=club).aggregate(
            total_registered=Count('id'),
            total_checked_in=Count('id', filter=Q(attendance_status='checked_in')),
        )

        total_registered = registrations_stats['total_registered'] or 0
        total_checked_in = registrations_stats['total_checked_in'] or 0
        attendance_rate = round((total_checked_in / total_registered * 100), 1) if total_registered > 0 else 0

        # Recent activities
        recent_members = [
            {
                'action': 'joined',
                'user_name': m.user.full_name or m.user.email.split('@')[0],
                'timestamp': m.joined_at.isoformat(),
            }
            for m in Membership.objects.filter(club=club).select_related('user').order_by('-joined_at')[:5]
        ]

        return Response({
            'club_id': str(club.id),
            'club_name': club.name,
            'total_members': total_members,
            'upcoming_events_count': upcoming_events,
            'past_events_count': past_events,
            'total_registrations': total_registered,
            'total_checked_in': total_checked_in,
            'attendance_rate': attendance_rate,
            'recent_activity': recent_members,
        })


# ---------------------------------------------------------------------------
# NOTIFICATIONS
# ---------------------------------------------------------------------------

class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        cache_key = f'notifications_{request.user.id}'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

        notifs = (
            Notification.objects
            .filter(user=request.user)
            .select_related('event', 'club', 'post')
            .order_by('-created_at')[:50]
        )
        data = NotificationSerializer(notifs, many=True).data
        cache.set(cache_key, data, timeout=20)
        return Response(data)


class MarkNotificationReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            notification = Notification.objects.get(pk=pk, user=request.user)
            notification.is_read = True
            notification.save(update_fields=['is_read'])
            cache.delete(f'notifications_{request.user.id}')
            return Response({'message': 'Marked as read'})
        except Notification.DoesNotExist:
            return Response({'error': 'Notification not found'}, status=404)


class MarkAllNotificationsReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        cache.delete(f'notifications_{request.user.id}')
        return Response({'message': 'All marked as read'})


# ---------------------------------------------------------------------------
# CLUB CHAT
# ---------------------------------------------------------------------------

class ClubChatView(APIView):
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
        cache_key = f'club_chat_{pk}'
        cached = cache.get(cache_key)
        if cached is not None:
            return Response(cached)

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
        data = ClubMessageSerializer(messages, many=True).data
        cache.set(cache_key, data, timeout=10)
        return Response(data)

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
        evaluate_user_achievements(request.user)
        cache.delete(f'club_chat_{pk}')
        return Response(ClubMessageSerializer(msg).data, status=201)


# ---------------------------------------------------------------------------
# POLLS (Preserved)
# ---------------------------------------------------------------------------

class EventSuggestionPollView(APIView):
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
                'response_count': len(p.suggestions.all()),
                'suggestions': [
                    {'phone': s.submitter_phone, 'suggestion': s.suggestion, 'submitted_at': s.submitted_at}
                    for s in p.suggestions.all()
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
        EventSuggestionPoll.objects.filter(is_active=True).update(
            is_active=False, closed_at=timezone.now()
        )
        poll = EventSuggestionPoll.objects.create(question=question, created_by=request.user)
        return Response({'id': str(poll.id), 'question': poll.question, 'is_active': poll.is_active}, status=201)


class EventSuggestionPollDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        if request.user.role != 'admin':
            return Response({'error': 'Admin access required'}, status=403)
        try:
            poll = EventSuggestionPoll.objects.prefetch_related('suggestions').get(pk=pk)
        except EventSuggestionPoll.DoesNotExist:
            return Response({'error': 'Poll not found'}, status=404)
        data = {
            'id': str(poll.id),
            'question': poll.question,
            'is_active': poll.is_active,
            'created_at': poll.created_at,
            'closed_at': poll.closed_at,
            'suggestions': [
                {'phone': s.submitter_phone, 'suggestion': s.suggestion, 'submitted_at': s.submitted_at}
                for s in poll.suggestions.all()
            ],
        }
        return Response(data)

    def post(self, request, pk):
        if request.user.role != 'admin':
            return Response({'error': 'Admin access required'}, status=403)
        try:
            poll = EventSuggestionPoll.objects.get(pk=pk)
        except EventSuggestionPoll.DoesNotExist:
            return Response({'error': 'Poll not found'}, status=404)
        poll.is_active = False
        poll.closed_at = timezone.now()
        poll.save(update_fields=['is_active', 'closed_at'])
        return Response({'message': 'Poll closed', 'id': str(poll.id)})


class EventSuggestionSubmitView(APIView):
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
