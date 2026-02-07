import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/core/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expiresense/core/theme/app_theme.dart';
import 'package:expiresense/presentation/widgets/tech_background.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text("SETTINGS", style: GoogleFonts.orbitron(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: TechBackground(
            child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
            children: [
              _buildSectionHeader("PREFERENCES"),
              
              // Notifications Toggle
              _buildSettingTile(
                context,
                icon: Icons.notifications_active_outlined,
                title: "Notifications",
                subtitle: "Alerts for expiring items",
                trailing: Switch(
                  value: ref.watch(settingsProvider),
                  activeColor: AppTheme.neonCyan,
                  onChanged: (val) {
                     ref.read(settingsProvider.notifier).toggleNotifications(val);
                     if (val) {
                         ref.read(notificationServiceProvider).requestPermissions();
                     }
                  },
                ),
              ),
              
              if (ref.watch(settingsProvider)) ...[
                  // Test Notification Button
                  _buildSettingTile(
                    context,
                    icon: Icons.notification_important_outlined,
                    title: "Test Notification",
                    subtitle: "Send a test alert now",
                    titleColor: Colors.amberAccent,
                    onTap: () async {
                        await ref.read(notificationServiceProvider).showTestNotification();
                        if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Notification Sent!", style: GoogleFonts.orbitron(color: Colors.black)), backgroundColor: AppTheme.neonCyan)
                            );
                        }
                    },
                  ),
              ],
              
              // Reminder Timing
              if (ref.watch(settingsProvider))
                  _buildSettingTile(
                    context,
                    icon: Icons.timer,
                    title: "Alert Timing",
                    subtitle: "${ref.watch(storageServiceProvider).daysBeforeExpiry} days before expiry",
                    trailing: SizedBox(
                        width: 120,
                        child: Slider(
                            value: ref.watch(storageServiceProvider).daysBeforeExpiry.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: "${ref.watch(storageServiceProvider).daysBeforeExpiry} days",
                            activeColor: AppTheme.neonCyan,
                            onChanged: (val) {
                                ref.read(settingsProvider.notifier).updateDaysBeforeExpiry(val.round());
                                (context as Element).markNeedsBuild();
                            },
                        ),
                    ),
              ),

              const SizedBox(height: 30),
              _buildSectionHeader("DATA MANAGEMENT"),
              
              // Clear Data
              _buildSettingTile(
                context,
                icon: Icons.delete_forever_outlined,
                title: "Factory Reset",
                subtitle: "Wipe all inventory data",
                titleColor: AppTheme.errorRed,
                onTap: () => _confirmReset(context, ref),
              ),
              
              // Logout
              _buildSettingTile(
                context,
                icon: Icons.logout,
                title: "Logout",
                subtitle: "Sign out of your account",
                titleColor: Colors.orangeAccent,
                onTap: () async {
                    await ref.read(authServiceProvider).logout();
                    if (context.mounted) context.go('/login');
                },
              ),

              const SizedBox(height: 30),
              _buildSectionHeader("ABOUT"),
              
              // Version
              _buildSettingTile(
                context,
                icon: Icons.info_outline,
                title: "Version",
                subtitle: "v1.3.0 (Tech-Grid Build)",
              ),
              
              // Credits / Contact
               _buildSettingTile(
                context,
                icon: Icons.code,
                title: "Developer",
                subtitle: "Built with Flutter & ML Kit",
              ),
            ].animate(interval: 50.ms).fadeIn().slideX(begin: 0.05),
          ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        title, 
        style: GoogleFonts.orbitron(color: AppTheme.neonCyan, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    String? subtitle, 
    Widget? trailing, 
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (titleColor ?? Colors.white).withOpacity(0.1)),
        boxShadow: onTap != null ? [BoxShadow(color: (titleColor ?? AppTheme.neonCyan).withOpacity(0.05), blurRadius: 10)] : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: (titleColor ?? AppTheme.neonCyan).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (titleColor ?? AppTheme.neonCyan).withOpacity(0.3))
            ),
            child: Icon(icon, color: titleColor ?? AppTheme.neonCyan, size: 20)
        ),
        title: Text(title, style: GoogleFonts.outfit(color: titleColor ?? Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
      final confirm = await showDialog<bool>(
          context: context, 
          builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(side: BorderSide(color: AppTheme.errorRed.withOpacity(0.5)), borderRadius: BorderRadius.circular(20)),
              title: const Text("Factory Reset?", style: TextStyle(color: AppTheme.errorRed, fontFamily: 'Orbitron')),
              content: const Text("This will permanently delete all your inventory data. This action cannot be undone."),
              actions: [
                  TextButton(onPressed: () => ctx.pop(false), child: const Text("Cancel", style: TextStyle(color: Colors.white))),
                  FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
                      onPressed: () => ctx.pop(true), 
                      child: const Text("Reset Everything")
                  ),
              ],
          )
      );

      if (confirm == true) {
           await ref.read(storageServiceProvider).clearAll();
           ref.read(productListProvider.notifier).clearAllProducts();
           
           if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("System Reset Complete", style: TextStyle(fontFamily: 'Orbitron'))));
               context.go('/');
           }
      }
  }
}
