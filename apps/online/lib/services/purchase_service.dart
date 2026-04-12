import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Callback type for purchase status updates.
typedef PurchaseStatusCallback = void Function({
  required bool isPremium,
  String? error,
});

class PurchaseService {
  static const String premiumMonthlyId = 'premium_monthly';
  static const Set<String> _productIds = {premiumMonthlyId};

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  PurchaseStatusCallback? _onPurchaseStatusChanged;

  List<ProductDetails> get products => _products;

  /// Sets a callback that is invoked whenever a purchase completes or fails.
  void setOnPurchaseStatusChanged(PurchaseStatusCallback? callback) {
    _onPurchaseStatusChanged = callback;
  }

  /// Initializes the purchase service by listening to purchase updates
  /// and loading available products.
  Future<void> initialize() async {
    final available = await isAvailable();
    if (!available) {
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        _onPurchaseStatusChanged?.call(
          isPremium: false,
          error: error.toString(),
        );
      },
    );

    await loadProducts();
  }

  /// Checks if the in-app purchase system is available on this device.
  Future<bool> isAvailable() async {
    return await _iap.isAvailable();
  }

  /// Queries the store for available product details.
  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);

    if (response.notFoundIDs.isNotEmpty) {
      // Some product IDs were not found in the store.
      // This is expected during development with test IDs.
    }

    _products = response.productDetails;
  }

  /// Initiates the purchase flow for the premium monthly subscription.
  Future<void> buyPremium() async {
    if (_products.isEmpty) {
      await loadProducts();
    }

    final ProductDetails? premiumProduct = _products.cast<ProductDetails?>().firstWhere(
      (p) => p?.id == premiumMonthlyId,
      orElse: () => null,
    );

    if (premiumProduct == null) {
      _onPurchaseStatusChanged?.call(
        isPremium: false,
        error: 'Premium product not found. Please try again later.',
      );
      return;
    }

    final purchaseParam = PurchaseParam(productDetails: premiumProduct);

    // For subscriptions, use buyNonConsumable (subscriptions are non-consumable).
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restores previously purchased subscriptions.
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Handles incoming purchase updates from the purchase stream.
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Purchase is pending - do nothing, wait for final status.
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Verify the purchase on the server side in a production app.
          _onPurchaseStatusChanged?.call(
            isPremium: true,
            error: null,
          );
          // Complete the purchase to finalize the transaction.
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.error:
          _onPurchaseStatusChanged?.call(
            isPremium: false,
            error: purchase.error?.message ?? 'Purchase failed',
          );
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          _onPurchaseStatusChanged?.call(
            isPremium: false,
            error: null,
          );
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  /// Disposes of resources held by this service.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _onPurchaseStatusChanged = null;
  }
}
