import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expiresense/presentation/widgets/glass_box.dart';
import 'package:expiresense/core/theme/app_theme.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      opacity: 0.05,
      blur: 15,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)), // Neon Border
      boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, spreadRadius: -2)], // Inner Glow
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1), 
                boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)]
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title, 
              style: GoogleFonts.orbitron( // Tech Font
                color: Colors.white.withOpacity(0.9), 
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 1
              )
            ),
          ],
        ),
      ),
    );
  }
}
