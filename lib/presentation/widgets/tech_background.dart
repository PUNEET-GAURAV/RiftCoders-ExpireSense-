import 'package:flutter/material.dart';
import 'package:expiresense/core/theme/app_theme.dart';

class TechBackground extends StatefulWidget {
  final Widget child;
  const TechBackground({super.key, required this.child});

  @override
  State<TechBackground> createState() => _TechBackgroundState();
}

class _TechBackgroundState extends State<TechBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base Dark Layer
        Container(color: AppTheme.deepCharcoal),

        // Animated Grid
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _GridPainter(
                color: AppTheme.neonCyan.withOpacity(0.05),
                offset: _controller.value,
              ),
              child: Container(),
            );
          },
        ),

        // Vignette (Dark Edges)
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.transparent,
                AppTheme.deepCharcoal.withOpacity(0.8),
                Colors.black,
              ],
              stops: const [0.5, 0.8, 1.0],
            ),
          ),
        ),
        
        // Content
        widget.child,
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double offset;

  _GridPainter({required this.color, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final gridSize = 40.0;
    
    // Vertical Lines (Static)
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal Lines (Moving)
    final shift = offset * gridSize;
    for (double y = -gridSize; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y + shift), Offset(size.width, y + shift), paint);
    }
    
    // Tech Crosshairs
    final crossHairPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2;
      
    // Random fixed tech accents
    canvas.drawLine(Offset(20, 100), Offset(40, 100), crossHairPaint);
    canvas.drawLine(Offset(20, 100), Offset(20, 120), crossHairPaint);
    
    canvas.drawLine(Offset(size.width - 20, size.height - 100), Offset(size.width - 40, size.height - 100), crossHairPaint);
    canvas.drawLine(Offset(size.width - 20, size.height - 100), Offset(size.width - 20, size.height - 120), crossHairPaint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.offset != offset;
  }
}
