import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String role;
  const RegistrationScreen({super.key, this.role = 'student'});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  String selectedClub = 'Coding Club';
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  final List<String> _clubNames = [
    'Coding Club',
    'Dance Club',
    'Music Club',
    'Sports Club'
  ];
  final Map<String, String> _clubIds = {};

  @override
  void initState() {
    super.initState();
    _fetchClubs();
  }

  Future<void> _fetchClubs() async {
    try {
      final clubs = await ApiService.getClubs();
      if (clubs.isNotEmpty) {
        setState(() {
          _clubNames.clear();
          _clubIds.clear();
          for (final c in clubs) {
            _clubNames.add(c['name'] as String);
            _clubIds[c['name'] as String] = c['id'] as String;
          }
          if (_clubNames.isNotEmpty) selectedClub = _clubNames.first;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final roll = _rollCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.register(
        fullName: name,
        email: email,
        password: pass,
        rollNumber: roll,
      );

      if (data.containsKey('access')) {
        await ApiService.saveTokens(data['access'] as String, data['refresh'] as String);

        final clubId = _clubIds[selectedClub];
        if (clubId != null) {
          await ApiService.joinClub(clubId);
        }

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        final errors =
            data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errors), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Club Registration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join Your Favorite Club ✨',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fill in your details to get started.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        hintText: 'Full Name',
                        labelText: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        controller: _nameCtrl,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        hintText: 'Roll Number (Optional)',
                        labelText: 'Roll Number',
                        icon: Icons.badge_outlined,
                        controller: _rollCtrl,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        hintText: 'College Email',
                        labelText: 'Email',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        hintText: 'Password',
                        labelText: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        controller: _passCtrl,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedClub,
                        decoration: const InputDecoration(
                          labelText: 'Select Club to Join',
                          prefixIcon: Icon(Icons.group_outlined),
                        ),
                        items: _clubNames.map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => selectedClub = v);
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Register Now',
                        isLoading: _isLoading,
                        onPressed: _register,
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
}
