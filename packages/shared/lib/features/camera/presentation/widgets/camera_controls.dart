import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback? onCapture;
  final VoidCallback? onFlipCamera;
  final VoidCallback? onToggleFlash;
  final VoidCallback? onOpenGallery;
  final VoidCallback? onToggleGrid;
  final FlashMode flashMode;
  final bool showGridLines;

  const CameraControls({
    super.key,
    this.onCapture,
    this.onFlipCamera,
    this.onToggleFlash,
    this.onOpenGallery,
    this.onToggleGrid,
    this.flashMode = FlashMode.auto,
    this.showGridLines = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top controls: flash and grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: onToggleFlash,
                icon: Icon(_flashIcon, color: Colors.white),
                tooltip: 'Flash: ${flashMode.name}',
              ),
              IconButton(
                onPressed: onToggleGrid,
                icon: Icon(
                  Icons.grid_on,
                  color: showGridLines ? Colors.yellow : Colors.white,
                ),
                tooltip: 'Grid lines',
              ),
            ],
          ),
        ),
        const Spacer(),
        // Bottom controls: gallery, capture, flip
        Padding(
          padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Gallery button
              IconButton(
                onPressed: onOpenGallery,
                icon: const Icon(Icons.photo_library, size: 32),
                color: Colors.white,
                tooltip: 'Import from gallery',
              ),
              // Capture button
              GestureDetector(
                onTap: onCapture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Flip camera button
              IconButton(
                onPressed: onFlipCamera,
                icon: const Icon(Icons.flip_camera_android, size: 32),
                color: Colors.white,
                tooltip: 'Flip camera',
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData get _flashIcon {
    switch (flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.highlight;
    }
  }
}
