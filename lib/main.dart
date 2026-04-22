import 'package:flutter/material.dart';
import 'package:club_management_app/main_screen.dart';
import 'package:club_management_app/screens/login_screen.dart';
import 'package:club_management_app/screens/signup_screen.dart';
import 'package:club_management_app/screens/OTP_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClubSphere',
      // Theme ko Light rakhein taaki aapka white UI sahi dikhe
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/otp': (context) => const OtpScreen(),
        '/home': (context) =>
            const MainLayout(), // Indexing isi ke andar handle hogi
      },
    );
  }
}
