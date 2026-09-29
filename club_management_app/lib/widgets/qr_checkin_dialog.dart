import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class QrCheckinDialog extends StatefulWidget {
  final Event event;

  const QrCheckinDialog({super.key, required this.event});

  static Future<void> show(BuildContext context, {required Event event}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => QrCheckinDialog(event: event),
    );
  }

  @override
  State<QrCheckinDialog> createState() => _QrCheckinDialogState();
}

class _QrCheckinDialogState extends State<QrCheckinDialog> {
  final _ticketController = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  String? _feedbackMessage;
  bool _isSuccess = true;
  int _totalRegistered = 0;
  int _checkedInCount = 0;
  List<dynamic> _registrations = [];

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrations() async {
    try {
      final data = await ApiService.getEventRegistrations(widget.event.id);
      if (mounted) {
        setState(() {
          _totalRegistered = data['total_registered'] ?? 0;
          _checkedInCount = data['checked_in_count'] ?? 0;
          _registrations = data['registrations'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitCheckin([String? explicitTicketId]) async {
    final ticketId = (explicitTicketId ?? _ticketController.text).trim().toUpperCase();
    if (ticketId.isEmpty) return;

    setState(() {
      _submitting = true;
      _feedbackMessage = null;
    });

    try {
      final res = await ApiService.checkInAttendee(widget.event.id, ticketId: ticketId);
      if (mounted) {
        final already = res['already_checked_in'] == true;
        setState(() {
          _feedbackMessage = already ? 'Already checked in' : '✓ Attendance marked';
          _isSuccess = !already;
          _submitting = false;
        });
        _ticketController.clear();
        _loadRegistrations();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _feedbackMessage = (e.statusCode == 404 || e.message.toLowerCase().contains('ticket') || e.message.toLowerCase().contains('not found'))
              ? 'Invalid ticket'
              : e.message;
          _isSuccess = false;
          _submitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _feedbackMessage = 'Invalid ticket';
          _isSuccess = false;
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 650;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? (screenWidth - 600) / 2 : 16,
        vertical: 30,
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Event Check-in & Attendance',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          widget.event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Attendance Stat Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppTheme.surfaceVariant,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Registered', '$_totalRegistered', Icons.how_to_reg_rounded),
                  Container(width: 1, height: 28, color: AppTheme.border),
                  _statItem('Checked In', '$_checkedInCount', Icons.check_circle_rounded, color: AppTheme.success),
                  Container(width: 1, height: 28, color: AppTheme.border),
                  _statItem(
                    'Attendance',
                    _totalRegistered > 0 ? '${(_checkedInCount / _totalRegistered * 100).round()}%' : '0%',
                    Icons.pie_chart_outline_rounded,
                  ),
                ],
              ),
            ),

            // Ticket Scanner / Input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ticketController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Enter Ticket ID (e.g. CS-9A224B)',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onSubmitted: (val) => _submitCheckin(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _submitting ? null : () => _submitCheckin(),
                    icon: _submitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Check In'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            // Feedback banner
            if (_feedbackMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSuccess ? AppTheme.successBg : AppTheme.errorBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isSuccess ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      color: _isSuccess ? AppTheme.success : AppTheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _feedbackMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isSuccess ? const Color(0xFF065F46) : AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Attendees List Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Attendees List',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                ),
              ),
            ),

            // List of attendees
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                  : _registrations.isEmpty
                      ? const Center(
                          child: Text(
                            'No registered attendees yet.',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          itemCount: _registrations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final r = _registrations[i];
                            final user = r['user'] ?? {};
                            final isChecked = r['attendance_status'] == 'checked_in';
                            final ticketId = r['ticket_id'] ?? '';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isChecked ? AppTheme.successBg.withValues(alpha: 0.5) : AppTheme.surfaceVariant.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isChecked ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isChecked ? AppTheme.successBg : AppTheme.primaryTint,
                                    child: Icon(
                                      isChecked ? Icons.check_rounded : Icons.person_outline_rounded,
                                      size: 16,
                                      color: isChecked ? AppTheme.success : AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['full_name'] ?? user['email'] ?? 'Attendee',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                        Text(
                                          'ID: $ticketId • Roll: ${user['roll_number'] ?? 'N/A'}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isChecked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Present ✓',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.success,
                                        ),
                                      ),
                                    )
                                  else
                                    TextButton(
                                      onPressed: () => _submitCheckin(ticketId),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Check In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color ?? AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
