import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  PurchaseService();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _available = false;
  bool get isAvailable => _available;

  ProductDetails? _premiumProduct;
  ProductDetails? get premiumProduct => _premiumProduct;

  Future<void> init({
    required String premiumProductId,
    required void Function(List<PurchaseDetails>) onPurchaseUpdate,
    required void Function(Object) onError,
  }) async {
    _available = await _iap.isAvailable();
    if (!_available) return;

    // Listen to purchase updates
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen(
      onPurchaseUpdate,
      onError: onError,
      onDone: () {},
    );

    // Query product details
    final response = await _iap.queryProductDetails({premiumProductId});
    if (response.error != null) {
      throw Exception('IAP query error: ${response.error}');
    }
    if (response.productDetails.isNotEmpty) {
      _premiumProduct = response.productDetails.first;
    }
  }

  Future<void> buyPremium() async {
    final product = _premiumProduct;
    if (!_available || product == null) return;

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  Future<void> completeIfNeeded(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
