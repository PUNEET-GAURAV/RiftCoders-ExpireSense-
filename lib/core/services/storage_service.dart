import 'package:hive_flutter/hive_flutter.dart';
import 'package:expiresense/data/models/product.dart';

class StorageService {
  static const String boxName = 'productsBox';
  static const String settingsBoxName = 'settingsBox';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    await Hive.openBox<Product>(boxName);
    await Hive.openBox(settingsBoxName);
  }

  Box<Product> get _box => Hive.box<Product>(boxName);
  Box get _settingsBox => Hive.box(settingsBoxName);

  // Settings
  bool get notificationsEnabled => _settingsBox.get('notificationsEnabled', defaultValue: true);
  
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put('notificationsEnabled', enabled);
  }

  int get daysBeforeExpiry => _settingsBox.get('daysBeforeExpiry', defaultValue: 7);

  Future<void> setDaysBeforeExpiry(int days) async {
    await _settingsBox.put('daysBeforeExpiry', days);
  }

  bool get isFirstLaunch => _settingsBox.get('isFirstLaunch', defaultValue: true);

  Future<void> setFirstLaunchCompleted() async {
    await _settingsBox.put('isFirstLaunch', false);
  }

  List<Product> getAllProducts() {
    return _box.values.toList();
  }

  Future<void> addProduct(Product product) async {
    await _box.add(product);
  }

  Future<void> updateProduct(Product product) async {
    await product.save();
  }

  Future<void> updateProductAtIndex(dynamic key, Product newProduct) async {
    await _box.put(key, newProduct);
  }

  Future<void> deleteProduct(Product product) async {
    await product.delete();
  }
  
  // For cleanup/testing
  Future<void> clearAll() async {
    await _box.clear();
  }
}
