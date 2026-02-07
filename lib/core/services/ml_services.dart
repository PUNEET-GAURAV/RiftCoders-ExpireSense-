import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MLService {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  bool _isProcessingLink = false;

  void dispose() {
    _barcodeScanner.close();
    _textRecognizer.close();
  }

  // Barcode Scanning
  Future<List<Barcode>> scanBarcodes(InputImage inputImage) async {
    try {
      return await _barcodeScanner.processImage(inputImage);
    } catch (e) {
      debugPrint("Error scanning barcodes: $e");
      return [];
    }
  }

  // Text Recognition
  Future<RecognizedText?> scanText(InputImage inputImage) async {
      try {
          return await _textRecognizer.processImage(inputImage);
      } catch (e) {
          debugPrint("Error scanning text: $e");
          return null;
      }
  }

  // Helper to extract date from text
  DateTime? extractExpiryDate(String text) {
    if (text.isEmpty) return null;
    // Clean text to standardise
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    
    // 1. Try to calculate from Mfg Date + Duration
    DateTime? calculatedDate = _calculateExpiryFromMfg(lines);
    if (calculatedDate != null) return calculatedDate;

    // 2. If calculation fails, look for an explicit Expiry Date
    DateTime? explicitDate = _findExplicitDate(lines);
    
    // Safety Force: If explicit date matches a Mfg date found by the Mfg finder, discard it.
    // This handles cases where _findExplicitDate's filter failed but _findMfgDate succeeded.
    if (explicitDate != null) {
        DateTime? mfgCheck = _findMfgDate(lines);
        if (mfgCheck != null && _isSameDate(explicitDate, mfgCheck)) {
             return null; // It's likely a manufacturing date
        }
    }
    
    return explicitDate;
  }
  
  bool _isSameDate(DateTime d1, DateTime d2) {
      return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  DateTime? _findExplicitDate(List<String> lines) {
    DateTime? bestDate;
    int maxScore = -1;

    // Regex for Numeric Dates: DD/MM/YYYY, MM/YYYY
    final RegExp numericDateRegex = RegExp(
      r'\b(?:(?:3[01]|[12][0-9]|0?[1-9])[\.\-\/](?:1[0-2]|0?[1-9])[\.\-\/](?:(?:19|20)\d{2}|\d{2}))\b|\b(?:(?:1[0-2]|0?[1-9])[\.\-\/](?:(?:19|20)\d{2}|\d{2}))\b|\b(?:(?:19|20)\d{2}[\.\-\/](?:1[0-2]|0?[1-9])[\.\-\/](?:3[01]|[12][0-9]|0?[1-9]))\b',
    );

    // Regex for Text Month Dates: "Sept 2023", "Oct. 2023", "12 Aug 2024"
    final RegExp textMonthRegex = RegExp(
      r'\b(?:(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|SEPT|OCT|NOV|DEC)[A-Z\.]*[\s\-\,\.]+(\d{4}))\b|\b(?:(\d{1,2})[\s\-\.]+(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|SEPT|OCT|NOV|DEC)[A-Z\.]*[\s\-\,\.]+(?:(?:19|20)\d{2}|\d{2}))\b',
      caseSensitive: false
    );

    final mfgKeywords = ['MFG', 'MFD', 'MANUFACTURED', 'PROD', 'PKD', 'PACKED', 'M.R.P', 'BATCH', 'DATE OF PACKAGING', 'DATE OF MFG'];
    final expKeywords = ['EXP', 'BB', 'BEST BEFORE', 'USE BY', 'E/D', 'B.B.', 'EXPIRES', 'VALID', 'USE WITHIN', 'USE BEFORE', 'SHELF LIFE'];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      String upperLine = line.toUpperCase();
      
      bool isMfg = mfgKeywords.any((k) => upperLine.contains(k));
      bool isExp = expKeywords.any((k) => upperLine.contains(k));

      // Skip probable Mfg dates (Context Check)
      if (isMfg && !isExp) continue; 
      
      // Strict Context Check: Check Previous Line if current line has no keywords
      if (!isMfg && !isExp && i > 0) {
          String prevLine = lines[i-1].toUpperCase();
          if (mfgKeywords.any((k) => prevLine.contains(k))) continue; // Likely Mfg date on next line
      }

      int score = 0;
      if (isExp) score += 10; 
      
      // Check Numeric Matches
      _checkMatches(numericDateRegex, line, score, (d, s) {
           if (s > maxScore) { maxScore = s; bestDate = d; }
           else if (s == maxScore && bestDate != null && d.isAfter(bestDate!)) { bestDate = d; }
      });

      // Check Text Matches
      _checkMatches(textMonthRegex, line, score, (d, s) {
           if (s > maxScore) { maxScore = s; bestDate = d; }
           else if (s == maxScore && bestDate != null && d.isAfter(bestDate!)) { bestDate = d; }
      });
    }
    return bestDate;
  }

  void _checkMatches(RegExp regex, String line, int baseScore, Function(DateTime, int) onValid) {
      var matches = regex.allMatches(line);
      for (final match in matches) {
          DateTime? d = _parseDate(match.group(0)!);
          // Sanity check: Date should be recent-ish (e.g. 2023+)
          if (d != null && d.year >= 2023) {
             onValid(d, baseScore + 1);
          }
      }
  }

  DateTime? _calculateExpiryFromMfg(List<String> lines) {
     // 1. FIRST find Duration. If no duration, we can't calculate.
     Duration? duration = _findDuration(lines);
     if (duration == null) return null;

     // 2. THEN find Mfg Date.
     DateTime? mfgDate = _findMfgDate(lines);
     if (mfgDate == null) return null;

     return mfgDate.add(duration);
  }

  DateTime? _findMfgDate(List<String> lines) {
    // Regex for "Sept 2023", "23/09/2023" etc.
    final RegExp dateRegex = RegExp(
      r'\b(?:(?:3[01]|[12][0-9]|0?[1-9])[\.\-\/](?:1[0-2]|0?[1-9])[\.\-\/](?:(?:19|20)\d{2}|\d{2}))\b|\b(?:(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|SEPT|OCT|NOV|DEC)[A-Z\.]*[\s\-\,\.]+(\d{4}))\b|\b(?:(\d{1,2})[\s\-\.]+(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|SEPT|OCT|NOV|DEC)[A-Z\.]*[\s\-\,\.]+(?:(?:19|20)\d{2}|\d{2}))\b',
      caseSensitive: false
    );
    
     final mfgKeywords = ['MFG', 'MFD', 'MANUFACTURED', 'PROD', 'PKD', 'PACKED', 'DATE OF PACKAGING', 'PACKAGING DATE', 'M.R.P']; // MRP often near mfg

     for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        String upperLine = line.toUpperCase();
        
        // If line has a keyword, look for date on THIS line OR NEXT line
        if (mfgKeywords.any((k) => upperLine.contains(k))) {
            // Check this line
            Match? match = dateRegex.firstMatch(line);
            if (match != null) return _parseDate(match.group(0)!);

            // Check next line (Neighbor Search)
            if (i + 1 < lines.length) {
               String nextLine = lines[i+1];
               match = dateRegex.firstMatch(nextLine);
               if (match != null) return _parseDate(match.group(0)!);
            }
        }
     }
     
     // Fallback: If we FOUND a duration (which we checked before calling this),
     // we are permitted to be more aggressive in finding a date.
     // Look for ANY valid date that is NOT explicitly an expiry date.
     final expKeywords = ['EXP', 'BB', 'BEST BEFORE', 'USE BY', 'EXPIRES', 'USE WITHIN', 'USE BEFORE', 'SHELF LIFE'];
     
     for (String line in lines) {
         if (expKeywords.any((k) => line.toUpperCase().contains(k))) continue;
         Match? match = dateRegex.firstMatch(line);
         if (match != null) {
             // Use this as fallback Mfg date
             // (Assuming that if we have a duration, the only other date around is likely Mfg)
             return _parseDate(match.group(0)!);
         }
     }

     return null;
  }

  Duration? _findDuration(List<String> lines) {
     final RegExp durationRegex1 = RegExp(r'(?:BEST BEFORE|USE BY|SHELF LIFE|EXPIRY|USE BEFORE|USE WITHIN)[\s\w:\.]*?(\d+)[\s]*(MONTH|YEAR|DAY)S?', caseSensitive: false);
     final RegExp durationRegex2 = RegExp(r'(\d+)[\s]*(MONTH|YEAR|DAY)S?[\s]*FROM[\s]*(?:PACKAGING|MFG|DATE|MANUFACTURE|THE DATE OF MFG)', caseSensitive: false);
     
     // New: Handle "Best Before N Months" appearing alone
     final RegExp durationRegex3 = RegExp(r'BEST BEFORE[\s\w:\.]*?(\d+)[\s]*(MONTH|YEAR|DAY)S?', caseSensitive: false);
    
     // New: Handle "Use within N Months" specifically
     final RegExp durationRegex4 = RegExp(r'USE WITHIN[\s\w:\.]*?(\d+)[\s]*(MONTH|YEAR|DAY)S?', caseSensitive: false);

     // New: Handle "Best before and use before N months" 
     final RegExp durationRegex5 = RegExp(r'(?:BEST BEFORE|USE BEFORE)[\s\w]*?(?:AND|&)?[\s\w]*?(?:BEST BEFORE|USE BEFORE)[\s\w:\.]*?(\d+)[\s]*(MONTH|YEAR|DAY)S?', caseSensitive: false);

     for (String line in lines) {
        Match? match = durationRegex1.firstMatch(line);
        if (match != null) return _parseDurationFromMatch(match);
        
        match = durationRegex2.firstMatch(line);
        if (match != null) return _parseDurationFromMatch(match);
        
        match = durationRegex3.firstMatch(line);
        if (match != null) return _parseDurationFromMatch(match);
        
        match = durationRegex4.firstMatch(line);
        if (match != null) return _parseDurationFromMatch(match);

        match = durationRegex5.firstMatch(line);
        if (match != null) return _parseDurationFromMatch(match);
     }
     return null;
  }

  Duration? _parseDurationFromMatch(Match match) {
       try {
         int value = int.parse(match.group(1)!);
         String unit = match.group(2)!.toUpperCase();
         
         if (unit.startsWith('MONTH')) {
            return Duration(days: value * 30); 
         } else if (unit.startsWith('YEAR')) {
            return Duration(days: value * 365);
         } else if (unit.startsWith('DAY')) {
            return Duration(days: value);
         }
       } catch (e) { return null; }
       return null;
  }

  DateTime? _parseDate(String dateStr) {
    try {
      String cleanDate = dateStr.toUpperCase().replaceAll('.', ' ').replaceAll('-', ' ').replaceAll('/', ' ').trim();
      List<String> parts = cleanDate.split(RegExp(r'\s+'));
      
      int day = 1;
      int month = 1;
      int year = DateTime.now().year;

      int? parsedMonth = _getMonthNumber(parts);
      if (parsedMonth != null) {
         month = parsedMonth;
         for (var part in parts) {
            if (part.length == 4 && int.tryParse(part) != null) year = int.parse(part);
            if (part.length <= 2 && int.tryParse(part) != null) {
               int val = int.parse(part);
               if (val > 0 && val <= 31) day = val;
            }
         }
      } else {
          if (parts.length == 3) {
            if (parts[0].length == 4) {
               year = int.parse(parts[0]);
               month = int.parse(parts[1]);
               day = int.parse(parts[2]);
            } else {
               day = int.parse(parts[0]);
               month = int.parse(parts[1]);
               year = int.parse(parts[2]);
            }
          } else if (parts.length == 2) {
             // MM/YYYY or YYYY/MM
             if (parts[0].length == 4) {
                 year = int.parse(parts[0]);
                 month = int.parse(parts[1]);
             } else if (parts[1].length == 4) {
                 month = int.parse(parts[0]);
                 year = int.parse(parts[1]);
             } else {
                 // Maybe MM/YY? 
                 month = int.parse(parts[0]);
                 year = int.parse(parts[1]) + 2000;
             }
          } else {
              return null;
          }
      }

      if (year < 100) year += 2000;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  int? _getMonthNumber(List<String> parts) {
      final months = {
          'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
          'JUL': 7, 'AUG': 8, 'SEP': 9, 'SEPT': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12
      };
      
      for (var part in parts) {
          for (var key in months.keys) {
              if (part.startsWith(key)) return months[key];
          }
      }
      return null;
  }
}

extension CameraImageExtension on CameraImage {
  InputImage? toInputImage(CameraDescription camera, int sensorOrientation) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(width.toDouble(), height.toDouble());

    final InputImageRotation imageRotation =
        InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat =
        InputImageFormatValue.fromRawValue(format.raw) ?? InputImageFormat.nv21;

    if (inputImageFormat == InputImageFormat.yuv420 || inputImageFormat == InputImageFormat.nv21) {
         // OK
    }

    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }
}
