import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ProductRepository {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  Future<Map<String, dynamic>?> fetchProductDetails(String barcode) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$barcode.json'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          return {
            'name': product['product_name'] ?? product['product_name_en'] ?? 'Unknown Product',
            'image_url': product['image_front_url'] ?? product['image_url'],
            'category': _mapCategory(product['categories_tags'] ?? []),
          };
        }
      }
    } catch (e) {
      debugPrint("Error fetching product: $e");
    }
    return null;
  }

  String _mapCategory(List<dynamic> tags) {
    // Simple mapping logic
    if (tags.any((t) => t.toString().contains('beverage') || t.toString().contains('drink'))) return 'Drinks';
    if (tags.any((t) => t.toString().contains('medicine') || t.toString().contains('pharmacy'))) return 'Medicine';
    if (tags.any((t) => t.toString().contains('beauty') || t.toString().contains('cosmetic'))) return 'Beauty';
    if (tags.any((t) => t.toString().contains('cleaning') || t.toString().contains('household'))) return 'Household';
    return 'Groceries'; // Default
  }
}
