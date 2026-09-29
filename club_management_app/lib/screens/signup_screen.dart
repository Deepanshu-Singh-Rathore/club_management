import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/clubsphere_logo.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/entrance_animation.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _rollCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _sanitizePhone(String input) {
    var cleaned = input.replaceAll(RegExp(r'[\s\-()]'), '').trim();
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    } else if (!cleaned.startsWith('+') && cleaned.length == 10) {
      cleaned = '+91$cleaned';
    } else if (!cleaned.startsWith('+') && cleaned.isNotEmpty) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().register(
            fullName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            rollNumber: _rollCtrl.text.trim(),
            phoneNumber: _sanitizePhone(_phoneCtrl.text),
          );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on ApiException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Network error. Check connection or backend server.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 880;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Branding Banner
        Expanded(
          flex: 5,
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ClubSphereLogo(
                      size: 44,
                      showText: true,
                      isLight: true,
                    ),
                    const Spacer(),
                    const EntranceAnimation(
                      child: Text(
                        'Unlock Your College Experience.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Join student clubs, build technical & leadership skills, attend workshops, and make lasting connections.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded,
                              color: Color(0xFFFBBF24), size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Earn official certificates and credentials validated by club heads and college administration.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right Registration Form
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: EntranceAnimation(
                  child: _buildFormCard(isDesktop: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: EntranceAnimation(
              child: Column(
                children: [
                  const ClubSphereLogo(
                    size: 52,
                    showText: true,
                    subtitle: 'Student Registration',
                  ),
                  const SizedBox(height: 20),
                  _buildFormCard(isDesktop: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 36 : 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign up to join clubs and register for events',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),

            CustomTextField(
              controller: _nameCtrl,
              labelText: 'Full Name',
              hintText: 'John Doe',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v != null && v.trim().isNotEmpty ? null : 'Name is required',
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: _emailCtrl,
              labelText: 'College Email',
              hintText: 'student@college.edu',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: _phoneCtrl,
              labelText: 'WhatsApp Phone Number',
              hintText: '+91 9876543210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
                final cleaned = _sanitizePhone(v);
                if (!RegExp(r'^\+[0-9]{7,15}$').hasMatch(cleaned)) {
                  return 'Enter a valid phone number (e.g. +91 9876543210)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: _rollCtrl,
              labelText: 'Roll Number (Optional)',
              hintText: 'e.g. 21BCE1024',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 14),

            CustomTextField(
              controller: _passCtrl,
              labelText: 'Password',
              hintText: 'At least 6 characters',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: 'Create Account',
              isLoading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Already have an account?',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
