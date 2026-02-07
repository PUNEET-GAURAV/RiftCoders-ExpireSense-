import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expiresense/presentation/providers.dart';
import 'package:expiresense/core/theme/app_theme.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    CameraDescription? camera;
    for (var c in cameras) {
      if (c.lensDirection == CameraLensDirection.back) {
        camera = c;
        break;
      }
    }
    camera ??= cameras.first; // Fallback

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _switchCamera() async {
      final cameras = await availableCameras();
      if (cameras.length < 2) return;

      final lensDirection = _controller?.description.lensDirection;
      CameraDescription? newCamera;
      
      if (lensDirection == CameraLensDirection.back) {
          newCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
      } else {
          newCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back, orElse: () => cameras.first);
      }

      if (_controller != null) {
          await _controller!.dispose();
      }

      _controller = CameraController(newCamera, ResolutionPreset.high, enableAudio: false);
      
      try {
          await _controller!.initialize();
          setState(() {});
      } catch (e) {
          print("Camera switch error: $e");
      }
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || !_controller!.value.isInitialized || _isScanning) return;

    setState(() => _isScanning = true);

    try {
      final image = await _controller!.takePicture();
      
      // Analyze with Gemini
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Analyzing expiry date with AI...")),
          );
      }
      
      final geminiService = ref.read(geminiServiceProvider);
      final result = await geminiService.scanProduct(image);

      if (mounted) {
        if (result != null) {
          context.push('/add', extra: {
              'imagePath': image.path,
              'initialDate': result['expiry'],
              'initialName': result['name'], // Pass extracted name
          });
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not detect product details. Try again.")),
          );
        }
      }

    } catch (e) {
      debugPrint("Error: $e");
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _pickAndAnalyzeImage() async {
      try {
          final picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: ImageSource.gallery);
          
          if (image == null) return;

          setState(() => _isScanning = true);
          
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Analyzing uploaded image...")),
              );
          }

          final geminiService = ref.read(geminiServiceProvider);
          final result = await geminiService.scanProduct(image);

          if (mounted) {
              if (result != null) {
                  context.push('/add', extra: {
                      'imagePath': image.path,
                      'initialDate': result['expiry'],
                      'initialName': result['name'],
                  });
              } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Could not detect product details.")),
                  );
              }
          }
      } catch (e) {
          debugPrint("Upload Error: $e");
           if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
              );
          }
      } finally {
          if (mounted) setState(() => _isScanning = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),
          // Overlay
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 50,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 300,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
           Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.white, size: 30),
              tooltip: "Upload Image",
              onPressed: _pickAndAnalyzeImage,
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Align Expiry Date in Box",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                FloatingActionButton.large(
                  onPressed: _isScanning ? null : _captureAndAnalyze,
                  child: _isScanning 
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.camera_alt),
                ),
                const SizedBox(height: 16),
                IconButton(
                    onPressed: _switchCamera,
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
                    tooltip: "Flip Camera",
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
