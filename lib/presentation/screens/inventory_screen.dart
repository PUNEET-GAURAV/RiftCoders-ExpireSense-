import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/core/utils/date_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);
    
    // Sort: Expiring soonest first
    final sortedProducts = List.of(products)..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return Scaffold(
      appBar: AppBar(title: const Text("My Inventory")),
      body: sortedProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text("No items yet.", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedProducts.length,
              itemBuilder: (context, index) {
                final product = sortedProducts[index];
                
                Color statusColor = Colors.green;
                if (product.isExpired) {
                    statusColor = Colors.red;
                } else if (product.isExpiringSoon) {
                    statusColor = Colors.orange;
                }

                return Dismissible(
                  key: Key(product.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                     ref.read(productListProvider.notifier).deleteProduct(product);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(Icons.calendar_today, color: statusColor),
                      ),
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Expires: ${AppDateUtils.format(product.expiryDate)}"),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                            Text(
                                product.isExpired 
                                    ? "EXPIRED" 
                                    : "${product.daysRemaining} days",
                                style: TextStyle(
                                    color: statusColor, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12
                                ),
                            ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1),
                );
              },
            ),
    );
  }
}
