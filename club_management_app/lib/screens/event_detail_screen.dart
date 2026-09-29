import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entrance_animation.dart';
import '../widgets/event_ticket_dialog.dart';
import '../widgets/qr_checkin_dialog.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state.dart';

class EventDetailScreen extends StatefulWidget {
  final String? eventId;
  const EventDetailScreen({super.key, this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? event;
  bool loading = true;
  bool applying = false;
  bool cancelling = false;
  String? appliedStatus;
  String? ticketId;
  String attendanceStatus = 'registered';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (event == null) {
      final id = widget.eventId ?? ModalRoute.of(context)?.settings.arguments as String?;
      if (id != null) {
        _loadEvent(id);
      }
    }
  }

  Future<void> _loadEvent(String id) async {
    setState(() => loading = true);
    try {
      final data = await ApiService.getEvent(id);
      if (mounted) {
        setState(() {
          event = Event.fromJson(data);
          loading = false;
        });
        _checkStatus();
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _checkStatus() async {
    if (event == null) return;
    try {
      final regs = await ApiService.getMyEvents();
      final match = regs.firstWhere(
        (r) => (r as Map)['event'] != null && (r['event']['id'] == event!.id),
        orElse: () => null,
      );

      if (mounted && match != null) {
        setState(() {
          final m = match as Map<String, dynamic>;
          appliedStatus = m['status'];
          ticketId = m['ticket_id'];
          attendanceStatus = m['attendance_status'] ?? 'registered';
        });
      }
    } catch (_) {}
  }

  Future<void> _apply() async {
    if (event == null) return;
    setState(() => applying = true);
    try {
      final res = await ApiService.applyForEvent(event!.id);
      if (mounted) {
        setState(() {
          appliedStatus = res['status'] ?? 'approved';
          ticketId = res['ticket_id'];
          attendanceStatus = res['attendance_status'] ?? 'registered';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Successfully registered! Digital ticket generated.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        _loadEvent(event!.id);

        if (ticketId != null && mounted) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          EventTicketDialog.show(
            context,
            event: event!,
            user: auth.user,
            ticketId: ticketId!,
            attendanceStatus: attendanceStatus,
          );
        }
      }
    } catch (err) {
      if (mounted) {
        final message = err.toString().contains('full')
            ? 'Registration is currently full.'
            : 'Your registration could not be completed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => applying = false);
    }
  }

  Future<void> _cancelRegistration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Registration', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to cancel your event registration? Your ticket pass will be revoked.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Ticket')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Registration'),
          ),
        ],
      ),
    );

    if (confirmed == true && event != null) {
      setState(() => cancelling = true);
      try {
        await ApiService.cancelEventRegistration(event!.id);
        if (mounted) {
          setState(() {
            appliedStatus = null;
            ticketId = null;
            cancelling = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration cancelled successfully'), backgroundColor: AppTheme.warning),
          );
          _loadEvent(event!.id);
        }
      } catch (_) {
        if (mounted) setState(() => cancelling = false);
      }
    }
  }

  void _showCalendarDialog() {
    if (event == null) return;
    final date = DateFormat('EEEE, MMM d, y').format(event!.eventDate.toLocal());
    final time = DateFormat('h:mm a').format(event!.eventDate.toLocal());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Add to Calendar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event!.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Text('Date: $date at $time', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            Text('Venue: ${event!.venue}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            const Text(
              'Copy details to import into Google Calendar or Apple Calendar.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Event: ${event!.title}\nDate: $date $time\nVenue: ${event!.venue}\nOrganized by: ${event!.clubName}',
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Event details copied to clipboard!'), backgroundColor: AppTheme.success),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Details'),
          ),
        ],
      ),
    );
  }

  void _shareEvent() {
    if (event == null) return;
    Clipboard.setData(ClipboardData(
      text: 'Check out "${event!.title}" hosted by ${event!.clubName} on ClubSphere! Date: ${DateFormat('MMM d, y').format(event!.eventDate.toLocal())} at ${event!.venue}.',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event invite link copied to clipboard!'), backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Event Details')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 220, borderRadius: 20),
                        SizedBox(height: 20),
                        SkeletonBox(height: 160, borderRadius: 16),
                      ],
                    ),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: SkeletonBox(height: 380, borderRadius: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (event == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Event Details')),
        body: const EmptyState(
          icon: Icons.event_busy_rounded,
          title: 'Event Not Found',
          subtitle: 'The event you are looking for does not exist or may have been removed.',
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    final e = event!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;
    final isRegistered = appliedStatus == 'approved' || appliedStatus == 'pending';
    final canManage = auth.isAdmin || auth.isClubHead;

    final formattedDate = DateFormat('EEEE, MMMM d, y').format(e.eventDate.toLocal());
    final formattedTime = DateFormat('h:mm a').format(e.eventDate.toLocal());

    // Left Column: Banner, Description, Schedule, Organizer
    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large Event Banner
        EntranceAnimation(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isDesktop ? 28 : 20),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        e.category,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: e.isCancelled ? AppTheme.error : (e.isCompleted ? AppTheme.textMuted : const Color(0xFF10B981)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        e.status.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  e.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF93C5FD)),
                    const SizedBox(width: 6),
                    Text(
                      'Organized by ${e.clubName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // About the Event Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('About the Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              Text(
                e.description.isNotEmpty ? e.description : 'No detailed description provided for this campus event.',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Event Schedule Card
        if (e.schedule.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Event Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  e.schedule,
                  style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary, height: 1.55),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // About the Organizer Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    e.clubName.isNotEmpty ? e.clubName[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.clubName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    const Text('Official Campus Organization', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // Right Column: Information card & Primary CTA (Section 7)
    final rightColumn = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Information',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),

          _infoRow(Icons.calendar_today_rounded, 'Date', formattedDate),
          const SizedBox(height: 14),
          _infoRow(Icons.access_time_rounded, 'Time', formattedTime),
          const SizedBox(height: 14),
          _infoRow(Icons.location_on_rounded, 'Location', e.venue.isNotEmpty ? e.venue : 'Campus Hall'),
          const SizedBox(height: 14),
          _infoRow(Icons.groups_rounded, 'Organiser', e.clubName),
          const SizedBox(height: 14),
          _infoRow(Icons.people_outline_rounded, 'Capacity', e.capacity > 0 ? '${e.capacity} Seats' : 'Unlimited'),
          const SizedBox(height: 14),
          _infoRow(Icons.how_to_reg_rounded, 'Registrations', '${e.registeredCount} Registered'),

          const Divider(height: 28),

          // Primary CTA Block (Section 7 requirement)
          if (!isRegistered) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: e.isFull || e.isCancelled || applying ? null : _apply,
                icon: applying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  e.isCancelled
                      ? 'Event Cancelled'
                      : (e.isFull ? 'Registration Full' : 'REGISTER NOW'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.successBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.success),
                  SizedBox(width: 8),
                  Text(
                    'REGISTERED ✓',
                    style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.success, fontSize: 13, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  EventTicketDialog.show(
                    context,
                    event: e,
                    user: auth.user,
                    ticketId: ticketId ?? '',
                    attendanceStatus: attendanceStatus,
                  );
                },
                icon: const Icon(Icons.qr_code_rounded, size: 18),
                label: const Text('VIEW TICKET', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: cancelling ? null : _cancelRegistration,
                child: const Text('Cancel Registration', style: TextStyle(color: AppTheme.error, fontSize: 12.5)),
              ),
            ),
          ],

          if (canManage) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => QrCheckinDialog.show(context, event: e),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Verify Attendance (QR Tool)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showCalendarDialog,
                  icon: const Icon(Icons.calendar_today_outlined, size: 15),
                  label: const Text('Calendar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareEvent,
                  icon: const Icon(Icons.share_outlined, size: 15),
                  label: const Text('Share', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), tooltip: 'Share', onPressed: _shareEvent),
          IconButton(icon: const Icon(Icons.calendar_today_outlined), tooltip: 'Add to Calendar', onPressed: _showCalendarDialog),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 24),
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: leftColumn),
                    const SizedBox(width: 24),
                    SizedBox(width: 360, child: rightColumn),
                  ],
                )
              else ...[
                leftColumn,
                const SizedBox(height: 20),
                rightColumn,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
