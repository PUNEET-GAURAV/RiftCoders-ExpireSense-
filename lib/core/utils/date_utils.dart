import 'package:intl/intl.dart';

class AppDateUtils {
  static final List<String> _formats = [
    'yyyy-MM-dd',
    'dd/MM/yyyy',
    'MM/yyyy',
    'dd-MM-yyyy',
    'yyyy/MM/dd',
  ];

  static DateTime? parse(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate.toUpperCase().contains('NOT_FOUND')) {
        return null; 
    }

    // Clean the string (remove potential extra text from AI)
    final cleaned = rawDate.replaceAll(RegExp(r'[^\d\/\-\.]'), '');

    for (var format in _formats) {
      try {
        return DateFormat(format).parse(cleaned);
      } catch (_) {}
    }
    return null;
  }

  static String format(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
