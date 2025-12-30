import 'package:flutter/foundation.dart';

@immutable
class Player {
  final String id;
  final String name;

  const Player({required this.id, required this.name});

  factory Player.create(String name) {
    final trimmed = name.trim();
    return Player(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory Player.fromJson(Map<String, dynamic> json) =>
      Player(id: json['id'] as String, name: json['name'] as String);
}
