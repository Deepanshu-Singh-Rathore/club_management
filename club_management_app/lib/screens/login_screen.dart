import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isStudent = true; // Radio button state control karne ke liye

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background gradient wahi purple wala
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
            // Logo aur Name
            const Icon(Icons.cloud_circle, size: 90, color: Colors.white),
            const Text(
              "ClubSphere",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Spacer(),
            
            // Deepanshu ka 'Metallic White' Form Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFFFBFCF6), // Metallic White
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  // Naya Custom TextField Widget
                  const CustomTextField(
                    hintText: "Email", 
                    icon: Icons.email_outlined
                  ),
                  const SizedBox(height: 20),
                  const CustomTextField(
                    hintText: "Password", 
                    icon: Icons.lock_outline, 
                    isPassword: true
                  ),
                  const SizedBox(height: 15),
                  
                  // Student/Admin Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio(
                        value: true, 
                        groupValue: isStudent, 
                        activeColor: const Color(0xFF4A6CF7),
                        onChanged: (v) => setState(() => isStudent = v as bool)
                      ),
                      const Text("Student", style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 30),
                      Radio(
                        value: false, 
                        groupValue: isStudent, 
                        activeColor: const Color(0xFF4A6CF7),
                        onChanged: (v) => setState(() => isStudent = v as bool)
                      ),
                      const Text("Admin", style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  // Naya Custom Button Widget
                  CustomButton(
                    text: "Login",
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Don't have an account? Signup",
                      style: TextStyle(color: Color(0xFF4A6CF7), fontWeight: FontWeight.bold),
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