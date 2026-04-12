import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/index.dart';
import 'providers/index.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service
  final apiService = ApiService();
  await apiService.init();

  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;

  const MyApp({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Initialize API service as a provider
        Provider<ApiService>(create: (_) => apiService),

        // Providers
        ChangeNotifierProvider(
          create: (context) => AuthProvider(apiService)..init(),
        ),
        ChangeNotifierProvider(
          create: (context) => ClubProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (context) => JoinRequestProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (context) => EventProvider(apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Club Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.light,
        routes: AppRoutes.getRoutes(),
        initialRoute: '/',
      ),
    );
  }
}
