import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ads_service.dart';
import 'premium_providers.dart';

final adsServiceProvider = Provider<AdsService>((ref) {
  final service = AdsService();
  ref.onDispose(service.dispose);

  // If user is NOT premium, we can preload interstitial early.
  final premium = ref.watch(premiumControllerProvider);
  if (!premium.isPremium) {
    service.preloadInterstitial();
  }

  return service;
});
