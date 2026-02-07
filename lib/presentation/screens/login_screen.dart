import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expiresense/core/services/auth_service.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/presentation/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGoogle();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      // Guest login just sets a mock state in AuthService
      final auth = ref.read(authServiceProvider);
      await auth.login("guest", "guest123"); 
      if (mounted) context.go('/');
    } catch (e) {
       // Should not happen for guest, but safety first
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFD500F9).withOpacity(0.15),
                shape: BoxShape.circle,

              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.15),
                shape: BoxShape.circle,

              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Icon(Icons.lock_open_rounded, size: 80, color: Colors.white)
                      .animate()
                      .fadeIn()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(duration: 2.seconds, delay: 1.seconds),
                  
                  const SizedBox(height: 30),
                  
                  Text(
                    "WELCOME BACK",
                    style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                  ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    "Sign in to sync your inventory",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 60),

                  if (_isLoading)
                    const CircularProgressIndicator(color: Color(0xFF00E5FF))
                  else
                    Column(
                      children: [
                        // Google Login
                        PrimaryButton(
                          text: "Sign in with Google",
                          icon: Icons.g_mobiledata,
                          onPressed: _handleGoogleLogin,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Guest Login
                        SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                                onPressed: _handleGuestLogin,
                                icon: const Icon(Icons.person_outline),
                                label: Text("Continue as Guest", style: GoogleFonts.orbitron(fontSize: 16, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                            ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  Text(
                    "By continuing, you agree to our Terms & Privacy Policy",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ).animate().fadeIn(delay: 800.ms),
                  
                  const SizedBox(height: 20),
                  // App Version
                  Text(
                      "v1.0.0 Cyber-Tech", 
                      style: GoogleFonts.outfit(color: const Color(0xFF00E5FF).withOpacity(0.5), fontSize: 10)
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Needed for blur

