import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  int _userType = 0; // 0 for Student, 1 for Admin

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Colors.white],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  // 2. FIXED LOGO SECTION (Simplified)
                  Center(
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1), // Halka sa glow
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(75),
                        child: Image.asset(
                          'assets/images/logo.png', // Check karein ye path sahi hai
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Agar image load nahi hui to icon dikhega
                            return const Icon(
                              Icons.shield,
                              size: 80,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "ClubSphere",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 3. Login Card
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 25),

                        _buildField(
                          _emailController,
                          Icons.alternate_email_rounded,
                          "Email Address",
                        ),
                        const SizedBox(height: 15),
                        _buildField(
                          _passController,
                          Icons.lock_outline_rounded,
                          "Password",
                          isPass: true,
                        ),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _roleOption("Student", 0),
                            const SizedBox(width: 20),
                            _roleOption("Admin", 1),
                          ],
                        ),

                        const SizedBox(height: 25),

                        GestureDetector(
                          onTap: _performLogin,
                          child: Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/signup'),
                          child: const Text(
                            "New here? Create Account",
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _roleOption(String title, int value) {
    return Row(
      children: [
        Radio(
          value: value,
          groupValue: _userType,
          onChanged: (v) => setState(() => _userType = v!),
          activeColor: const Color(0xFF0D47A1),
        ),
        Text(title),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    IconData icon,
    String hint, {
    bool isPass = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _performLogin() {
    if (_emailController.text.isNotEmpty && _passController.text.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }
}
