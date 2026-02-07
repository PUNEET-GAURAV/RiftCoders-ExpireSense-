import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expiresense/core/theme/app_theme.dart';
import 'package:expiresense/core/services/storage_service.dart';
import 'package:expiresense/core/services/notification_service.dart';
import 'package:expiresense/core/services/auth_service.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/presentation/screens/home_screen.dart';
import 'package:expiresense/presentation/screens/login_screen.dart';
import 'package:expiresense/presentation/screens/splash_screen.dart';
import 'package:expiresense/presentation/screens/onboarding_screen.dart';
import 'package:expiresense/presentation/screens/scan_screen.dart';
import 'package:expiresense/presentation/screens/add_product_screen.dart';
import 'package:expiresense/presentation/screens/inventory_screen.dart';
import 'package:expiresense/presentation/screens/dashboard_screen.dart';
import 'package:expiresense/presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization failed: $e");
    // Continue running app even if Firebase fails, to allow UI testing
  }
  
  await dotenv.load(fileName: ".env");
  
  // Initialize Services
  final storage = StorageService();
  await storage.init();
  
  final notifications = NotificationService();
  await notifications.init();
  
  // Request Notification Permissions (Added Fix)
  await notifications.requestPermissions();

  final auth = AuthService();
  await auth.init();

  runApp(ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      storageServiceProvider.overrideWithValue(storage),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
    child: const ExpireSenseApp(),
  ));
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AddProductScreen(
          imagePath: extra?['imagePath'],
          initialDate: extra?['initialDate'],
          initialName: extra?['initialName'],
          barcode: extra?['barcode'],
          // Ensure we handle 'productToEdit' if passed via context push or extra
          productToEdit: extra?['productToEdit'],
        );
      },
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class ExpireSenseApp extends StatelessWidget {
  const ExpireSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ExpireSense',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force Dark Mode for this design
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
