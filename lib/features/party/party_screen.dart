import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truth_dare/core/telemetry/app_analytics.dart';

import '../../data/models/prompt.dart';
import '../../data/providers/prompt_providers.dart';
import '../../widgets/prompt_card.dart';

import '../daily/daily_prompt_provider.dart';
import '../favorites/favorites_controller.dart';
import '../players/players_controller.dart';
import '../players/players_sheet.dart';
import 'party_controller.dart';

class PartyScreen extends ConsumerStatefulWidget {
  const PartyScreen({super.key});

  @override
  ConsumerState<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends ConsumerState<PartyScreen> {
  ProviderSubscription<AsyncValue<List<Prompt>>>? _promptsSub;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();

    // Log screen once (avoid spamming in build)
    Future.microtask(() => AppAnalytics.screen('party'));

    void maybeSeed(AsyncValue<List<Prompt>> async) {
      async.whenOrNull(
        data: (_) {
          if (_seeded) return;

          final partyState = ref.read(partyControllerProvider);
          if (partyState.currentPrompt == null) {
            _seeded = true;
            ref
                .read(partyControllerProvider.notifier)
                .nextPrompt(forceRebuild: true);
          }
        },
      );
    }

    // Run once immediately (since fireImmediately isn't available)
    maybeSeed(ref.read(allPromptsProvider));

    // Subscribe safely (initState-friendly)
    _promptsSub = ref.listenManual<AsyncValue<List<Prompt>>>(
      allPromptsProvider,
      (prev, next) => maybeSeed(next),
    );
  }

  @override
  void dispose() {
    _promptsSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promptsAsync = ref.watch(allPromptsProvider);

    final state = ref.watch(partyControllerProvider);
    final controller = ref.read(partyControllerProvider.notifier);

    final playersState = ref.watch(playersControllerProvider);
    final playersCtrl = ref.read(playersControllerProvider.notifier);

    final favs = ref.watch(favoritesProvider);
    final favCtrl = ref.read(favoritesProvider.notifier);

    final currentPlayerName = playersState.currentPlayer?.name;
    final currentPrompt = state.currentPrompt;
    final currentPromptId = currentPrompt?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Party'),
        actions: [
          IconButton(
            tooltip: 'Daily Prompt',
            icon: const Icon(Icons.star_outline),
            onPressed: () {
              HapticFeedback.selectionClick();
              AppAnalytics.tab('daily_party_open');

              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const _PartyDailyPromptSheet(),
              );
            },
          ),
          IconButton(
            tooltip: 'Players',
            icon: const Icon(Icons.group),
            onPressed: () {
              HapticFeedback.selectionClick();
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const PlayersSheet(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'Shown: ${state.shownCount}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: promptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading prompts:\n$e'),
          ),
        ),
        data: (_) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                if (currentPlayerName != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Turn: $currentPlayerName',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                _TypeToggle(
                  selected: state.selectedType,
                  onSelect: (t) {
                    HapticFeedback.selectionClick();
                    controller.setType(t);
                  },
                ),
                const SizedBox(height: 10),
                _LevelFilters(
                  selected: state.selectedLevel,
                  onSelect: (lvl) {
                    HapticFeedback.selectionClick();
                    controller.setLevel(lvl);
                  },
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: Center(
                    child: currentPrompt == null
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
                                            favs.contains(currentPromptId))
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                  ),
                                  onPressed: () {
                                    if (currentPromptId == null) return;
                                    HapticFeedback.lightImpact();
                                    AppAnalytics.favoriteToggle('party');
                                    favCtrl.toggle(currentPromptId);
                                  },
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
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
                                  title: currentPrompt.type.name,
                                  text: currentPrompt.text,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          AppAnalytics.promptSkip('party');
                          playersCtrl.nextPlayer();
                          controller.skip();
                        },
                        icon: const Icon(Icons.fast_forward),
                        label: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          AppAnalytics.promptNext('party');
                          playersCtrl.nextPlayer();
                          controller.nextPrompt();
                        },
                        icon: const Icon(Icons.navigate_next),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),

                if (playersState.players.isEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Tip: Add players (top-right) to take turns automatically.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PartyDailyPromptSheet extends ConsumerWidget {
  const _PartyDailyPromptSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(dailyCountdownProvider);
    final dailyAsync = ref.watch(partyDailyPromptProvider);

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
                    const Icon(Icons.star),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Party Prompt',
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

class _TypeToggle extends StatelessWidget {
  final PromptType selected;
  final void Function(PromptType) onSelect;

  const _TypeToggle({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PromptType>(
      segments: const [
        ButtonSegment(value: PromptType.truth, label: Text('Truth')),
        ButtonSegment(value: PromptType.dare, label: Text('Dare')),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onSelect(s.first),
    );
  }
}

class _LevelFilters extends StatelessWidget {
  final PartyFilterLevel selected;
  final void Function(PartyFilterLevel) onSelect;

  const _LevelFilters({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: PartyFilterLevel.values.map((lvl) {
        return ChoiceChip(
          label: Text(lvl.name.toUpperCase()),
          selected: lvl == selected,
          onSelected: (_) => onSelect(lvl),
        );
      }).toList(),
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
          'No prompts found for this filter.\nTry a different level.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onTry, child: const Text('Try Again')),
      ],
    );
  }
}
