import 'package:expiresense/data/models/product.dart';

class AnalyticsService {
  
  Map<String, int> getCategoryDistribution(List<Product> products) {
    final map = <String, int>{};
    for (var product in products) {
      final category = product.category ?? "Other";
      map[category] = (map[category] ?? 0) + 1;
    }
    return map;
  }

  int getExpiringSoonCount(List<Product> products) {
    return products.where((p) => p.isExpiringSoon && !p.isExpired).length;
  }

  int getExpiredCount(List<Product> products) {
    return products.where((p) => p.isExpired).length;
  }

  int getTotalItems(List<Product> products) {
    return products.length;
  }
}
