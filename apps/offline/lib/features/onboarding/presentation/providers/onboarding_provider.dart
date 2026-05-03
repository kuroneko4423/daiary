import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
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

  Future<bool> isOnWifi() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.wifi);
  }

  Future<void> downloadModel({bool skipWifiCheck = false}) async {
    if (!skipWifiCheck) {
      final onWifi = await isOnWifi();
      if (!onWifi) {
        debugPrint('[Onboarding] downloadModel blocked: not on wifi');
        state = state.copyWith(
          error: 'wifi_required',
        );
        return;
      }
    }

    debugPrint('[Onboarding] downloadModel start');
    state =
        state.copyWith(isDownloading: true, downloadProgress: 0.0, error: null);

    try {
      var lastLoggedDecile = -1;
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'onDownloadProgress') {
          final progress = call.arguments as double;
          final decile = (progress * 10).floor();
          if (decile != lastLoggedDecile) {
            lastLoggedDecile = decile;
            debugPrint(
              '[Onboarding] download progress ${(progress * 100).toStringAsFixed(0)}%',
            );
          }
          state = state.copyWith(downloadProgress: progress);
        }
      });

      await _channel.invokeMethod('downloadModel');

      debugPrint('[Onboarding] downloadModel complete');
      state = state.copyWith(
        isModelReady: true,
        isDownloading: false,
        downloadProgress: 1.0,
      );
    } catch (e) {
      debugPrint('[Onboarding] downloadModel failed: $e');
      state = state.copyWith(
        isDownloading: false,
        error: 'Download failed: $e',
      );
    }
  }

  void cancelDownload() {
    debugPrint('[Onboarding] downloadModel cancel requested');
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
