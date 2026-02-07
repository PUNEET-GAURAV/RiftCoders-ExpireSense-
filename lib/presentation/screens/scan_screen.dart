import 'dart:async';
import 'package:camera/camera.dart';
import 'package:expiresense/core/services/ml_services.dart';
import 'package:expiresense/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:expiresense/presentation/providers.dart';

enum ScanMode { barcode, expiry }

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isScanning = false; // If true, we are "paused" after a scan
  ScanMode _scanMode = ScanMode.barcode;
  
  // Camera Controls
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  bool _isFlashOn = false;

  // Stream processing & Throttling
  bool _isProcessingFrame = false;
  int _lastProcessTime = 0;
  final int _throttleMs = 300; // Process every ~300ms

  // Stability / Debounce
  final Map<String, int> _detectionCounter = {};
  final int _stabilityThreshold = 2; // Require 2 consecutive hits
  String? _lastDetectedValue;

  // Animation
  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    // Setup scanning animation
    _animController = AnimationController(
        vsync: this, 
        duration: const Duration(seconds: 2)
    )..repeat(reverse: true);
    
    _anim = Tween<double>(begin: 0.1, end: 0.9).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut)
    );
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Camera permission is required to scan items.'))
         );
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("No cameras found");
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();
      
      // Get Zoom limits
      try {
          _minZoom = await _controller!.getMinZoomLevel();
          _maxZoom = await _controller!.getMaxZoomLevel();
      } catch (e) {
          debugPrint("Error getting zoom levels: $e");
      }
      
      if (mounted) {
        setState(() => _isInitialized = true);
        _startImageStream();
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Camera error: $e"))
          );
      }
    }
  }

  void _startImageStream() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      if (_isProcessingFrame || _isScanning) return;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastProcessTime < _throttleMs) return; // Throttle
      
      _lastProcessTime = now;
      _isProcessingFrame = true;

      try {
        await _processFrame(image);
      } catch (e) {
        debugPrint("Frame process error: $e");
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    final mlService = ref.read(mlServiceProvider);
    final sensorOrient = _controller!.description.sensorOrientation;
    final inputImage = image.toInputImage(_controller!.description, sensorOrient);

    if (inputImage == null) return;

    if (_scanMode == ScanMode.barcode) {
      final barcodes = await mlService.scanBarcodes(inputImage);
      if (barcodes.isNotEmpty) {
        final code = barcodes.first.rawValue;
        if (code != null) {
             _validateAndAct(code, isDate: false);
        }
      } else {
        _resetStability();
      }
    } else {
      final recognizedText = await mlService.scanText(inputImage);
      if (recognizedText != null) {
          final date = mlService.extractExpiryDate(recognizedText.text);
          if (date != null) {
               // Normalize date string for stability check
               String dateStr = date.toIso8601String().split('T')[0];
               _validateAndAct(dateStr, isDate: true, dateObj: date);
          } else {
               _resetStability();
          }
      } else {
          _resetStability();
      }
    }
  }
  
  void _resetStability() {
      _lastDetectedValue = null;
      _detectionCounter.clear();
  }

  void _validateAndAct(String value, {required bool isDate, DateTime? dateObj}) {
      if (_lastDetectedValue == value) {
          _detectionCounter[value] = (_detectionCounter[value] ?? 0) + 1;
      } else {
          _lastDetectedValue = value;
          _detectionCounter[value] = 1;
      }

      if ((_detectionCounter[value] ?? 0) >= _stabilityThreshold) {
          if (isDate) {
              _onDateDetected(dateObj!);
          } else {
              _onBarcodeDetected(value);
          }
      }
  }
  
  // Temporary storage for sequential scan
  Map<String, dynamic>? _scannedProductData;
  String? _scannedBarcode;

  Future<void> _onBarcodeDetected(String code) async {
      if (_isScanning) return;
      _pauseStream();
      HapticFeedback.mediumImpact();
      
      if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Loading product details...", style: GoogleFonts.orbitron()), duration: const Duration(milliseconds: 500), backgroundColor: AppTheme.neonCyan.withOpacity(0.8)),
           );
      }

      final repo = ref.read(productRepositoryProvider);
      final productData = await repo.fetchProductDetails(code);

      if (!mounted) return;

      // Store data for next step
      _scannedBarcode = code;
      _scannedProductData = productData;

      await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _buildProductSheet(ctx, code, productData),
      );
      
      // If sheet closed without action, resume or reset? 
      // For now, resume barcode scanning if they cancelled
      if (_scanMode == ScanMode.barcode) {
          _resumeStream();
      }
  }

  Widget _buildProductSheet(BuildContext context, String code, Map<String, dynamic>? data) {
      final theme = Theme.of(context);
      final name = data?['name'] ?? 'Unknown Product';
      final category = data?['category'] ?? 'Groceries';
      final image = data?['image_url'];

      return Container(
          decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: AppTheme.neonCyan.withOpacity(0.1), blurRadius: 20, spreadRadius: 1)],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Center(
                      child: Container(
                          width: 40, height: 4, 
                          decoration: BoxDecoration(color: AppTheme.neonCyan, borderRadius: BorderRadius.circular(2)),
                      )
                  ),
                  const SizedBox(height: 20),
                  Row(
                      children: [
                          Container(
                             width: 80, height: 80,
                             decoration: BoxDecoration(
                                 color: Colors.black26,
                                 borderRadius: BorderRadius.circular(12),
                                 border: Border.all(color: AppTheme.electricPurple.withOpacity(0.5)),
                                 image: image != null ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover) : null,
                             ),
                             child: image == null ? const Icon(Icons.shopping_bag, size: 40, color: Colors.grey) : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Text(name, style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(category, style: GoogleFonts.outfit(color: Colors.white70)),
                                      const SizedBox(height: 4),
                                      Text("Barcode: $code", style: GoogleFonts.outfit(color: AppTheme.neonCyan)),
                                  ],
                              ),
                          ),
                      ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                      children: [
                          Expanded(
                              child: OutlinedButton(
                                  onPressed: () {
                                      // Skip Expiry Scan
                                      context.pop(); 
                                      _navigateToSave(null);
                                  },
                                  style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      side: const BorderSide(color: AppTheme.neonCyan),
                                      foregroundColor: AppTheme.neonCyan,
                                  ),
                                  child: Text("Skip Date", style: GoogleFonts.orbitron()),
                              ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: ElevatedButton.icon(
                                  onPressed: () {
                                      context.pop(); // Close sheet
                                      // Switch to Expiry Mode
                                      setState(() {
                                          _scanMode = ScanMode.expiry;
                                          _resetStability();
                                          _isScanning = false; // Resume stream logic
                                      });
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Now scan the Expiry Date ->", style: GoogleFonts.orbitron()), duration: const Duration(seconds: 2), backgroundColor: AppTheme.electricPurple),
                                      );
                                  },
                                  icon: const Icon(Icons.calendar_today),
                                  label: const Text("Scan Date"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.electricPurple,
                                      padding: const EdgeInsets.symmetric(vertical: 16)
                                  ),
                              ),
                          ),
                      ],
                  ),
                  const SizedBox(height: 10),
              ],
          ),
      );
  }
  
  void _onDateDetected(DateTime date) {
       if (_isScanning) return;
       _pauseStream();
       HapticFeedback.mediumImpact();
       
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Date Found: ${date.toLocal().toString().split(' ')[0]}", style: GoogleFonts.orbitron()), duration: const Duration(milliseconds: 500), backgroundColor: AppTheme.neonCyan),
           );
           
           _navigateToSave(date);
       }
  }

  void _navigateToSave(DateTime? date) {
      context.push('/add', extra: {
           'imagePath': _scannedProductData?['image_url'], 
           'initialName': _scannedProductData?['name'], 
           'barcode': _scannedBarcode,
           'initialDate': date,
      }).then((_) {
          // Reset state when coming back
          setState(() {
              _scanMode = ScanMode.barcode;
              _scannedProductData = null;
              _scannedBarcode = null;
          });
          _resumeStream();
      });
  }

  void _pauseStream() {
      if (mounted) setState(() => _isScanning = true);
  }
  
  void _resumeStream() {
       _resetStability();
       if (mounted) setState(() => _isScanning = false);
  }
  
  Future<void> _toggleFlash() async {
      if (_controller == null) return;
      try {
          bool newState = !_isFlashOn;
          await _controller!.setFlashMode(newState ? FlashMode.torch : FlashMode.off);
          setState(() => _isFlashOn = newState);
      } catch (e) {
          debugPrint("Flash error: $e");
      }
  }
  
  Future<void> _setZoom(double zoom) async {
      if (_controller == null) return;
      try {
          await _controller!.setZoomLevel(zoom);
          setState(() => _currentZoom = zoom);
      } catch (e) {
          debugPrint("Zoom error: $e");
      }
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller?.stopImageStream();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.neonCyan)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Feed
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),
          
          // Dark Overlay with Hole
          _buildOverlay(),
          
          // Scanning Animation (Laser)
          _buildScannerLine(),

          // Top Bar (Back + Flash)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: () => context.pop(),
                    ),
                    IconButton(
                      icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 30),
                      onPressed: _toggleFlash,
                    ),
                ],
            ),
          ),
          
          // Zoom Slider
          Positioned(
              right: 20,
              top: 150,
              bottom: 200,
              child: RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                      value: _currentZoom,
                      min: _minZoom,
                      max: _maxZoom > 4.0 ? 4.0 : _maxZoom, // Cap max zoom for UI
                      activeColor: AppTheme.neonCyan,
                      inactiveColor: Colors.white24,
                      onChanged: _setZoom,
                  ),
              ),
          ),
          
          // Bottom Controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                 // Mode Switcher
                 _buildModeSwitcher(),
                 const SizedBox(height: 20),
                 Text(
                  _scanMode == ScanMode.barcode 
                     ? "SCAN BARCODE" 
                     : "SCAN EXPIRY DATE",
                  style: GoogleFonts.orbitron(color: AppTheme.neonCyan, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                 ),
                 const SizedBox(height: 10),
                 Text(
                   "Ensure good lighting",
                   style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                 ),
                 const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
      final scanW = 300.0;
      final scanH = _scanMode == ScanMode.barcode ? 180.0 : 120.0;
      final color = _scanMode == ScanMode.barcode ? AppTheme.neonCyan : AppTheme.electricPurple;
      
      return Stack(
          children: [
             // Darken background
             ColorFiltered(
                colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        backgroundBlendMode: BlendMode.srcOut,
                      ),
                      child: const SizedBox.expand(),
                    ),
                    Center(
                      child: Container(
                        width: scanW,
                        height: scanH,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
             ),
             
              // Sci-Fi Brackets
             Center(
               child: CustomPaint(
                 foregroundPainter: _SciFiPainter(
                   lineColor: color,
                   animationValue: _anim.value,
                 ),
                 child: SizedBox(
                   width: scanW + 20,
                   height: scanH + 20,
                 ),
               ),
             ),
          ],
      );
  }

  Widget _buildScannerLine() {
      return AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
              final scanH = _scanMode == ScanMode.barcode ? 180.0 : 120.0;
              final color = _scanMode == ScanMode.barcode ? AppTheme.neonCyan : AppTheme.electricPurple;
              
              return Center(
                  child: Container(
                      width: 280,
                      height: scanH,
                      alignment: Alignment(0, (_anim.value * 2) - 1),
                      child: Container(
                          height: 2, 
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.8),
                              boxShadow: [
                                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                              ],
                          ),
                      ),
                  ),
              );
          },
      );
  }

  Widget _buildModeSwitcher() {
      return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: AppTheme.neonCyan.withOpacity(0.1), blurRadius: 10)],
          ),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  _modeButton("BARCODE", ScanMode.barcode),
                  _modeButton("EXPIRY", ScanMode.expiry),
              ],
          ),
      );
  }

  Widget _modeButton(String title, ScanMode mode) {
      final isSelected = _scanMode == mode;
      final color = mode == ScanMode.barcode ? AppTheme.neonCyan : AppTheme.electricPurple;
      
      return GestureDetector(
          onTap: () {
              setState(() {
                  _scanMode = mode;
                  _resetStability();
              });
              HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: isSelected ? Border.all(color: color) : Border.all(color: Colors.transparent),
              ),
              child: Text(
                  title,
                  style: GoogleFonts.orbitron(
                      color: isSelected ? color : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1,
                  ),
              ),
          ),
      );
  }
}

class _SciFiPainter extends CustomPainter {
  final Color lineColor;
  final double animationValue;

  _SciFiPainter({required this.lineColor, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final glowPaint = Paint()
      ..color = lineColor.withOpacity(0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final w = size.width;
    final h = size.height;
    final cornerSize = 30.0;

    final path = Path();
    // Top Left
    path.moveTo(0, cornerSize);
    path.lineTo(0, 0);
    path.lineTo(cornerSize, 0);
    
    // Top Right
    path.moveTo(w - cornerSize, 0);
    path.lineTo(w, 0);
    path.lineTo(w, cornerSize);
    
    // Bottom Right
    path.moveTo(w, h - cornerSize);
    path.lineTo(w, h);
    path.lineTo(w - cornerSize, h);
    
    // Bottom Left
    path.moveTo(cornerSize, h);
    path.lineTo(0, h);
    path.lineTo(0, h - cornerSize);

    // Draw Glow then Stroke
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
    
    // Draw Grid Lines (Scanning effect)
    final gridPaint = Paint()
      ..color = lineColor.withOpacity(0.1 + (0.2 * animationValue)) // Pulse opacity
      ..strokeWidth = 1;
      
    final step = 20.0;
    for (double i = step; i < h; i += step) {
       canvas.drawLine(Offset(10, i), Offset(w - 10, i), gridPaint);
    }
    for (double i = step; i < w; i += step) {
       canvas.drawLine(Offset(i, 10), Offset(i, h - 10), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SciFiPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.lineColor != lineColor;
  }
}
