import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/club.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

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
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
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
      _showSnack('Please select a club', AppTheme.warning);
      return;
    }
    if (_eventDate == null) {
      _showSnack('Please select an event date and time', AppTheme.warning);
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
        _showSnack('Event created successfully!', AppTheme.success);
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) _showSnack(e.message, AppTheme.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
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
        title: const Text('Create New Event'),
      ),
      body: _loadingClubs
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Event Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Fill in the information to publish your club event.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title
                          CustomTextField(
                            controller: _titleCtrl,
                            labelText: 'Event Title',
                            hintText: 'e.g. Annual Hackathon 2026',
                            icon: Icons.title_rounded,
                            validator: (v) =>
                                v != null && v.trim().isNotEmpty
                                    ? null
                                    : 'Event title is required',
                          ),
                          const SizedBox(height: 16),

                          // Description
                          CustomTextField(
                            controller: _descCtrl,
                            labelText: 'Description',
                            hintText: 'Describe schedule, requirements, venue…',
                            icon: Icons.description_outlined,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 16),

                          // Club picker
                          DropdownButtonFormField<String>(
                            initialValue: _selectedClubId,
                            decoration: const InputDecoration(
                              labelText: 'Host Club',
                              prefixIcon: Icon(Icons.groups_rounded),
                            ),
                            items: _clubs
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedClubId = v),
                            validator: (v) =>
                                v != null ? null : 'Please select a host club',
                          ),
                          const SizedBox(height: 16),

                          // Date picker
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Event Date & Time',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _eventDate == null
                                        ? 'Select date & start time'
                                        : DateFormat('EEE, dd MMM yyyy • hh:mm a')
                                            .format(_eventDate!),
                                    style: TextStyle(
                                      color: _eventDate == null
                                          ? AppTheme.textMuted
                                          : AppTheme.textPrimary,
                                      fontWeight: _eventDate == null
                                          ? FontWeight.normal
                                          : FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppTheme.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Capacity
                          CustomTextField(
                            controller: _capCtrl,
                            labelText: 'Capacity (0 = Unlimited)',
                            hintText: '0',
                            icon: Icons.people_outline_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          // Image URL
                          CustomTextField(
                            controller: _imgCtrl,
                            labelText: 'Cover Image URL (Optional)',
                            hintText: 'https://images.unsplash.com/…',
                            icon: Icons.image_outlined,
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 28),

                          // Submit
                          CustomButton(
                            text: 'Publish Event',
                            isLoading: _loading,
                            icon: Icons.publish_rounded,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
