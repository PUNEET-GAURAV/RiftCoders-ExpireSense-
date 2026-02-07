import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expiresense/core/services/auth_service.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/presentation/widgets/tech_background.dart';
import 'package:expiresense/core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for animation to finish (approx 3 seconds)
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (!mounted) return;

    final auth = ref.read(authServiceProvider);
    final storage = ref.read(storageServiceProvider);
    
    final isLoggedIn = auth.isLoggedIn;
    final isFirstLaunch = storage.isFirstLaunch;
    
    if (isFirstLaunch) {
      context.go('/onboarding');
    } else if (isLoggedIn) {
      context.go('/');
    } else {
      context.go('/login'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: TechBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonCyan.withOpacity(0.05),
                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                  boxShadow: [
                    BoxShadow(color: AppTheme.neonCyan.withOpacity(0.5), blurRadius: 40, spreadRadius: 5),
                    BoxShadow(color: AppTheme.electricPurple.withOpacity(0.3), blurRadius: 80, spreadRadius: 20),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                      const Icon(Icons.shield, size: 60, color: AppTheme.neonCyan), 
                      Positioned(
                          top: 35,
                          child: const Icon(Icons.access_time_filled, size: 30, color: AppTheme.electricPurple),
                      ),
                  ],
                ),
              )
              .animate()
              .scale(duration: 1000.ms, curve: Curves.elasticOut) // Bounce In
              .then(delay: 500.ms) // Wait
              .shimmer(duration: 1000.ms, color: Colors.white) // Scan shine
              .then()
              .scaleXY(end: 20, duration: 500.ms, curve: Curves.easeIn) // Zoom IN to camera/app
              .fadeOut(duration: 300.ms), // Fade out as it zooms too close

              const SizedBox(height: 40),

              // Text
              Column(
                children: [
                  Text(
                    "EXPIRESENSE",
                    style: GoogleFonts.orbitron(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: [Shadow(color: AppTheme.neonCyan, blurRadius: 20)]
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "SYSTEM INITIALIZING...",
                    style: GoogleFonts.sourceCodePro( // Fixed Font
                      fontSize: 14,
                      color: AppTheme.neonCyan,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: 500.ms, duration: 800.ms)
              .then(delay: 1200.ms)
              .fadeOut(duration: 300.ms), // Fade out with logo
            ],
          ),
        ),
      ),
    );
  }
}
