import 'package:flutter/material.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Web/Desktop ke liye width control logic
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
                width: contentWidth, // Controlled Width Fix
                child: Column(
                  children: [
                    // Logo (Login/Signup ke barabar chota size)
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
                    const SizedBox(height: 25),

                    // OTP CARD
                    Container(
                      padding: const EdgeInsets.all(25),
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
                        children: [
                          const Text(
                            "OTP Verification",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Enter the code sent to your email",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 25),

                          // OTP Input Field
                          TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 6, // 6 digit OTP limit
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 10,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              counterText: "", // Hide character counter
                              hintText: "000000",
                              hintStyle: TextStyle(
                                  // FIXED: withOpacity replaced with .withValues
                                  color: Colors.grey.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Verify Button
                          SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                // Final step: Home page par bhej rahe hain
                                Navigator.pushReplacementNamed(
                                    context, '/home');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "Verify",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              // Resend OTP logic yahan aayega
                            },
                            child: const Text(
                              "Didn't receive code? Resend",
                              style: TextStyle(
                                  color: Color(0xFF1565C0), fontSize: 12),
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
}
