import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:daiary_shared/core/constants/share_constants.dart';
import 'package:daiary_shared/services/share_service.dart';
import 'package:daiary_shared/features/camera/presentation/providers/camera_state.dart';
import 'package:daiary_shared/features/camera/presentation/widgets/camera_controls.dart';
import '../../data/repositories/camera_repository.dart';

final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  return CameraRepository();
});

final cameraNotifierProvider =
    StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier();
});

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !(_controller!.value.isInitialized)) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initError = 'No cameras available on this device';
          _isInitializing = false;
        });
        return;
      }

      final cameraState = ref.read(cameraNotifierProvider);
      final cameraIndex = cameraState.isFrontCamera
          ? cameras.indexWhere(
              (c) => c.lensDirection == CameraLensDirection.front)
          : cameras.indexWhere(
              (c) => c.lensDirection == CameraLensDirection.back);
      final selectedCamera =
          cameras[cameraIndex == -1 ? 0 : cameraIndex];

      _controller?.dispose();
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(cameraState.flashMode);

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = 'Failed to initialize camera: $e';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final image = await _controller!.takePicture();
      final repo = ref.read(cameraRepositoryProvider);
      final savedPath = await repo.savePhoto(image.path);
      ref.read(cameraNotifierProvider.notifier).onPhotoCaptured(savedPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    }
  }

  Future<void> _importFromGallery() async {
    try {
      final repo = ref.read(cameraRepositoryProvider);
      final path = await repo.importFromGallery();
      if (path != null) {
        ref.read(cameraNotifierProvider.notifier).onPhotoImported(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import photo: $e')),
        );
      }
    }
  }

  Future<void> _flipCamera() async {
    ref.read(cameraNotifierProvider.notifier).toggleCamera();
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    ref.read(cameraNotifierProvider.notifier).toggleFlashMode();
    final newMode = ref.read(cameraNotifierProvider).flashMode;
    try {
      await _controller?.setFlashMode(newMode);
    } catch (_) {
      // Some devices don't support all flash modes
    }
  }

  void _toggleGrid() {
    ref.read(cameraNotifierProvider.notifier).toggleGridLines();
  }

  @override
  Widget build(BuildContext context) {
    final cameraState = ref.watch(cameraNotifierProvider);

    if (cameraState.viewState == CameraViewState.captured &&
        cameraState.capturedImagePath != null) {
      return _buildPreviewScreen(cameraState.capturedImagePath!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitializing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : _initError != null
                ? _buildErrorView()
                : _buildCameraView(cameraState),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              _initError!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _importFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Import from Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(CameraState cameraState) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        if (_controller != null && _controller!.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: 1 / _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
        // Grid lines overlay
        if (cameraState.showGridLines) _buildGridOverlay(),
        // Camera controls
        CameraControls(
          onCapture: _capturePhoto,
          onFlipCamera: _flipCamera,
          onToggleFlash: _toggleFlash,
          onOpenGallery: _importFromGallery,
          onToggleGrid: _toggleGrid,
          flashMode: cameraState.flashMode,
          showGridLines: cameraState.showGridLines,
        ),
      ],
    );
  }

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GridPainter(),
      ),
    );
  }

  Widget _buildPreviewScreen(String imagePath) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(cameraNotifierProvider.notifier).resetToPreview();
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(cameraNotifierProvider.notifier)
                          .resetToPreview();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ShareService.shareImageWithText(
                        imagePath,
                        text: ShareTemplates.defaultShareText,
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      context.push('/ai-generate', extra: imagePath);
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI Generate'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Vertical lines (rule of thirds)
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(2 * size.width / 3, 0),
      Offset(2 * size.width / 3, size.height),
      paint,
    );

    // Horizontal lines (rule of thirds)
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, 2 * size.height / 3),
      Offset(size.width, 2 * size.height / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
