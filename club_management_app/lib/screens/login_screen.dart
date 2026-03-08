import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'registration_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isStudent = true;
  bool _isLoading = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = await ApiService.login(email: email, password: password);
      if (data.containsKey('access')) {
        await ApiService.saveTokens(data['access'], data['refresh']);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        final msg =
            data['error'] ?? data['detail'] ?? data.values.first.toString();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.toString())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7B61FF), Color(0xFFF557FA)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.cloud_circle, size: 90, color: Colors.white),
            const Text(
              "ClubSphere",
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFFFBFCF6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  CustomTextField(
                    hintText: "Email",
                    icon: Icons.email_outlined,
                    controller: _emailCtrl,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    hintText: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordCtrl,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio(
                        value: true,
                        groupValue: isStudent,
                        activeColor: const Color(0xFF4A6CF7),
                        onChanged: (v) => setState(() => isStudent = v as bool),
                      ),
                      const Text("Student",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 30),
                      Radio(
                        value: false,
                        groupValue: isStudent,
                        activeColor: const Color(0xFF4A6CF7),
                        onChanged: (v) => setState(() => isStudent = v as bool),
                      ),
                      const Text("Admin",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFF4A6CF7))
                      : CustomButton(text: "Login", onPressed: _login),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RegistrationScreen(
                              role: isStudent ? 'student' : 'admin')),
                    ),
                    child: const Text(
                      "Don't have an account? Signup",
                      style: TextStyle(
                          color: Color(0xFF4A6CF7),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
