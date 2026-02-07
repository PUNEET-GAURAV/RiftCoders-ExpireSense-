import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime expiryDate;

  @HiveField(3)
  final DateTime addedDate;

  @HiveField(4)
  final String? imagePath;

  @HiveField(5)
  final String? category;

  @HiveField(6)
  final String? barcode;

  @HiveField(7)
  bool isConsumed;

  Product({
    String? id,
    required this.name,
    required this.expiryDate,
    required this.addedDate,
    this.imagePath,
    this.category,
    this.barcode,
    this.isConsumed = false,
  }) : id = id ?? const Uuid().v4();

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  bool get isExpired => daysRemaining < 0;
  bool get isFresh => daysRemaining > 7;
  bool get isExpiringSoon => daysRemaining >= 0 && daysRemaining <= 7;
}
