import 'package:flutter/foundation.dart';

enum GameMode { party, couples }

enum PromptType { truth, dare }

// Party levels
enum PartyLevel { clean, fun, spicy }

// Couples levels (you can expand later)
enum CouplesLevel { romantic, deep, fun, spicy }

@immutable
class Prompt {
  final String id;
  final GameMode mode;
  final PromptType type;

  /// Raw level value from JSON (e.g. clean/fun/spicy/romantic/deep)
  /// We keep it as String so we can support different level sets per mode.
  final String level;

  final String text;

  const Prompt({
    required this.id,
    required this.mode,
    required this.type,
    required this.level,
    required this.text,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    final modeStr = (json['mode'] as String).trim().toLowerCase();
    final typeStr = (json['type'] as String).trim().toLowerCase();

    return Prompt(
      id: (json['id'] as String).trim(),
      mode: _parseMode(modeStr),
      type: _parseType(typeStr),
      level: (json['level'] as String).trim().toLowerCase(),
      text: (json['text'] as String).trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mode': describeEnum(mode),
    'type': describeEnum(type),
    'level': level,
    'text': text,
  };

  static GameMode _parseMode(String v) {
    switch (v) {
      case 'party':
        return GameMode.party;
      case 'couples':
        return GameMode.couples;
      default:
        throw FormatException('Unknown mode: $v');
    }
  }

  static PromptType _parseType(String v) {
    switch (v) {
      case 'truth':
        return PromptType.truth;
      case 'dare':
        return PromptType.dare;
      default:
        throw FormatException('Unknown type: $v');
    }
  }
}
