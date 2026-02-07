import 'package:expiresense/core/services/analytics_service.dart';
import 'package:expiresense/core/theme/app_theme.dart';
import 'package:expiresense/data/models/product.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Product> products = ref.watch(productListProvider);
    final AnalyticsService analytics = ref.watch(analyticsServiceProvider);

    final categoryData = analytics.getCategoryDistribution(products);
    final totalItems = analytics.getTotalItems(products);
    final expiringSoon = analytics.getExpiringSoonCount(products);
    final expired = analytics.getExpiredCount(products);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(child: _SummaryCard(title: "Total", value: "$totalItems", color: Colors.blue, icon: Icons.inventory_2)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(title: "Expiring", value: "$expiringSoon", color: Colors.orange, icon: Icons.warning)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(title: "Expired", value: "$expired", color: Colors.red, icon: Icons.delete_forever)),
              ],
            ),
            const SizedBox(height: 32),

            // Category Chart
            Text("Category Distribution", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            if (products.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No data to display")))
            else
                SizedBox(
                height: 300,
                child: PieChart(
                    PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _buildPieSections(categoryData),
                    ),
                ),
                ),
            
            const SizedBox(height: 24),
            _buildLegend(categoryData),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> data) {
    final List<Color> colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      Colors.purple,
      Colors.orange,
      Colors.blue,
      Colors.grey,
    ];

    int index = 0;
    return data.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, int> data) {
    final List<Color> colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      Colors.purple,
      Colors.orange,
      Colors.blue,
      Colors.grey,
    ];
    int index = 0;
    
    return Wrap(
        spacing: 16,
        runSpacing: 8,
        children: data.entries.map((entry) {
            final color = colors[index % colors.length];
            index++;
            return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 4),
                    Text(entry.key),
                ],
            );
        }).toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)) 
        ]
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
