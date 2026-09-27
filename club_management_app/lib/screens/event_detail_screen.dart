import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/entrance_animation.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? event;
  bool loading = true;
  bool applying = false;
  String? appliedStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final eventId = ModalRoute.of(context)!.settings.arguments;

    if (event == null && eventId != null) {
      _loadEvent(eventId.toString());
    }
  }

  Future<void> _loadEvent(String id) async {
    try {
      final data = await ApiService.getEvent(id);
      final e = Event.fromJson(data);

      if (mounted) {
        setState(() {
          event = e;
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
          appliedStatus = (match as Map)['status'];
        });
      }
    } catch (_) {}
  }

  Future<void> _apply() async {
    if (event == null) return;

    setState(() => applying = true);

    try {
      await ApiService.applyForEvent(event!.id);

      if (mounted) {
        setState(() => appliedStatus = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration submitted! Awaiting club approval.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error submitting registration. Please try again.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    if (event == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Event Details')),
        body: const Center(
          child: Text(
            'Event not found or has been removed.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    final e = event!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 860;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          e.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 20,
            ),
            children: [
              EntranceAnimation(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column (65%): Banner, Title, Details, Description
                          Expanded(
                            flex: 65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCoverBanner(e, isDesktop),
                                const SizedBox(height: 20),
                                _buildMainInfo(e),
                                const SizedBox(height: 20),
                                _buildDescriptionCard(e),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),

                          // Right Column (35%): Registration Action Card (No awkward bottomsheet!)
                          Expanded(
                            flex: 35,
                            child: Column(
                              children: [
                                _buildRegistrationCard(e, auth),
                                const SizedBox(height: 16),
                                _buildOrganizerCard(e),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCoverBanner(e, isDesktop),
                          const SizedBox(height: 16),
                          _buildMainInfo(e),
                          const SizedBox(height: 16),
                          _buildRegistrationCard(e, auth),
                          const SizedBox(height: 16),
                          _buildOrganizerCard(e),
                          const SizedBox(height: 16),
                          _buildDescriptionCard(e),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverBanner(Event e, bool isDesktop) {
    if (e.imageUrl != null && e.imageUrl!.isNotEmpty) {
      return Container(
        height: isDesktop ? 280 : 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              e.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallbackCover(e, isDesktop),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: _statusChip(e.status),
            ),
          ],
        ),
      );
    }
    return _fallbackCover(e, isDesktop);
  }

  Widget _fallbackCover(Event e, bool isDesktop) {
    return Container(
      height: isDesktop ? 180 : 130,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.cardHeaderGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e.clubName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _statusChip(e.status),
            ],
          ),
          Text(
            e.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainInfo(Event e) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            e.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _detailBlock(
                icon: Icons.calendar_month_rounded,
                title: 'Date',
                value: DateFormat('EEE, dd MMM yyyy').format(e.eventDate),
                color: AppTheme.primary,
              ),
              const SizedBox(width: 20),
              _detailBlock(
                icon: Icons.access_time_rounded,
                title: 'Time',
                value: DateFormat('hh:mm a').format(e.eventDate),
                color: AppTheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailBlock({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(Event e, AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Registration',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Capacity Bar
          if (e.capacity > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seat Availability',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${e.registeredCount}/${e.capacity} seats',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (e.registeredCount / e.capacity).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppTheme.surfaceVariant,
                color: e.isFull ? AppTheme.error : AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.all_inclusive_rounded, size: 16, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Unlimited student capacity',
                    style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Registration Action Button / Status
          if (auth.isStudent) ...[
            if (appliedStatus != null)
              _buildAppliedBadge()
            else if (e.isFull)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Text(
                    'This event is at full capacity',
                    style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              CustomButton(
                text: 'Register for Event',
                isLoading: applying,
                icon: Icons.how_to_reg_rounded,
                onPressed: _apply,
              ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  auth.isAdmin ? 'Viewing as Administrator' : 'Viewing as Club Head',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppliedBadge() {
    final isApproved = appliedStatus == 'approved';
    final isPending = appliedStatus == 'pending';
    final color = isApproved
        ? AppTheme.success
        : isPending
            ? AppTheme.warning
            : AppTheme.error;
    final bg = isApproved
        ? AppTheme.successBg
        : isPending
            ? AppTheme.warningBg
            : AppTheme.errorBg;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isApproved
                ? Icons.check_circle_rounded
                : isPending
                    ? Icons.hourglass_top_rounded
                    : Icons.cancel_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isApproved
                ? 'Registration Confirmed ✓'
                : isPending
                    ? 'Registration Pending Review'
                    : 'Application ${appliedStatus!}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerCard(Event e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                e.clubName.isNotEmpty ? e.clubName[0].toUpperCase() : 'C',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Host Organization', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Text(
                  e.clubName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Event e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Event',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            e.description.isEmpty
                ? 'No description provided for this campus event.'
                : e.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final c = AppTheme.statusColor(status);
    final bg = AppTheme.statusBgColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
