import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:expiresense/core/theme/app_theme.dart';
import 'package:expiresense/core/services/storage_service.dart';
import 'package:expiresense/core/services/notification_service.dart';
import 'package:expiresense/core/services/auth_service.dart';
import 'package:expiresense/presentation/screens/home_screen.dart';
import 'package:expiresense/presentation/screens/login_screen.dart';
import 'package:expiresense/presentation/screens/scan_screen.dart';
import 'package:expiresense/presentation/screens/add_product_screen.dart';
import 'package:expiresense/presentation/screens/inventory_screen.dart';
import 'package:expiresense/presentation/screens/dashboard_screen.dart';

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

  final auth = AuthService();
  await auth.init();

  runApp(ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
    ],
    child: const ExpireSenseApp(),
  ));
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Temporarily disabled for debugging/access
    // final ref = ProviderScope.containerOf(context);
    // final auth = ref.read(authServiceProvider);
    // final isLoggedIn = auth.isLoggedIn;
    // final isLoginRoute = state.uri.path == '/login';

    // if (!isLoggedIn && !isLoginRoute) return '/login';
    // if (isLoggedIn && isLoginRoute) return '/';
    return null;
  },
  routes: [
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
  ],
);

class ExpireSenseApp extends StatelessWidget {
  const ExpireSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ExpireSense',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
