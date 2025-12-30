import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/player.dart';

class PlayersState {
  final List<Player> players;
  final int currentIndex;

  const PlayersState({required this.players, required this.currentIndex});

  Player? get currentPlayer => players.isEmpty
      ? null
      : players[currentIndex.clamp(0, players.length - 1)];

  static const initial = PlayersState(players: [], currentIndex: 0);

  PlayersState copyWith({List<Player>? players, int? currentIndex}) {
    return PlayersState(
      players: players ?? this.players,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

final playersControllerProvider =
    StateNotifierProvider<PlayersController, PlayersState>((ref) {
      return PlayersController()..load();
    });

class PlayersController extends StateNotifier<PlayersState> {
  PlayersController() : super(PlayersState.initial);

  static const _key = 'party_players';
  final _rng = Random();

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return;

    final list = (jsonDecode(raw) as List)
        .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    state = state.copyWith(players: list, currentIndex: 0);
  }

  Future<void> _save(List<Player> players) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(
      _key,
      jsonEncode(players.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> addPlayer(String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    final updated = [...state.players, Player.create(n)];
    state = state.copyWith(players: updated, currentIndex: 0);
    await _save(updated);
  }

  Future<void> removePlayer(String id) async {
    final updated = state.players.where((p) => p.id != id).toList();
    state = state.copyWith(players: updated, currentIndex: 0);
    await _save(updated);
  }

  void nextPlayer() {
    if (state.players.isEmpty) return;
    final next = (state.currentIndex + 1) % state.players.length;
    state = state.copyWith(currentIndex: next);
  }

  void randomPlayer() {
    if (state.players.isEmpty) return;
    state = state.copyWith(currentIndex: _rng.nextInt(state.players.length));
  }
}
