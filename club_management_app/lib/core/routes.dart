import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../screens/club_head/club_head_home_screen.dart';
import '../screens/admin/admin_home_screen.dart';

/// Named routes for navigation
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegistrationScreen(),
      home: (context) {
        // Get the screen from arguments passed during navigation
        final screen = ModalRoute.of(context)?.settings.arguments as Widget?;
        return screen ?? const StudentHomeScreen();
      },
    };
  }
}
