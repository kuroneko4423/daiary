import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  // Test ad unit IDs (replace with real IDs for production)
  static String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  static String get interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // ---------------------------------------------------------------------------
  // Banner ad
  // ---------------------------------------------------------------------------

  static BannerAd createBannerAd({required void Function() onLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interstitial ad
  // ---------------------------------------------------------------------------

  InterstitialAd? _interstitialAd;
  int _generationCount = 0;

  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Shows an interstitial ad every 5 AI generations.
  Future<void> showInterstitialIfNeeded() async {
    _generationCount++;
    if (_generationCount % 5 == 0) {
      if (_interstitialAd != null) {
        await _interstitialAd!.show();
      } else {
        await loadInterstitialAd();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
