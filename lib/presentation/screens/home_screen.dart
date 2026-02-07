import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:expiresense/core/theme/app_theme.dart';
import 'package:expiresense/data/models/product.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/presentation/widgets/action_card.dart';
import 'package:expiresense/presentation/widgets/glass_box.dart';
import 'package:expiresense/presentation/widgets/tech_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(productListProvider); // Watch for changes
    final products = ref.read(productListProvider);
    final theme = Theme.of(context);
    
    // Stats
    final expiringSoon = products.where((p) => p.isExpiringSoon && !p.isConsumed).length;
    final expired = products.where((p) => p.isExpired && !p.isConsumed).length;
    final active = products.where((p) => !p.isConsumed && !p.isExpired).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_moon, color: AppTheme.neonCyan, size: 24),
            const SizedBox(width: 10),
            Text("EXPIRESENSE", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 22)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: TechBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 110, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // System Status HUD
              GlassBox(
                opacity: 0.05,
                blur: 20,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
                boxShadow: [BoxShadow(color: AppTheme.neonCyan.withOpacity(0.1), blurRadius: 20, spreadRadius: -5)],
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("SYSTEM STATUS", style: GoogleFonts.orbitron(fontSize: 12, color: AppTheme.neonCyan, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.neonCyan.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text("ONLINE", style: TextStyle(color: AppTheme.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHudStat("ACTIVE", active.toString(), Colors.white),
                        Container(width: 1, height: 40, color: Colors.white10),
                        _buildHudStat("WARNING", expiringSoon.toString(), Colors.orangeAccent),
                        Container(width: 1, height: 40, color: Colors.white10),
                        _buildHudStat("CRITICAL", expired.toString(), AppTheme.errorRed),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOut),

              const SizedBox(height: 32),
              
              Text("QUICK ACTIONS", style: GoogleFonts.orbitron(fontSize: 14, color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ActionCard(
                      title: "SCAN ITEM",
                      icon: Icons.qr_code_scanner,
                      color: AppTheme.neonCyan,
                      onTap: () => context.push('/scan'),
                    ).animate().slideX(begin: -0.2, delay: 200.ms),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionCard(
                      title: "MANUAL ADD",
                      icon: Icons.edit_note,
                      color: AppTheme.electricPurple,
                      onTap: () => context.push('/add'),
                    ).animate().slideX(begin: 0.2, delay: 300.ms),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Text("INVENTORY LINK", style: GoogleFonts.orbitron(fontSize: 14, color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              InkWell(
                onTap: () => context.push('/inventory'),
                borderRadius: BorderRadius.circular(24),
                child: GlassBox(
                  height: 100,
                  opacity: 0.05,
                  blur: 15,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                        child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("VIEW ALL ITEMS", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text("${products.length} Items Logged", style: GoogleFonts.outfit(color: Colors.white54)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 16),
               InkWell(
                onTap: () => context.push('/dashboard'),
                borderRadius: BorderRadius.circular(24),
                child: GlassBox(
                  height: 80,
                  opacity: 0.03,
                  blur: 10,
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_outlined, color: Colors.white54),
                      const SizedBox(width: 20),
                      Text("ANALYTICS DASHBOARD", style: GoogleFonts.orbitron(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 16),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHudStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.bold, color: color, shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10)])),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
