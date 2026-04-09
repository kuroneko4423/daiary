import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/camera_repository.dart';
import '../../domain/entities/photo.dart';

enum CameraViewState { preview, captured, processing }

class CameraState {
  final CameraViewState viewState;
  final FlashMode flashMode;
  final bool isFrontCamera;
  final bool showGridLines;
  final String? capturedImagePath;
  final Photo? savedPhoto;
  final String? errorMessage;

  const CameraState({
    this.viewState = CameraViewState.preview,
    this.flashMode = FlashMode.auto,
    this.isFrontCamera = false,
    this.showGridLines = false,
    this.capturedImagePath,
    this.savedPhoto,
    this.errorMessage,
  });

  CameraState copyWith({
    CameraViewState? viewState,
    FlashMode? flashMode,
    bool? isFrontCamera,
    bool? showGridLines,
    String? capturedImagePath,
    Photo? savedPhoto,
    String? errorMessage,
  }) {
    return CameraState(
      viewState: viewState ?? this.viewState,
      flashMode: flashMode ?? this.flashMode,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      showGridLines: showGridLines ?? this.showGridLines,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      savedPhoto: savedPhoto ?? this.savedPhoto,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  final CameraRepository _repository;

  CameraNotifier(this._repository) : super(const CameraState());

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

  Future<Photo?> saveAndRegisterPhoto(String sourcePath) async {
    state = state.copyWith(viewState: CameraViewState.processing);
    try {
      final photo = await _repository.savePhoto(sourcePath);
      state = state.copyWith(
        viewState: CameraViewState.captured,
        savedPhoto: photo,
      );
      return photo;
    } catch (e) {
      state = state.copyWith(
        viewState: CameraViewState.captured,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void resetToPreview() {
    state = const CameraState();
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }
}

final cameraRepositoryProvider =
    Provider<CameraRepository>((ref) => CameraRepository());

final cameraNotifierProvider =
    StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  return CameraNotifier(ref.watch(cameraRepositoryProvider));
});

final availableCamerasProvider =
    FutureProvider<List<CameraDescription>>((ref) async {
  return await availableCameras();
});
