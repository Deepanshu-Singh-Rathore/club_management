import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import 'clubsphere_logo.dart';

class EventTicketDialog extends StatelessWidget {
  final Event event;
  final User? user;
  final String ticketId;
  final String attendanceStatus;

  const EventTicketDialog({
    super.key,
    required this.event,
    this.user,
    required this.ticketId,
    this.attendanceStatus = 'registered',
  });

  static Future<void> show(
    BuildContext context, {
    required Event event,
    User? user,
    required String ticketId,
    String attendanceStatus = 'registered',
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => EventTicketDialog(
        event: event,
        user: user,
        ticketId: ticketId,
        attendanceStatus: attendanceStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCheckedIn = attendanceStatus.toLowerCase() == 'checked_in';
    final formattedDate = DateFormat('EEEE, MMM d, y').format(event.eventDate.toLocal());
    final formattedTime = DateFormat('h:mm a').format(event.eventDate.toLocal());

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ClubSphereLogo(
                        size: 28,
                        showText: true,
                        isLight: true,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCheckedIn ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCheckedIn ? Icons.check_circle_rounded : Icons.confirmation_number_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isCheckedIn ? 'CHECKED IN' : 'CONFIRMED PASS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Event & Student Details
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Organized by ${event.clubName}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Metadata Grid
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _infoBlock('DATE & TIME', '$formattedDate\n$formattedTime', Icons.calendar_today_rounded),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _infoBlock('VENUE', event.venue, Icons.location_on_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _infoBlock('ATTENDEE', user?.displayName ?? 'Student', Icons.person_rounded),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _infoBlock('ROLL / ID', user?.rollNumber ?? user?.email ?? 'Registered', Icons.badge_rounded),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Ticket Divider with Cutout effect
                      Row(
                        children: List.generate(
                          30,
                          (i) => Expanded(
                            child: Container(
                              height: 1.5,
                              color: i.isEven ? AppTheme.border : Colors.transparent,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // QR Code & Ticket ID
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: QrImageView(
                                data: ticketId.isNotEmpty ? ticketId : event.id,
                                version: QrVersions.auto,
                                size: 140,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: AppTheme.textPrimary,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ticketId.isNotEmpty ? ticketId : 'TICKET ID PENDING',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Present this QR at the venue entrance for attendance',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Close Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close Ticket', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
