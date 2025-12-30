import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/prompt.dart';

class PromptRepository {
  final String assetPath;

  const PromptRepository({this.assetPath = 'assets/prompts/prompts.json'});

  Future<List<Prompt>> loadAllPrompts() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw FormatException('Prompts JSON must be a list');
    }

    return decoded
        .map((e) => Prompt.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }
}
