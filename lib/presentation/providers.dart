import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expiresense/core/services/storage_service.dart';
import 'package:expiresense/core/services/gemini_service.dart';
import 'package:expiresense/core/services/notification_service.dart';
import 'package:expiresense/core/services/auth_service.dart';
import 'package:expiresense/core/services/analytics_service.dart';
import 'package:expiresense/data/models/product.dart';

// Services
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService());

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
    await _notifications.scheduleExpiryNotification(product.key, product.name, product.expiryDate); // key is Hive internal ID
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
     }
    _loadProducts();
  }
}
