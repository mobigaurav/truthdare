import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/iap_constants.dart';
import 'purchase_service.dart';
import 'storage_service.dart';

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  ref.onDispose(() => service.dispose());
  return service;
});

class PremiumState {
  final bool isPremium;
  final bool isIapAvailable;
  final bool isLoading;
  final String? errorMessage;

  const PremiumState({
    required this.isPremium,
    required this.isIapAvailable,
    required this.isLoading,
    this.errorMessage,
  });

  PremiumState copyWith({
    bool? isPremium,
    bool? isIapAvailable,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isIapAvailable: isIapAvailable ?? this.isIapAvailable,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  static const initial = PremiumState(
    isPremium: false,
    isIapAvailable: false,
    isLoading: true,
    errorMessage: null,
  );
}

final premiumControllerProvider =
    StateNotifierProvider<PremiumController, PremiumState>((ref) {
      return PremiumController(ref)..init();
    });

class PremiumController extends StateNotifier<PremiumState> {
  PremiumController(this._ref) : super(PremiumState.initial);

  final Ref _ref;

  Future<void> init() async {
    final storage = _ref.read(storageServiceProvider);
    final purchaseService = _ref.read(purchaseServiceProvider);

    final cachedPremium = await storage.getIsPremium();
    state = state.copyWith(isPremium: cachedPremium);

    try {
      await purchaseService.init(
        premiumProductId: IapConstants.premiumProductId,
        onPurchaseUpdate: _handlePurchaseUpdates,
        onError: (err) {
          state = state.copyWith(errorMessage: err.toString());
        },
      );

      state = state.copyWith(
        isIapAvailable: purchaseService.isAvailable,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> buyPremium() async {
    state = state.copyWith(errorMessage: null);
    await _ref.read(purchaseServiceProvider).buyPremium();
  }

  Future<void> restore() async {
    state = state.copyWith(errorMessage: null);
    await _ref.read(purchaseServiceProvider).restorePurchases();
  }

  Future<void> _setPremium(bool value) async {
    final storage = _ref.read(storageServiceProvider);
    await storage.setIsPremium(value);
    state = state.copyWith(isPremium: value);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    final purchaseService = _ref.read(purchaseServiceProvider);

    for (final purchase in purchases) {
      // Minimal “ship-fast” handling:
      // In production, you’d ideally verify server-side for higher security.
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // If product id matches, unlock premium.
        if (purchase.productID == IapConstants.premiumProductId) {
          await _setPremium(true);
        }
      }

      if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(errorMessage: purchase.error?.message);
      }

      await purchaseService.completeIfNeeded(purchase);
    }
  }
}
