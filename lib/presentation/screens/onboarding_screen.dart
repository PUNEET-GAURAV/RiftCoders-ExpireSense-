import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/presentation/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      "title": "SCAN BARCODE",
      "desc": "Instantly identify products with our high-speed scanner.",
      "icon": Icons.qr_code_scanner,
      "color": Color(0xFF00E5FF),
    },
    {
      "title": "CAPTURE EXPIRY",
      "desc": "Use AI to read expiry dates directly from the packaging.",
      "icon": Icons.calendar_today,
      "color": Color(0xFFD500F9),
    },
    {
      "title": "GET ALERTS",
      "desc": "Receive timely notifications before your items go bad.",
      "icon": Icons.notifications_active,
      "color": Colors.orangeAccent,
    },
     {
      "title": "SECURE SYNC",
      "desc": "Login to backup your inventory and access it anywhere.",
      "icon": Icons.cloud_sync,
      "color": Colors.greenAccent,
    },
  ];

  void _finishOnboarding() async {
    await ref.read(storageServiceProvider).setFirstLaunchCompleted();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pages[_currentPage]['color'].withOpacity(0.1),

              ),
            ),
          ),
          
          PageView.builder(
            controller: _controller,
            onPageChanged: (v) => setState(() => _currentPage = v),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(page['icon'], size: 100, color: page['color']).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 60),
                    Text(
                      page['title'], 
                      textAlign: TextAlign.center,
                      style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 20),
                    Text(
                      page['desc'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              );
            },
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 8),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? _pages[_currentPage]['color'] : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                
                // Next/Done Button
                PrimaryButton(
                  width: 160,
                  height: 48,
                  text: _currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT",
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(duration: 400.ms, curve: Curves.easeInOut);
                    } else {
                      _finishOnboarding();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Needed for blur

