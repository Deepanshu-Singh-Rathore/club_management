import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../theme/app_theme.dart';

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onManage;
  final bool isRegistered;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onManage,
    this.isRegistered = false,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final dateFormatted = DateFormat('EEE, MMM d').format(e.eventDate.toLocal());
    final timeFormatted = DateFormat('h:mm a').format(e.eventDate.toLocal());

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? AppTheme.primaryLight.withValues(alpha: 0.5) : AppTheme.border,
            width: 1,
          ),
          boxShadow: _isHovered ? AppTheme.cardShadow : AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Banner / Category header
                Stack(
                  children: [
                    Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: _categoryGradient(e.category),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -15,
                            bottom: -15,
                            child: Icon(
                              _categoryIcon(e.category),
                              size: 110,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          e.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    // Status Badge (Section 9: REGISTERED ✓ / FULL / UPCOMING)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: widget.isRegistered
                              ? const Color(0xFF10B981)
                              : (e.isCancelled
                                  ? AppTheme.error
                                  : (e.isFull
                                      ? const Color(0xFFD97706)
                                      : (e.isCompleted
                                          ? AppTheme.textSecondary
                                          : Colors.black.withValues(alpha: 0.4)))),
                          borderRadius: BorderRadius.circular(10),
                          border: widget.isRegistered || e.isCancelled || e.isFull || e.isCompleted
                              ? null
                              : Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isRegistered) ...[
                              const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              widget.isRegistered
                                  ? 'REGISTERED ✓'
                                  : (e.isCancelled
                                      ? 'CANCELLED'
                                      : (e.isFull
                                          ? 'FULL'
                                          : (e.isCompleted ? 'COMPLETED' : 'UPCOMING'))),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Card Details
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Club Name
                      Row(
                        children: [
                          const Icon(Icons.groups_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              e.clubName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Date & Time
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$dateFormatted • $timeFormatted',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Location / Venue
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.venue.isNotEmpty ? e.venue : 'Campus Venue',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.borderSubtle),
                      const SizedBox(height: 10),

                      // Footer: Registration count & Button (Section 9: [View Event])
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 14,
                                color: e.isFull ? AppTheme.warning : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                e.isFull
                                    ? 'Full (${e.registeredCount})'
                                    : '${e.registeredCount}${e.capacity > 0 ? '/${e.capacity}' : ''} registered',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: e.isFull ? AppTheme.warning : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.onManage != null ? 'Manage' : 'View Event',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _categoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)]);
      case 'cultural':
        return const LinearGradient(colors: [Color(0xFF831843), Color(0xFFDB2777)]);
      case 'sports':
        return const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF059669)]);
      case 'photography':
        return const LinearGradient(colors: [Color(0xFF374151), Color(0xFF4B5563)]);
      case 'music':
        return const LinearGradient(colors: [Color(0xFF581C87), Color(0xFF7C3AED)]);
      case 'literature':
        return const LinearGradient(colors: [Color(0xFF78350F), Color(0xFFD97706)]);
      case 'entrepreneurship':
        return const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0284C7)]);
      default:
        return const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF2563EB)]);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Icons.terminal_rounded;
      case 'cultural':
        return Icons.theater_comedy_rounded;
      case 'sports':
        return Icons.sports_basketball_rounded;
      case 'photography':
        return Icons.camera_alt_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'literature':
        return Icons.auto_stories_rounded;
      case 'entrepreneurship':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.event_rounded;
    }
  }
}
