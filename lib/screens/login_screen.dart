import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  int _userType = 0;
  bool _obscurePassword = true; // Password hide/show toggle
  bool _isLoading = false; // Loading indicator state

  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError("Please enter a valid email address");
      return;
    }
    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);

    // Mocking an API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Logged in as ${_userType == 0 ? 'Student' : 'Admin'}"),
          backgroundColor: Colors.green,
        ),
      );
      // Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double contentWidth = screenWidth > 500 ? 400 : screenWidth * 0.88;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFADCFFF), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 10),
                    const Text(
                      "ClubSphere",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildLoginCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0D47A1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            "assets/images/logo.png",
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.group_work_rounded,
                color: Colors.white,
                size: 60),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Welcome Back 👋",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 30),
          _buildField("Email Address", _emailController, Icons.email_outlined),
          const SizedBox(height: 20),
          _buildField(
            "Password",
            _passController,
            Icons.lock_outline,
            isPassword: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _roleOption("Student", 0),
              const SizedBox(width: 30),
              _roleOption("Admin", 1),
            ],
          ),
          const SizedBox(height: 30),
          _buildLoginButton(),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            child: RichText(
              text: const TextSpan(
                text: "New here? ",
                style: TextStyle(color: Colors.black54, fontSize: 14),
                children: [
                  TextSpan(
                    text: "Create Account",
                    style: TextStyle(
                        color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                "LOGIN",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1),
              ),
      ),
    );
  }

  Widget _roleOption(String title, int value) {
    bool isSelected = _userType == value;
    return GestureDetector(
      onTap: () => setState(() => _userType = value),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      String hint, TextEditingController controller, IconData icon,
      {bool isPassword = false, Widget? suffixIcon}) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 22),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF1F4F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
      ),
    );
  }
}
