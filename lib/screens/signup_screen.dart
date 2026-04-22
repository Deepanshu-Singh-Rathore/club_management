import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String? selectedInterest;
  final List<String> interests = ['Sports', 'Music', 'Coding', 'Art'];

  // Controllers for data handling
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Responsive width logic: Web/Tablet pe max 400px, phone pe 85%
    double contentWidth = screenWidth > 500 ? 400 : screenWidth * 0.85;

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
                width: contentWidth, // Controlled width fix
                child: Column(
                  children: [
                    // Logo (Fixed Size like Login Screen)
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF0D47A1),
                        image: DecorationImage(
                          image: AssetImage("assets/images/logo.png"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "ClubSphere",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Signup Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            // FIXED: withOpacity replaced with .withValues
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text("🚀", style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),

                          _buildField("Name", _nameController),
                          _buildField("Email", _emailController),
                          _buildField("Password", _passController,
                              isPassword: true),
                          _buildField(
                              "Confirm Password", _confirmPassController,
                              isPassword: true),

                          const Text(
                            "Interest",
                            style: TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Custom Interest Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedInterest,
                                hint: const Text(
                                  "Select Interest",
                                  style: TextStyle(fontSize: 13),
                                ),
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down,
                                    color: Color(0xFF0D47A1)),
                                items: interests.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.black),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) =>
                                    setState(() => selectedInterest = newValue),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Signup Button
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                // FLOW: Signup ke baad OTP page khulega
                                Navigator.pushNamed(context, '/otp');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Create Account",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Already have an account? Login",
                                style: TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontSize: 12,
                                ),
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
      ),
    );
  }

  // Method to build text fields consistently
  Widget _buildField(String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 45,
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.black, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
