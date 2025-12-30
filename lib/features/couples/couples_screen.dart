import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truth_dare/core/telemetry/app_analytics.dart';

import '../../core/services/premium_providers.dart';
import '../../data/models/prompt.dart';
import '../../widgets/prompt_card.dart';

import '../daily/daily_prompt_provider.dart';
import '../favorites/favorites_controller.dart';
import 'couples_controller.dart';
import 'couples_telemetry_providers.dart';

class CouplesScreen extends ConsumerStatefulWidget {
  const CouplesScreen({super.key});

  @override
  ConsumerState<CouplesScreen> createState() => _CouplesScreenState();
}

class _CouplesScreenState extends ConsumerState<CouplesScreen> {
  ProviderSubscription? _premiumSub;

  @override
  void initState() {
    super.initState();

    // Log screen once
    Future.microtask(() => AppAnalytics.screen('couples'));

    void handlePremium(dynamic premium) {
      if (premium.isPremium) return;

      final alreadyLogged = ref.read(couplesPaywallLoggedProvider);
      if (alreadyLogged) return;

      // ✅ Delay provider write until after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Re-check (in case premium flipped quickly)
        final p = ref.read(premiumControllerProvider);
        final logged = ref.read(couplesPaywallLoggedProvider);
        if (p.isPremium || logged) return;

        ref.read(couplesPaywallLoggedProvider.notifier).state = true;
        AppAnalytics.paywallShown('couples_tab');
      });
    }

    // Run once immediately (no fireImmediately in your version)
    handlePremium(ref.read(premiumControllerProvider));

    // Subscribe safely in initState
    _premiumSub = ref.listenManual(
      premiumControllerProvider,
      (prev, next) => handlePremium(next),
    );
  }

  @override
  void dispose() {
    _premiumSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final premium = ref.watch(premiumControllerProvider);
    final premiumController = ref.read(premiumControllerProvider.notifier);

    final state = ref.watch(couplesControllerProvider);
    final controller = ref.read(couplesControllerProvider.notifier);

    final favs = ref.watch(favoritesProvider);
    final favCtrl = ref.read(favoritesProvider.notifier);

    final currentPrompt = state.currentPrompt;
    final currentPromptId = currentPrompt?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Couples'),
        actions: [
          IconButton(
            tooltip: 'Daily Prompt',
            icon: const Icon(Icons.favorite_outline),
            onPressed: () {
              HapticFeedback.selectionClick();

              if (!premium.isPremium) {
                AppAnalytics.paywallShown('daily_couples_appbar');
                premiumController.buyPremium();
                return;
              }

              AppAnalytics.tab('daily_couples_open');
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const _CouplesDailyPromptSheet(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'Streak: ${state.streak}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _CouplesCategoryChips(
                  selected: state.category,
                  enabled: premium.isPremium,
                  onSelect: (c) {
                    HapticFeedback.selectionClick();
                    controller.setCategory(c);
                  },
                ),
                const SizedBox(height: 10),
                _TypeToggle(
                  selected: state.selectedType,
                  enabled: premium.isPremium,
                  onSelect: (t) {
                    HapticFeedback.selectionClick();
                    controller.setType(t);
                  },
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: Center(
                    child: !premium.isPremium
                        ? const PromptCard(
                            title: 'Locked',
                            text: 'Unlock Premium to play Couples Mode.',
                          )
                        : (currentPrompt == null
                              ? _EmptyState(
                                  onTry: () {
                                    HapticFeedback.mediumImpact();
                                    controller.nextPrompt(forceRebuild: true);
                                  },
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        tooltip: 'Favorite',
                                        icon: Icon(
                                          (currentPromptId != null &&
                                                  favs.contains(
                                                    currentPromptId,
                                                  ))
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                        ),
                                        onPressed: () {
                                          if (currentPromptId == null) return;
                                          HapticFeedback.lightImpact();
                                          AppAnalytics.favoriteToggle(
                                            'couples',
                                          );
                                          favCtrl.toggle(currentPromptId);
                                        },
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      transitionBuilder: (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: PromptCard(
                                        key: ValueKey(currentPrompt.id),
                                        title:
                                            '${state.selectedType.name} • ${state.category.name}',
                                        text: currentPrompt.text,
                                      ),
                                    ),
                                  ],
                                )),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: premium.isPremium
                            ? () {
                                HapticFeedback.selectionClick();
                                AppAnalytics.promptSkip('couples');
                                controller.skip();
                              }
                            : null,
                        icon: const Icon(Icons.fast_forward),
                        label: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: premium.isPremium
                            ? () {
                                HapticFeedback.mediumImpact();
                                AppAnalytics.promptNext('couples');
                                controller.done();
                              }
                            : null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!premium.isPremium)
            _PremiumLockOverlay(
              isIapAvailable: premium.isIapAvailable,
              isLoading: premium.isLoading,
              errorMessage: premium.errorMessage,
              onUnlock: () {
                HapticFeedback.mediumImpact();
                AppAnalytics.paywallShown('couples_overlay_unlock');
                premiumController.buyPremium();
              },
              onRestore: () {
                HapticFeedback.selectionClick();
                premiumController.restore();
              },
            ),
        ],
      ),
    );
  }
}

class _CouplesDailyPromptSheet extends ConsumerWidget {
  const _CouplesDailyPromptSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(dailyCountdownProvider);
    final dailyAsync = ref.watch(couplesDailyPromptProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: dailyAsync.when(
          loading: () => const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Daily prompt error:\n$e'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
          data: (p) {
            if (p == null) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No daily prompt available.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Couples Prompt',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      'New in $countdown',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PromptCard(
                  title: '${p.type.name} • ${p.level.toUpperCase()}',
                  text: p.text,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CouplesCategoryChips extends StatelessWidget {
  final CouplesCategory selected;
  final void Function(CouplesCategory) onSelect;
  final bool enabled;

  const _CouplesCategoryChips({
    required this.selected,
    required this.onSelect,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: CouplesCategory.values.map((c) {
        return ChoiceChip(
          label: Text(c.name.toUpperCase()),
          selected: c == selected,
          onSelected: enabled ? (_) => onSelect(c) : null,
        );
      }).toList(),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final PromptType selected;
  final void Function(PromptType) onSelect;
  final bool enabled;

  const _TypeToggle({
    required this.selected,
    required this.onSelect,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PromptType>(
      segments: const [
        ButtonSegment(value: PromptType.truth, label: Text('Truth')),
        ButtonSegment(value: PromptType.dare, label: Text('Dare')),
      ],
      selected: {selected},
      onSelectionChanged: enabled ? (s) => onSelect(s.first) : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTry;

  const _EmptyState({required this.onTry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 36),
        const SizedBox(height: 10),
        Text(
          'No prompts found for this category.\nTry another one.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onTry, child: const Text('Try Again')),
      ],
    );
  }
}

class _PremiumLockOverlay extends StatelessWidget {
  final bool isIapAvailable;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onUnlock;
  final VoidCallback onRestore;

  const _PremiumLockOverlay({
    required this.isIapAvailable,
    required this.isLoading,
    required this.errorMessage,
    required this.onUnlock,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Unlock Couples Mode ❤️',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Couples prompts + remove ads.\nOne-time purchase. Lifetime access.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    )
                  else if (!isIapAvailable)
                    Text(
                      'In-app purchases are not available right now.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    FilledButton(
                      onPressed: onUnlock,
                      child: const Text('Unlock for \$4.99 • Lifetime'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onRestore,
                      child: const Text('Restore Purchase'),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
