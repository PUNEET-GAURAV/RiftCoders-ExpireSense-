import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:expiresense/data/models/product.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/core/utils/date_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expiresense/presentation/widgets/glass_box.dart';
import 'package:expiresense/presentation/widgets/tech_background.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expiresense/core/theme/app_theme.dart';
import 'package:expiresense/presentation/screens/add_product_screen.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider);
    final theme = Theme.of(context);
    
    // Categories for Tabs
    final categories = ["All", "Groceries", "Medicine", "Beauty", "Household", "Other"];

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text("MY INVENTORY", style: GoogleFonts.orbitron(letterSpacing: 2, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: GlassBox(
              opacity: 0.1,
              blur: 10,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: BorderRadius.circular(12),
              child: TabBar(
                isScrollable: true,
                indicatorColor: AppTheme.neonCyan,
                indicatorWeight: 3,
                labelColor: AppTheme.neonCyan,
                unselectedLabelColor: Colors.white54,
                labelStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.orbitron(fontSize: 10),
                tabs: categories.map((c) => Tab(text: c.toUpperCase())).toList(),
              ),
            ),
          ),
        ),
        body: TechBackground(
          child: TabBarView(
            children: categories.map((category) {
              // Filter Logic
              List<Product> filteredProducts;
              if (category == "All") {
                filteredProducts = products.where((p) => !p.isConsumed).toList();
              } else if (category == "Other") {
                // "Other" includes items explicitly "Other" OR items with categories not in the main list
                final mainCategories = ["Groceries", "Medicine", "Beauty", "Household"];
                filteredProducts = products.where((p) => 
                  !p.isConsumed && (p.category == "Other" || !mainCategories.contains(p.category))
                ).toList();
              } else {
                filteredProducts = products.where((p) => !p.isConsumed && p.category == category).toList();
              }

              // Sort: Expiring soonest first
              filteredProducts.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

              return _buildProductList(context, ref, filteredProducts, category);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context, WidgetRef ref, List<Product> activeProducts, String category) {
    if (activeProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.electricPurple.withOpacity(0.5)).animate().scale(duration: 2.seconds, curve: Curves.easeInOut),
             const SizedBox(height: 16),
             Text("NO ${category.toUpperCase()} ITEMS", style: GoogleFonts.orbitron(fontSize: 18, color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.w600)),
             const SizedBox(height: 8),
             Text("Scan items to track them", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white30)),
          ],
        ).animate().fadeIn(duration: 800.ms),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20), // Reduced top padding as TabBar takes space
      itemCount: activeProducts.length,
      itemBuilder: (context, index) {
        final product = activeProducts[index];
        
        Color statusColor = AppTheme.neonCyan; 
        String statusText = "${product.daysRemaining} DAYS LEFT";
        
        if (product.isExpired) {
            statusColor = AppTheme.errorRed;
            statusText = "EXPIRED";
        } else if (product.isExpiringSoon) {
            statusColor = Colors.orangeAccent;
        }

        return Dismissible(
          key: Key(product.id),
          direction: DismissDirection.horizontal,
          background: _buildSwipeAction(Alignment.centerLeft, AppTheme.neonCyan, Icons.check_circle, "CONSUMED"),
          secondaryBackground: _buildSwipeAction(Alignment.centerRight, AppTheme.errorRed, Icons.delete_outline, "WASTE"),
          onDismissed: (direction) {
             HapticFeedback.mediumImpact();
             if (direction == DismissDirection.startToEnd) {
                // Mark as Consumed
                ref.read(productListProvider.notifier).toggleConsumed(product);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product.name} marked as Consumed"), backgroundColor: AppTheme.neonCyan.withOpacity(0.8)));
             } else {
                // Delete
                ref.read(productListProvider.notifier).deleteProduct(product);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${product.name} removed from inventory"), backgroundColor: AppTheme.errorRed));
             }
          },
          child: GlassBox(
            margin: const EdgeInsets.only(bottom: 12),
            opacity: 0.03,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: statusColor.withOpacity(0.05), blurRadius: 10)],
            child: ListTile(
              onTap: () {
                  // NAVIGATE TO EDIT SCREEN
                  Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => AddProductScreen(productToEdit: product))
                  );
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  image: (product.imagePath != null) 
                    ? DecorationImage(
                        image: (product.imagePath!.startsWith('http') 
                          ? CachedNetworkImageProvider(product.imagePath!) 
                          : FileImage(File(product.imagePath!)) as ImageProvider), 
                        fit: BoxFit.cover
                      )
                    : null
                ),
                child: product.imagePath == null ? Icon(Icons.shopping_bag_outlined, color: Colors.white30) : null,
              ),
              title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Expires ${AppDateUtils.format(product.expiryDate)}", 
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.customReminderDate != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.notifications_active, size: 12, color: AppTheme.neonCyan.withOpacity(0.7)),
                        )
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                            statusText,
                            style: GoogleFonts.orbitron(
                                color: statusColor, 
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5
                            ),
                        ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.edit, color: Colors.white30, size: 16),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: (50 * index).ms).slideX(begin: 0.1, curve: Curves.easeOut),
        );
      },
    );
  }

  Widget _buildSwipeAction(Alignment alignment, Color color, IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft 
        ? [Icon(icon, color: color, size: 24), const SizedBox(width: 8), Text(label, style: GoogleFonts.orbitron(color: color, fontWeight: FontWeight.bold, fontSize: 12))]
        : [Text(label, style: GoogleFonts.orbitron(color: color, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(width: 8), Icon(icon, color: color, size: 24)],
      ),
    );
  }
}
