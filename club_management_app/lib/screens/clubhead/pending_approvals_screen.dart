import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/event_registration.dart';
import '../../services/api_service.dart';

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
      _showSnack('Approved ✓', Colors.green);
      _load();
    } on ApiException catch (e) {
      _showSnack(e.message, Colors.red);
    }
  }

  Future<void> _reject(EventRegistration reg) async {
    try {
      await ApiService.rejectRegistration(widget.event.id, reg.id);
      _showSnack('Rejected', Colors.orange);
      _load();
    } on ApiException catch (e) {
      _showSnack(e.message, Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pending – ${widget.event.title}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _regs.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green),
                          SizedBox(height: 12),
                          Text('No pending registrations',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _regs.length,
                      itemBuilder: (_, i) {
                        final reg = _regs[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundColor:
                                    const Color(0xFF0D47A1).withOpacity(0.1),
                                child: Text(
                                  reg.user.displayName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Color(0xFF0D47A1),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(reg.user.displayName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(reg.user.email,
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                      if (reg.user.rollNumber != null)
                                        Text(reg.user.rollNumber!,
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                    ]),
                              ),
                              Column(children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  tooltip: 'Approve',
                                  onPressed: () => _approve(reg),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  tooltip: 'Reject',
                                  onPressed: () => _reject(reg),
                                ),
                              ]),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
