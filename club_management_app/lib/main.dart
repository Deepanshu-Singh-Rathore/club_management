import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/clubs_screen.dart';
import 'screens/events_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/clubhead/create_event_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/OTP_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/community_feed_screen.dart';
import 'screens/achievements_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..tryRestoreSession(),
      child: const ClubSphereApp(),
    ),
  );
}

class ClubSphereApp extends StatelessWidget {
  const ClubSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClubSphere',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _RootRouter(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/otp': (_) => const OtpScreen(),
        '/home': (_) => const HomeScreen(),
        '/discover': (_) => const DiscoverScreen(),
        '/community': (_) => const CommunityFeedScreen(),
        '/achievements': (_) => const AchievementsScreen(),
        '/clubs': (_) => const ClubsScreen(),
        '/events': (_) => const EventsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
        '/clubhead/create-event': (_) => const CreateEventScreen(),
        '/event-detail': (context) => const EventDetailScreen(),
      },
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
