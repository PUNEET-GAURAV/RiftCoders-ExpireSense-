import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/data/models/product.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expiresense/presentation/widgets/glass_box.dart';
import 'package:expiresense/presentation/widgets/tech_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expiresense/core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);
    final theme = Theme.of(context);

    // Calculate Stats
    final totalValue = products.fold(0.0, (sum, item) => sum + (item.price)); 
    final expiredCount = products.where((p) => p.isExpired && !p.isConsumed).length;
    final consumedCount = products.where((p) => p.isConsumed).length;
    final wastedCount = products.where((p) => p.isExpired && !p.isConsumed).length;
    final activeCount = products.where((p) => !p.isExpired && !p.isConsumed).length;

    // Data Presence Check
    bool hasData = products.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("ANALYTICS", style: GoogleFonts.orbitron(letterSpacing: 2, fontWeight: FontWeight.bold, color: AppTheme.electricPurple)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: TechBackground(
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(child: _buildStatCard(theme, "TOTAL LOGGED", products.length.toString(), Icons.inventory_2, AppTheme.neonCyan)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(theme, "CONSUMED", consumedCount.toString(), Icons.check_circle, Colors.greenAccent)),
                  ],
                ).animate().slideX(begin: -0.1, duration: 400.ms),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(theme, "EXPIRING SOON", 
                        products.where((p) => p.isExpiringSoon && !p.isConsumed).length.toString(), 
                        Icons.warning_amber, Colors.orangeAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(theme, "WASTED", wastedCount.toString(), Icons.delete_outline, AppTheme.errorRed)),
                  ],
                ).animate().slideX(begin: 0.1, duration: 400.ms, delay: 100.ms),
                
                const SizedBox(height: 24),
                
                // Chart Section
                Text("CONSUMPTION RATIO", style: GoogleFonts.orbitron(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 20),
                
                SizedBox(
                  height: 250,
                  child: Stack(
                      alignment: Alignment.center,
                      children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 50,
                              sections: hasData ? [
                                 PieChartSectionData(
                                   value: activeCount.toDouble(),
                                   color: AppTheme.neonCyan,
                                   title: '${(activeCount / products.length * 100).toInt()}%',
                                   radius: 60,
                                   titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                 ),
                                 PieChartSectionData(
                                   value: consumedCount.toDouble(),
                                   color: Colors.greenAccent,
                                   title: '${(consumedCount / products.length * 100).toInt()}%',
                                   radius: 65,
                                   titleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                 ),
                                 PieChartSectionData(
                                   value: wastedCount.toDouble(),
                                   color: AppTheme.errorRed,
                                   title: '${(wastedCount / products.length * 100).toInt()}%',
                                   radius: 60,
                                   titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                 ),
                              ] : [
                                  PieChartSectionData(
                                   value: 1,
                                   color: Colors.white10,
                                   radius: 60,
                                   showTitle: false,
                                 ),
                              ],
                            ),
                          ),
                          if (!hasData)
                              const Text("No Data", style: TextStyle(color: Colors.white30)),
                      ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
                
                // Legend
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(AppTheme.neonCyan, "Active"),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.greenAccent, "Consumed"),
                    const SizedBox(width: 16),
                    _buildLegendItem(AppTheme.errorRed, "Wasted"),
                  ],
                ),
              ],
            ),
          ),
        ), // TechBackground closing
    ); // Scaffold closing
  }

  Widget _buildStatCard(ThemeData theme, String title, String value, IconData icon, Color color) {
    return GlassBox(
      opacity: 0.03,
      blur: 10,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      border: Border.all(color: color.withOpacity(0.2)),
      boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 5)]
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)])),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
