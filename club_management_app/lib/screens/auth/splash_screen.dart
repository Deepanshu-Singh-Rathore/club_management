import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import '../student/student_home_screen.dart';
import '../club_head/club_head_home_screen.dart';
import '../admin/admin_home_screen.dart';

/// Splash screen that checks authentication state and routes to appropriate screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  /// Check authentication and navigate to appropriate screen
  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash screen delay

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAuthenticated) {
      // Navigate to role-based home screen
      _navigateToRoleHome(authProvider.userRole);
    } else {
      // Navigate to login
      _navigateToLogin();
    }
  }

  /// Navigate to login screen
  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  /// Navigate to role-based home screen
  void _navigateToRoleHome(String? role) {
    Widget screen;
    switch (role) {
      case 'club_head':
        screen = const ClubHeadHomeScreen();
        break;
      case 'admin':
        screen = const AdminHomeScreen();
        break;
      case 'student':
      default:
        screen = const StudentHomeScreen();
        break;
    }

    Navigator.of(context).pushReplacementNamed(
      '/home',
      arguments: screen,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            const SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Club Management',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
