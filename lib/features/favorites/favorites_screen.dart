import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truth_dare/core/telemetry/app_analytics.dart' show AppAnalytics;

import '../../data/models/prompt.dart';
import '../../data/providers/prompt_providers.dart';
import '../../widgets/prompt_card.dart';
import 'favorites_controller.dart';

enum FavoritesFilter { all, party, couples }

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  FavoritesFilter _filter = FavoritesFilter.all;

  @override
  Widget build(BuildContext context) {
    AppAnalytics.screen('favorites');
    final favIds = ref.watch(favoritesProvider); // Set<String>
    final favCtrl = ref.read(favoritesProvider.notifier);
    final promptsAsync = ref.watch(allPromptsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: promptsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load prompts:\n$e'),
          ),
        ),
        data: (allPrompts) {
          // Join favorites -> prompt objects
          final byId = {for (final p in allPrompts) p.id: p};
          final favPrompts = favIds
              .map((id) => byId[id])
              .whereType<Prompt>()
              .toList(growable: false);

          final filtered = favPrompts
              .where((p) {
                switch (_filter) {
                  case FavoritesFilter.all:
                    return true;
                  case FavoritesFilter.party:
                    return p.mode == GameMode.party;
                  case FavoritesFilter.couples:
                    return p.mode == GameMode.couples;
                }
              })
              .toList(growable: false);

          // Sort: Couples first (optional), then Truth, then alphabetic text
          filtered.sort((a, b) {
            final modeRankA = a.mode == GameMode.couples ? 0 : 1;
            final modeRankB = b.mode == GameMode.couples ? 0 : 1;
            if (modeRankA != modeRankB) return modeRankA - modeRankB;

            final typeRankA = a.type == PromptType.truth ? 0 : 1;
            final typeRankB = b.type == PromptType.truth ? 0 : 1;
            if (typeRankA != typeRankB) return typeRankA - typeRankB;

            return a.text.compareTo(b.text);
          });

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                _FilterChips(
                  value: _filter,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = v);
                  },
                  counts: _Counts(
                    all: favPrompts.length,
                    party: favPrompts
                        .where((p) => p.mode == GameMode.party)
                        .length,
                    couples: favPrompts
                        .where((p) => p.mode == GameMode.couples)
                        .length,
                  ),
                ),
                const SizedBox(height: 12),

                if (filtered.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        favPrompts.isEmpty
                            ? 'No favorites yet.\nTap the heart on a prompt to save it.'
                            : 'No favorites in this filter.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = filtered[index];
                        final subtitle =
                            '${p.mode.name.toUpperCase()} • ${p.type.name.toUpperCase()} • ${(p.level).toUpperCase()}';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        subtitle,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelMedium,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove from favorites',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        favCtrl.toggle(p.id); // toggle removes
                                      },
                                    ),
                                  ],
                                ),
                                PromptCard(title: p.type.name, text: p.text),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Counts {
  final int all;
  final int party;
  final int couples;
  const _Counts({
    required this.all,
    required this.party,
    required this.couples,
  });
}

class _FilterChips extends StatelessWidget {
  final FavoritesFilter value;
  final ValueChanged<FavoritesFilter> onChanged;
  final _Counts counts;

  const _FilterChips({
    required this.value,
    required this.onChanged,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: Text('ALL (${counts.all})'),
          selected: value == FavoritesFilter.all,
          onSelected: (_) => onChanged(FavoritesFilter.all),
        ),
        ChoiceChip(
          label: Text('PARTY (${counts.party})'),
          selected: value == FavoritesFilter.party,
          onSelected: (_) => onChanged(FavoritesFilter.party),
        ),
        ChoiceChip(
          label: Text('COUPLES (${counts.couples})'),
          selected: value == FavoritesFilter.couples,
          onSelected: (_) => onChanged(FavoritesFilter.couples),
        ),
      ],
    );
  }
}
