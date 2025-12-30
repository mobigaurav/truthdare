import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/premium_providers.dart';
import '../../data/models/prompt.dart';
import '../../data/providers/prompt_providers.dart';

enum CouplesCategory { romantic, deep, fun, spicy }

class CouplesState {
  final CouplesCategory category;
  final PromptType selectedType; // truth/dare
  final Prompt? currentPrompt;

  final int shownCount;
  final int streak; // increments on "Done", resets on "Skip"

  const CouplesState({
    required this.category,
    required this.selectedType,
    required this.currentPrompt,
    required this.shownCount,
    required this.streak,
  });

  static CouplesState initial() => const CouplesState(
    category: CouplesCategory.romantic,
    selectedType: PromptType.truth,
    currentPrompt: null,
    shownCount: 0,
    streak: 0,
  );

  CouplesState copyWith({
    CouplesCategory? category,
    PromptType? selectedType,
    Prompt? currentPrompt,
    int? shownCount,
    int? streak,
  }) {
    return CouplesState(
      category: category ?? this.category,
      selectedType: selectedType ?? this.selectedType,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      shownCount: shownCount ?? this.shownCount,
      streak: streak ?? this.streak,
    );
  }
}

class CouplesController extends StateNotifier<CouplesState> {
  CouplesController(this._ref) : super(CouplesState.initial()) {
    _ref.listen<AsyncValue<List<Prompt>>>(allPromptsProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (state.currentPrompt == null) {
            nextPrompt(forceRebuild: true);
          }
        },
      );
    }, fireImmediately: true);
  }

  final Ref _ref;
  final _rng = Random();

  List<Prompt> _queue = [];
  int _queueIndex = 0;

  // Future<void> _initIfPossible() async {
  //   final async = _ref.read(allPromptsProvider);
  //   async.whenData((_) {
  //     if (state.currentPrompt == null) {
  //       nextPrompt();
  //     }
  //   });
  // }

  bool _isUnlocked() {
    final premium = _ref.read(premiumControllerProvider);
    return premium.isPremium;
  }

  List<Prompt> _filteredCouplesPrompts(List<Prompt> all) {
    final categoryStr = state.category.name; // romantic/deep/fun/spicy
    return all
        .where((p) => p.mode == GameMode.couples)
        .where((p) => p.type == state.selectedType)
        .where((p) => p.level == categoryStr)
        .toList(growable: false);
  }

  void _rebuildQueue(List<Prompt> all) {
    final items = _filteredCouplesPrompts(all);
    if (items.isEmpty) {
      _queue = [];
      _queueIndex = 0;
      return;
    }
    final shuffled = items.toList(growable: false);
    shuffled.shuffle(_rng);
    _queue = shuffled;
    _queueIndex = 0;
  }

  void setCategory(CouplesCategory c) {
    if (c == state.category) return;
    state = state.copyWith(category: c, currentPrompt: null);
    nextPrompt(forceRebuild: true);
  }

  void setType(PromptType type) {
    if (type == state.selectedType) return;
    state = state.copyWith(selectedType: type, currentPrompt: null);
    nextPrompt(forceRebuild: true);
  }

  void nextPrompt({bool forceRebuild = false}) {
    if (!_isUnlocked()) {
      // Locked: do nothing. UI overlays lock anyway.
      return;
    }

    final async = _ref.read(allPromptsProvider);

    async.when(
      loading: () {},
      error: (_, __) {},
      data: (all) {
        if (forceRebuild || _queue.isEmpty) {
          _rebuildQueue(all);
        }

        if (_queue.isEmpty) {
          state = state.copyWith(currentPrompt: null);
          return;
        }

        if (_queueIndex >= _queue.length) {
          _rebuildQueue(all);
        }

        final prompt = _queue[_queueIndex];
        _queueIndex++;

        state = state.copyWith(
          currentPrompt: prompt,
          shownCount: state.shownCount + 1,
        );
      },
    );
  }

  void done() {
    if (!_isUnlocked()) return;
    state = state.copyWith(streak: state.streak + 1);
    nextPrompt();
  }

  void skip() {
    if (!_isUnlocked()) return;
    state = state.copyWith(streak: 0);
    nextPrompt();
  }
}

// Provider
final couplesControllerProvider =
    StateNotifierProvider<CouplesController, CouplesState>((ref) {
      return CouplesController(ref);
    });
