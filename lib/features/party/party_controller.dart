import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/prompt.dart';
import '../../data/providers/prompt_providers.dart';
import '../../core/services/ads_providers.dart';
import '../../core/services/premium_providers.dart';

enum PartyFilterLevel { clean, fun, spicy }

class PartyState {
  final PromptType selectedType; // truth or dare
  final PartyFilterLevel selectedLevel; // clean/fun/spicy
  final Prompt? currentPrompt;

  /// How many prompts have been shown (useful later for interstitial cadence)
  final int shownCount;

  const PartyState({
    required this.selectedType,
    required this.selectedLevel,
    required this.currentPrompt,
    required this.shownCount,
  });

  PartyState copyWith({
    PromptType? selectedType,
    PartyFilterLevel? selectedLevel,
    Prompt? currentPrompt,
    int? shownCount,
  }) {
    return PartyState(
      selectedType: selectedType ?? this.selectedType,
      selectedLevel: selectedLevel ?? this.selectedLevel,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      shownCount: shownCount ?? this.shownCount,
    );
  }

  static PartyState initial() => const PartyState(
    selectedType: PromptType.truth,
    selectedLevel: PartyFilterLevel.fun,
    currentPrompt: null,
    shownCount: 0,
  );
}

class PartyController extends StateNotifier<PartyState> {
  PartyController(this._ref) : super(PartyState.initial()) {
    // Seed first prompt when data becomes available
    _ref.listen<AsyncValue<List<Prompt>>>(
      allPromptsProvider,
      (prev, next) {
        next.whenOrNull(
          data: (_) {
            if (state.currentPrompt == null) {
              nextPrompt(forceRebuild: true);
            }
          },
        );
      },
      fireImmediately:
          true, // important: handles cases where data is already ready
    );
  }

  final Ref _ref;
  final _rng = Random();

  // Queue for no-repeat behavior
  List<Prompt> _queue = [];
  int _queueIndex = 0;

  // Future<void> _initIfPossible() async {
  //   final async = _ref.read(allPromptsProvider);
  //   async.whenData((_) {
  //     // once prompts are loaded, pick first prompt
  //     if (state.currentPrompt == null) {
  //       nextPrompt();
  //     }
  //   });
  // }

  List<Prompt> _filteredPartyPrompts(List<Prompt> all) {
    final levelStr = state.selectedLevel.name; // "clean" | "fun" | "spicy"
    return all
        .where((p) => p.mode == GameMode.party)
        .where((p) => p.type == state.selectedType)
        .where((p) => p.level == levelStr)
        .toList(growable: false);
  }

  void _rebuildQueue(List<Prompt> all) {
    final items = _filteredPartyPrompts(all);

    // If empty, keep queue empty
    if (items.isEmpty) {
      _queue = [];
      _queueIndex = 0;
      return;
    }

    // Shuffle for no-repeat until exhausted
    final shuffled = items.toList(growable: false);
    shuffled.shuffle(_rng);

    _queue = shuffled;
    _queueIndex = 0;
  }

  void setType(PromptType type) {
    if (type == state.selectedType) return;
    state = state.copyWith(selectedType: type, currentPrompt: null);
    nextPrompt(forceRebuild: true);
  }

  void setLevel(PartyFilterLevel level) {
    if (level == state.selectedLevel) return;
    state = state.copyWith(selectedLevel: level, currentPrompt: null);
    nextPrompt(forceRebuild: true);
  }

  void nextPrompt({bool forceRebuild = false}) {
    final async = _ref.read(allPromptsProvider);

    async.when(
      loading: () {
        // Do nothing — UI can show loading spinner
      },
      error: (e, st) {
        // Do nothing here — UI handles error
      },
      data: (all) {
        if (forceRebuild || _queue.isEmpty) {
          _rebuildQueue(all);
        } else {
          // If the current queue no longer matches filters (rare), rebuild
          // This is a safe-guard in case JSON changes or state drift happens.
          final shouldMatch = _filteredPartyPrompts(all);
          if (shouldMatch.isEmpty) {
            _queue = [];
            _queueIndex = 0;
          }
        }

        if (_queue.isEmpty) {
          state = state.copyWith(currentPrompt: null);
          return;
        }

        // If exhausted, reshuffle (no repeats within a cycle)
        if (_queueIndex >= _queue.length) {
          _rebuildQueue(all);
        }

        final prompt = _queue[_queueIndex];
        _queueIndex++;

        final newCount = state.shownCount + 1;

        state = state.copyWith(currentPrompt: prompt, shownCount: newCount);

        // Show interstitial every 5 prompts (free users only)
        final premium = _ref.read(premiumControllerProvider);
        if (!premium.isPremium && newCount % 5 == 0) {
          final ads = _ref.read(adsServiceProvider);
          // Ensure preloaded
          ads.preloadInterstitial();
          // Try showing
          ads.showInterstitialIfReady();
        }
      },
    );
  }

  /// Skip is same as next for now (later you can track skips separately)
  void skip() => nextPrompt();
}

// Provider
final partyControllerProvider =
    StateNotifierProvider<PartyController, PartyState>((ref) {
      return PartyController(ref);
    });
