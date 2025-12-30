import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/prompt.dart';
import '../../data/providers/prompt_providers.dart';
import 'daily_prompt_service.dart';

final dailyPromptServiceProvider = Provider((_) => DailyPromptService());

final partyDailyPromptProvider = FutureProvider<Prompt?>((ref) async {
  final prompts = await ref.watch(allPromptsProvider.future);
  final party = prompts.where((p) => p.mode == GameMode.party).toList();
  if (party.isEmpty) return null;

  final svc = ref.read(dailyPromptServiceProvider);
  const salt = "truth-dare-v1|party";
  final idx = svc.indexForToday(length: party.length, salt: salt);
  return party[idx];
});

final couplesDailyPromptProvider = FutureProvider<Prompt?>((ref) async {
  final prompts = await ref.watch(allPromptsProvider.future);
  final couples = prompts.where((p) => p.mode == GameMode.couples).toList();
  if (couples.isEmpty) return null;

  final svc = ref.read(dailyPromptServiceProvider);
  const salt = "truth-dare-v1|couples";
  final idx = svc.indexForToday(length: couples.length, salt: salt);
  return couples[idx];
});

final dailyCountdownProvider = Provider<String>((ref) {
  final svc = ref.read(dailyPromptServiceProvider);
  return svc.formatCountdown(svc.timeUntilNextUtcMidnight());
});
