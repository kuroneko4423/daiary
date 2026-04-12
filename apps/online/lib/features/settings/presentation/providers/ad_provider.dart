import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/admob_service.dart';
import 'purchase_provider.dart';

// ---------------------------------------------------------------------------
// AdmobService singleton provider
// ---------------------------------------------------------------------------

final adServiceProvider = Provider<AdmobService>((ref) {
  final service = AdmobService();
  // Pre-load interstitial and rewarded ads.
  service.loadInterstitialAd();
  service.loadRewardedAd();
  ref.onDispose(() => service.dispose());
  return service;
});

// ---------------------------------------------------------------------------
// Whether to show ads (true when user is NOT premium)
// ---------------------------------------------------------------------------

final showAdsProvider = Provider<bool>((ref) {
  final purchaseState = ref.watch(purchaseProvider);
  return !purchaseState.isPremium;
});

// ---------------------------------------------------------------------------
// Generation count tracking for interstitial ad timing
// ---------------------------------------------------------------------------

class GenerationCountNotifier extends StateNotifier<int> {
  GenerationCountNotifier() : super(0);

  void increment() {
    state++;
  }

  void reset() {
    state = 0;
  }
}

final generationCountProvider =
    StateNotifierProvider<GenerationCountNotifier, int>((ref) {
  return GenerationCountNotifier();
});
