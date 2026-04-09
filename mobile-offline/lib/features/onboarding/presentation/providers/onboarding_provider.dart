import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final bool isModelReady;
  final bool isDownloading;
  final double downloadProgress;
  final String? error;

  const OnboardingState({
    this.isModelReady = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.error,
  });

  OnboardingState copyWith({
    bool? isModelReady,
    bool? isDownloading,
    double? downloadProgress,
    String? error,
  }) {
    return OnboardingState(
      isModelReady: isModelReady ?? this.isModelReady,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  static const _channel = MethodChannel('com.daiary.offline/gemma');

  OnboardingNotifier() : super(const OnboardingState());

  Future<void> checkModelStatus() async {
    try {
      final ready = await _channel.invokeMethod<bool>('isModelReady');
      state = state.copyWith(isModelReady: ready ?? false);
    } catch (e) {
      state = state.copyWith(
        isModelReady: false,
        error: 'Failed to check model status: $e',
      );
    }
  }

  Future<void> downloadModel() async {
    state = state.copyWith(isDownloading: true, downloadProgress: 0.0, error: null);

    try {
      // Set up progress callback
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onDownloadProgress') {
          final progress = call.arguments as double;
          state = state.copyWith(downloadProgress: progress);
        }
      });

      await _channel.invokeMethod('downloadModel');

      state = state.copyWith(
        isModelReady: true,
        isDownloading: false,
        downloadProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: 'Download failed: $e',
      );
    }
  }

  void cancelDownload() {
    _channel.invokeMethod('cancelDownload');
    state = state.copyWith(isDownloading: false, downloadProgress: 0.0);
  }

  Future<void> deleteModel() async {
    try {
      await _channel.invokeMethod('deleteModel');
      state = state.copyWith(isModelReady: false);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete model: $e');
    }
  }
}

final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
