import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'OTP_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;
  String selectedRole = "student";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🔵 Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3A7BD5), Color(0xFF8E2DE2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          /// 🔵 Main Content
          Column(
            children: [
              SizedBox(height: 100),

              /// Logo
              Icon(Icons.blur_circular, size: 70, color: Colors.white),

              SizedBox(height: 10),

              /// Title
              Text(
                "ClubSphere",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 40),

              /// White Card
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        /// Email Field
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined),
                            labelText: "Email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        SizedBox(height: 15),

                        /// Password Field
                        TextField(
                          controller: passwordController,
                          obscureText: !isPasswordVisible,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline),
                            labelText: "Password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        /// Role Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Radio(
                              value: "student",
                              groupValue: selectedRole,
                              activeColor: Colors.deepPurple,
                              onChanged: (value) {
                                setState(() {
                                  selectedRole = value.toString();
                                });
                              },
                            ),
                            Text("Student"),

                            Radio(
                              value: "admin",
                              groupValue: selectedRole,
                              activeColor: Colors.deepPurple,
                              onChanged: (value) {
                                setState(() {
                                  selectedRole = value.toString();
                                });
                              },
                            ),
                            Text("Admin"),
                          ],
                        ),

                        SizedBox(height: 20),

                        /// Gradient Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              if (emailController.text.isEmpty ||
                                  passwordController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Please fill all fields"),
                                  ),
                                );
                              } else {
                                /// ✅ Notification
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("OTP Sent Successfully 📩"),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                /// ✅ Go To OTP Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OTPScreen(),
                                  ),
                                );
                              }
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF3A7BD5),
                                    Color(0xFF8E2DE2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 15),

                        /// Signup Option
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SignupScreen()),
                            );
                          },
                          child: Text(
                            "Don't have an account? Signup",
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
