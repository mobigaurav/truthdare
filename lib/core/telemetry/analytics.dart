import 'package:firebase_analytics/firebase_analytics.dart';

class AppAnalytics {
  static final _a = FirebaseAnalytics.instance;

  static Future<void> tab(String name) =>
      _a.logEvent(name: 'tab_open', parameters: {'name': name});
  static Future<void> promptNext(String mode) =>
      _a.logEvent(name: 'prompt_next', parameters: {'mode': mode});
  static Future<void> promptSkip(String mode) =>
      _a.logEvent(name: 'prompt_skip', parameters: {'mode': mode});
  static Future<void> favoriteToggle(String mode) =>
      _a.logEvent(name: 'favorite_toggle', parameters: {'mode': mode});

  static Future<void> paywallShown(String source) =>
      _a.logEvent(name: 'paywall_shown', parameters: {'source': source});
  static Future<void> purchaseSuccess() =>
      _a.logEvent(name: 'purchase_success');
  static Future<void> restoreSuccess() => _a.logEvent(name: 'restore_success');

  static Future<void> adImpression(String format, String screen) => _a.logEvent(
    name: 'ad_impression',
    parameters: {'format': format, 'screen': screen},
  );
}
