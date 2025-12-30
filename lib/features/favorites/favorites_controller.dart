import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesController extends StateNotifier<Set<String>> {
  FavoritesController() : super(<String>{}) {
    load();
  }

  static const _key = 'favorite_prompt_ids';

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List).cast<String>();
    state = list.toSet();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(state.toList()));
  }

  Future<void> toggle(String promptId) async {
    final next = {...state};
    if (next.contains(promptId)) {
      next.remove(promptId);
    } else {
      next.add(promptId);
    }
    state = next;
    await _save();
  }

  bool isFav(String id) => state.contains(id);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesController, Set<String>>((ref) {
      return FavoritesController();
    });
