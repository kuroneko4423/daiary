import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../services/purchase_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class PurchaseState {
  final bool isPremium;
  final bool isLoading;
  final List<ProductDetails> products;
  final String? error;

  const PurchaseState({
    this.isPremium = false,
    this.isLoading = false,
    this.products = const [],
    this.error,
  });

  PurchaseState copyWith({
    bool? isPremium,
    bool? isLoading,
    List<ProductDetails>? products,
    String? error,
  }) {
    return PurchaseState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      products: products ?? this.products,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final PurchaseService _purchaseService;

  PurchaseNotifier(this._purchaseService) : super(const PurchaseState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);

    _purchaseService.setOnPurchaseStatusChanged(
      ({required bool isPremium, String? error}) {
        state = state.copyWith(
          isPremium: isPremium,
          isLoading: false,
          error: error,
        );
      },
    );

    await _purchaseService.initialize();

    state = state.copyWith(
      products: _purchaseService.products,
      isLoading: false,
    );
  }

  Future<void> buyPremium() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _purchaseService.buyPremium();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _purchaseService.restorePurchases();
      // The result will come through the purchase stream callback.
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(() => service.dispose());
  return service;
});

final purchaseProvider =
    StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final service = ref.watch(purchaseServiceProvider);
  return PurchaseNotifier(service);
});
