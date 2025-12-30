import 'dart:convert';

class DailyPromptService {
  // FNV-1a 32-bit hash
  int fnv1a32(String input) {
    const int fnvPrime = 0x01000193;
    const int offsetBasis = 0x811C9DC5;
    int hash = offsetBasis;
    final bytes = utf8.encode(input);
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  int indexForToday({
    required int length,
    required String salt,
    DateTime? nowUtc,
  }) {
    if (length <= 0) return 0;
    final now = (nowUtc ?? DateTime.now().toUtc());
    final dayKey =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final h = fnv1a32("$dayKey|$salt");
    return h % length;
  }

  Duration timeUntilNextUtcMidnight({DateTime? nowUtc}) {
    final now = (nowUtc ?? DateTime.now().toUtc());
    final next = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    return next.difference(now);
  }

  String formatCountdown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return "${h}h ${m}m";
  }
}
