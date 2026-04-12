import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/admob_service.dart';

final adServiceProvider = Provider<AdmobService>((ref) {
  final service = AdmobService();
  service.loadInterstitialAd();
  ref.onDispose(() => service.dispose());
  return service;
});
