import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/event_registration.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class PendingApprovalsScreen extends StatefulWidget {
  final Event event;
  const PendingApprovalsScreen({super.key, required this.event});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  List<EventRegistration> _regs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getPendingRegistrations(widget.event.id);
      if (mounted) {
        setState(() {
          _regs = raw
              .map((e) => EventRegistration.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(EventRegistration reg) async {
    try {
      await ApiService.approveRegistration(widget.event.id, reg.id);
      _showSnack('Registration approved ✓', AppTheme.success);
      _load();
    } on ApiException catch (e) {
      _showSnack(e.message, AppTheme.error);
    }
  }

  Future<void> _reject(EventRegistration reg) async {
    try {
      await ApiService.rejectRegistration(widget.event.id, reg.id);
      _showSnack('Registration rejected', AppTheme.warning);
      _load();
    } on ApiException catch (e) {
      _showSnack(e.message, AppTheme.error);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Approvals: ${widget.event.title}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  child: _regs.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Icon(
                              Icons.task_alt_rounded,
                              size: 56,
                              color: AppTheme.success,
                            ),
                            SizedBox(height: 14),
                            Center(
                              child: Text(
                                'All Caught Up!',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Center(
                              child: Text(
                                'No pending event registration requests right now.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          itemCount: _regs.length,
                          itemBuilder: (_, i) {
                            final reg = _regs[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryTint,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          reg.user.displayName.isNotEmpty
                                              ? reg.user.displayName[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            reg.user.displayName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            reg.user.email,
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (reg.user.rollNumber != null &&
                                              reg.user.rollNumber!.isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                'Roll: ${reg.user.rollNumber!}',
                                                style: const TextStyle(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppTheme.success,
                                            size: 28,
                                          ),
                                          tooltip: 'Approve',
                                          onPressed: () => _approve(reg),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cancel_rounded,
                                            color: AppTheme.error,
                                            size: 28,
                                          ),
                                          tooltip: 'Reject',
                                          onPressed: () => _reject(reg),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }
}
