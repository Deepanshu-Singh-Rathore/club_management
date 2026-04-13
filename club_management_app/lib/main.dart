import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/OTP_screen.dart';
import 'main_screen.dart'; // Is line par dhyan dein

void main() {
  runApp(const ClubSphereApp());
}

class ClubSphereApp extends StatelessWidget {
  const ClubSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClubSphere',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/otp': (context) => const OtpScreen(),
        '/home': (context) =>
            MainLayout(), // Maine 'const' hata diya hai yahan se
      },
    );
  }
}
