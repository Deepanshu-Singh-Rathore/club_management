import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Brilliant White background for a clean look
        scaffoldBackgroundColor: const Color(0xFFEDF1FE), 
        primaryColor: const Color(0xFF7B61FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF7B61FF),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}