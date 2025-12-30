import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:truth_dare/data/providers/prompt_providers.dart';
import 'package:truth_dare/data/providers/remote_prompt_status_provider.dart';

import '../../core/services/ads_providers.dart';
import '../../core/services/premium_providers.dart';
import '../favorites/favorites_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ---- Update these for production ----
  static const String privacyUrl = 'https://YOUR_DOMAIN/privacy';
  static const String termsUrl = 'https://YOUR_DOMAIN/terms';

  // Use your real store links once you have them:
  // iOS format: https://apps.apple.com/app/idYOUR_APP_ID?action=write-review
  static const String iosRateUrl =
      'https://apps.apple.com/app/idYOUR_APP_ID?action=write-review';

  // Android format: market://details?id=your.package.name
  static const String androidRateUrl = 'market://details?id=com.your.app';

  static const String shareText =
      'Try Truth or Dare — Party + Couples mode ❤️\n';
  static const String shareUrl = 'https://YOUR_APP_LINK';

  static const String supportEmail = 'support@yourdomain.com';
  static const String supportSubject = 'Truth & Dare Support';

  ProviderSubscription<PremiumState>? _premiumSub;
  bool _didInitialBannerSync = false;

  @override
  void initState() {
    super.initState();

    // Keep banner synced with premium status (initState safe)
    _premiumSub = ref.listenManual<PremiumState>(premiumControllerProvider, (
      prev,
      next,
    ) {
      if (next.isLoading) return;
      final adsSvc = ref.read(adsServiceProvider);
      if (next.isPremium) {
        adsSvc.disposeBanner();
      } else {
        adsSvc.loadBanner();
      }
    });
  }

  @override
  void dispose() {
    _premiumSub?.close();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }

  Future<void> _rateApp() async {
    final url = Platform.isIOS ? iosRateUrl : androidRateUrl;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // Android "market://" might fail on simulators — fallback to https
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && Platform.isAndroid) {
      final httpsFallback = Uri.tryParse(
        'https://play.google.com/store/apps/details?id=com.your.app',
      );
      if (httpsFallback != null) {
        await launchUrl(httpsFallback, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _contactSupport() async {
    final info = await PackageInfo.fromPlatform();
    final body = Uri.encodeComponent(
      'Hi Support,\n\n'
      'I need help with:\n\n'
      '---\n'
      'App: ${info.appName}\n'
      'Version: ${info.version} (${info.buildNumber})\n'
      'Platform: ${Platform.operatingSystem}\n',
    );

    final mail = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': supportSubject, 'body': body},
    );

    await launchUrl(mail, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareApp() async {
    await Share.share('$shareText$shareUrl');
  }

  Future<void> _showAbout() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 10),
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(info.appName),
                  subtitle: Text(
                    'Version ${info.version} (${info.buildNumber})',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Truth & Dare for parties and couples.\n'
                  'Premium unlocks Couples mode and removes ads.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _cardList(List<Widget> tiles) {
    return Card(
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumControllerProvider);
    final controller = ref.read(premiumControllerProvider.notifier);
    final ads = ref.watch(adsServiceProvider);

    final updatedAtAsync = ref.watch(remotePromptUpdatedAtProvider);
    final promptsAsync = ref.watch(allPromptsProvider);

    // ✅ One-time initial banner sync after premium is known
    if (!_didInitialBannerSync && !premium.isLoading) {
      _didInitialBannerSync = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(premiumControllerProvider).isPremium) {
          ref.read(adsServiceProvider).disposeBanner();
        } else {
          ref.read(adsServiceProvider).loadBanner();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _sectionTitle('Premium'),
                _cardList([
                  ListTile(
                    leading: Icon(
                      premium.isPremium ? Icons.verified : Icons.star,
                    ),
                    title: Text(
                      premium.isPremium ? 'Premium Active' : 'Get Premium',
                    ),
                    subtitle: Text(
                      premium.isPremium
                          ? 'Couples unlocked • Ads removed'
                          : 'Unlock Couples • Remove ads',
                    ),
                    trailing: premium.isPremium
                        ? null
                        : FilledButton(
                            onPressed: premium.isLoading
                                ? null
                                : controller.buyPremium,
                            child: const Text('Unlock'),
                          ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restore Purchase'),
                    onTap: premium.isLoading ? null : controller.restore,
                  ),
                ]),

                _sectionTitle('Your stuff'),
                _cardList([
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text('Favorites'),
                    subtitle: const Text('View saved prompts'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                ]),

                _sectionTitle('Support'),
                _cardList([
                  ListTile(
                    leading: const Icon(Icons.star_rate),
                    title: const Text('Rate the app'),
                    onTap: _rateApp,
                  ),
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('Share'),
                    onTap: _shareApp,
                  ),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Contact Support'),
                    subtitle: Text(supportEmail),
                    onTap: _contactSupport,
                  ),
                ]),

                _sectionTitle('Legal'),
                _cardList([
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: () => _openUrl(privacyUrl),
                  ),
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('Terms of Use'),
                    onTap: () => _openUrl(termsUrl),
                  ),
                ]),

                _sectionTitle('App'),
                _cardList([
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    onTap: _showAbout,
                  ),
                ]),

                // Optional: keep your Remote status card but tuck it under Developer
                _sectionTitle('Developer'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remote Prompts Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        promptsAsync.when(
                          loading: () => const Text('Loading prompts...'),
                          error: (e, _) => Text('Prompts error: $e'),
                          data: (prompts) =>
                              Text('Loaded prompts: ${prompts.length}'),
                        ),
                        updatedAtAsync.when(
                          loading: () => const Text('Checking cache...'),
                          error: (e, _) => Text('Cache read error: $e'),
                          data: (ts) => Text(
                            'Cached updatedAt: ${ts ?? "none (using bundled asset or cache not set)"}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (premium.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    premium.errorMessage!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                  ),
                ],
              ],
            ),
          ),

          // Banner only if NOT premium
          if (!premium.isPremium)
            StreamBuilder<BannerAd?>(
              stream: ads.bannerAdStream,
              builder: (context, snapshot) {
                final banner = snapshot.data;
                if (banner == null) return const SizedBox.shrink();
                return SafeArea(
                  top: false,
                  child: SizedBox(
                    width: banner.size.width.toDouble(),
                    height: banner.size.height.toDouble(),
                    child: AdWidget(ad: banner),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
