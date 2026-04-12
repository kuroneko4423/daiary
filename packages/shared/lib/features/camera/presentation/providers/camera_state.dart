import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CameraViewState { preview, captured, processing }

class CameraState {
  final CameraViewState viewState;
  final FlashMode flashMode;
  final bool isFrontCamera;
  final bool showGridLines;
  final String? capturedImagePath;
  final String? errorMessage;

  const CameraState({
    this.viewState = CameraViewState.preview,
    this.flashMode = FlashMode.auto,
    this.isFrontCamera = false,
    this.showGridLines = false,
    this.capturedImagePath,
    this.errorMessage,
  });

  CameraState copyWith({
    CameraViewState? viewState,
    FlashMode? flashMode,
    bool? isFrontCamera,
    bool? showGridLines,
    String? capturedImagePath,
    String? errorMessage,
  }) {
    return CameraState(
      viewState: viewState ?? this.viewState,
      flashMode: flashMode ?? this.flashMode,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      showGridLines: showGridLines ?? this.showGridLines,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(const CameraState());

  void toggleFlashMode() {
    final modes = FlashMode.values;
    final nextIndex = (modes.indexOf(state.flashMode) + 1) % modes.length;
    state = state.copyWith(flashMode: modes[nextIndex]);
  }

  void toggleCamera() {
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  void toggleGridLines() {
    state = state.copyWith(showGridLines: !state.showGridLines);
  }

  void onPhotoCaptured(String path) {
    state = state.copyWith(
      viewState: CameraViewState.captured,
      capturedImagePath: path,
    );
  }

  void onPhotoImported(String path) {
    state = state.copyWith(
      viewState: CameraViewState.captured,
      capturedImagePath: path,
    );
  }

  void resetToPreview() {
    state = const CameraState();
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }
}

final availableCamerasProvider =
    FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});
