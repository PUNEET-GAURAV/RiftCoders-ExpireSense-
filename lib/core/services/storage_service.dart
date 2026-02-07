import 'package:hive_flutter/hive_flutter.dart';
import 'package:expiresense/data/models/product.dart';

class StorageService {
  static const String boxName = 'productsBox';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    await Hive.openBox<Product>(boxName);
  }

  Box<Product> get _box => Hive.box<Product>(boxName);

  List<Product> getAllProducts() {
    return _box.values.toList();
  }

  Future<void> addProduct(Product product) async {
    await _box.add(product);
  }

  Future<void> updateProduct(Product product) async {
    await product.save();
  }

  Future<void> deleteProduct(Product product) async {
    await product.delete();
  }
  
  // For cleanup/testing
  Future<void> clearAll() async {
    await _box.clear();
  }
}
