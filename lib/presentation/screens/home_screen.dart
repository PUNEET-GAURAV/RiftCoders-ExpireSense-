import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/presentation/widgets/custom_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);

    final total = products.length;
    final expired = products.where((p) => p.isExpired).length;
    final soon = products.where((p) => p.isExpiringSoon).length;
    final fresh = total - expired - soon;

    return Scaffold(
      appBar: AppBar(title: const Text("ExpireSense")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(child: _buildStatCard(context, "Total", total.toString(), Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, "Expiring", soon.toString(), Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, "Expired", expired.toString(), Colors.red)),
              ],
            ),
            const SizedBox(height: 24),

            // Chart
            if (total > 0)
              AspectRatio(
                aspectRatio: 1.5,
                child: CustomCard(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        if (fresh > 0)
                          PieChartSectionData(color: Colors.green, value: fresh.toDouble(), title: "$fresh", radius: 50),
                        if (soon > 0)
                          PieChartSectionData(color: Colors.orange, value: soon.toDouble(), title: "$soon", radius: 55),
                        if (expired > 0)
                          PieChartSectionData(color: Colors.red, value: expired.toDouble(), title: "$expired", radius: 60),
                      ],
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            Text("Quick Actions", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            CustomCard(
              onTap: () => context.push('/scan'),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 32),
                  SizedBox(width: 16),
                  Text("Scan Product", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
             CustomCard(
              onTap: () => context.push('/inventory'),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list, size: 32),
                  SizedBox(width: 16),
                  Text("View Inventory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
             const SizedBox(height: 12),
             CustomCard(
              onTap: () => context.push('/dashboard'),
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 32, color: Theme.of(context).colorScheme.onTertiaryContainer),
                  const SizedBox(width: 16),
                  Text("Analytics Dashboard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onTertiaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
