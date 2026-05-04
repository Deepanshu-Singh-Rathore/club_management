import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/club.dart';
import '../../services/api_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  final _capCtrl = TextEditingController(text: '0');

  List<Club> _clubs = [];
  String? _selectedClubId;
  DateTime? _eventDate;
  bool _loading = false;
  bool _loadingClubs = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _imgCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    try {
      final raw = await ApiService.getClubs();
      if (mounted) {
        setState(() {
          _clubs = raw.map((e) => Club.fromJson(e as Map<String, dynamic>)).toList();
          _loadingClubs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClubs = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (mounted) {
        setState(() {
          _eventDate = time != null
              ? DateTime(picked.year, picked.month, picked.day,
                  time.hour, time.minute)
              : picked;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClubId == null) {
      _showSnack('Please select a club', Colors.orange);
      return;
    }
    if (_eventDate == null) {
      _showSnack('Please pick an event date', Colors.orange);
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiService.createEvent(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        eventDate: _eventDate!.toIso8601String(),
        clubId: _selectedClubId!,
        capacity: int.tryParse(_capCtrl.text) ?? 0,
        imageUrl: _imgCtrl.text.trim().isEmpty ? null : _imgCtrl.text.trim(),
      );
      if (mounted) {
        _showSnack('Event created!', Colors.green);
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: _loadingClubs
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Event Title',
                          prefixIcon: Icon(Icons.title)),
                      validator: (v) =>
                          v != null && v.isNotEmpty ? null : 'Required',
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                          alignLabelWithHint: true),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),

                    // Club picker
                    DropdownButtonFormField<String>(
                      value: _selectedClubId,
                      decoration: const InputDecoration(
                          labelText: 'Club',
                          prefixIcon: Icon(Icons.group)),
                      items: _clubs
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedClubId = v),
                      validator: (v) => v != null ? null : 'Select a club',
                    ),
                    const SizedBox(height: 14),

                    // Date picker
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Event Date & Time',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _eventDate == null
                              ? 'Tap to pick date'
                              : DateFormat('dd MMM yyyy, hh:mm a')
                                  .format(_eventDate!),
                          style: TextStyle(
                              color: _eventDate == null
                                  ? Colors.grey
                                  : Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Capacity
                    TextFormField(
                      controller: _capCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Capacity (0 = unlimited)',
                          prefixIcon: Icon(Icons.people)),
                    ),
                    const SizedBox(height: 14),

                    // Image URL
                    TextFormField(
                      controller: _imgCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                          labelText: 'Image URL (optional)',
                          prefixIcon: Icon(Icons.image)),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check),
                      label: Text(_loading ? 'Creating…' : 'Create Event'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
