import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expiresense/core/services/storage_service.dart';
import 'package:expiresense/core/services/gemini_service.dart';
import 'package:expiresense/core/services/notification_service.dart';
import 'package:expiresense/core/services/auth_service.dart';
import 'package:expiresense/core/services/analytics_service.dart';
import 'package:expiresense/core/services/ml_services.dart';
import 'package:expiresense/data/repositories/product_repository.dart';
import 'package:expiresense/data/models/product.dart';

// Services
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());
final mlServiceProvider = Provider<MLService>((ref) => MLService());
final productRepositoryProvider = Provider<ProductRepository>((ref) => ProductRepository());

final settingsProvider = StateNotifierProvider<SettingsNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SettingsNotifier(storage);
});

class SettingsNotifier extends StateNotifier<bool> {
  final StorageService _storage;
  
  SettingsNotifier(this._storage) : super(true) {
    state = _storage.notificationsEnabled;
  }
  
  Future<void> toggleNotifications(bool value) async {
    await _storage.setNotificationsEnabled(value);
    state = value;
  }

  Future<void> updateDaysBeforeExpiry(int days) async {
    await _storage.setDaysBeforeExpiry(days);
  }
}

// State
final productListProvider = StateNotifierProvider<ProductListNotifier, List<Product>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final notifications = ref.watch(notificationServiceProvider);
  return ProductListNotifier(storage, notifications);
});

class ProductListNotifier extends StateNotifier<List<Product>> {
  final StorageService _storage;
  final NotificationService _notifications;

  ProductListNotifier(this._storage, this._notifications) : super([]) {
    _loadProducts();
  }

  void _loadProducts() {
    state = _storage.getAllProducts();
  }

  Future<void> addProduct(Product product) async {
    await _storage.addProduct(product);
    if (_storage.notificationsEnabled) {
        final daysBefore = _storage.daysBeforeExpiry;
        await _notifications.scheduleExpiryNotification(
            product.key, 
            product.name, 
            product.expiryDate, 
            daysBefore: daysBefore,
            customReminderDate: product.customReminderDate
        );
    }
    _loadProducts();
  }

  Future<void> updateProduct(dynamic key, Product newProduct) async {
     // 1. Cancel old notifications (using key)
     await _notifications.cancelNotifications(key);
     
     // 2. Save updates
     await _storage.updateProductAtIndex(key, newProduct);

     // 3. Reschedule notifications
     if (_storage.notificationsEnabled && !newProduct.isConsumed) {
         final daysBefore = _storage.daysBeforeExpiry;
         await _notifications.scheduleExpiryNotification(
             key, 
             newProduct.name, 
             newProduct.expiryDate, 
             daysBefore: daysBefore,
             customReminderDate: newProduct.customReminderDate
         );
     }
     _loadProducts();
  }
  
  Future<void> deleteProduct(Product product) async {
      await _notifications.cancelNotifications(product.key);
      await _storage.deleteProduct(product);
      _loadProducts();
  }

  Future<void> toggleConsumed(Product product) async {
    product.isConsumed = !product.isConsumed;
    await _storage.updateProduct(product);
     if (product.isConsumed) {
         await _notifications.cancelNotifications(product.key);
     } else {
         // Reschedule if un-consumed
         if (_storage.notificationsEnabled) {
            final daysBefore = _storage.daysBeforeExpiry;
            await _notifications.scheduleExpiryNotification(
                product.key, 
                product.name, 
                product.expiryDate, 
                daysBefore: daysBefore,
                customReminderDate: product.customReminderDate
            );
         }
     }
    _loadProducts();
  }
  
  Future<void> clearAllProducts() async {
      final products = state;
      for (var p in products) {
          await _notifications.cancelNotifications(p.key);
      }
      await _storage.clearAll();
      _loadProducts();
  }
}
