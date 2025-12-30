import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/remote/remote_config_provider.dart';
import '../models/prompt.dart';
import '../repositories/remote_prompt_repository.dart';

final remotePromptRepoProvider = Provider<RemotePromptRepository>((ref) {
  return RemotePromptRepository();
});

final remoteConfigInitProvider = FutureProvider<void>((ref) async {
  final rc = ref.read(remoteConfigServiceProvider);
  await rc.init(); // idempotent
});

final _didRemoteRefreshProvider = StateProvider<bool>((ref) => false);

final allPromptsProvider = FutureProvider<List<Prompt>>((ref) async {
  await ref.watch(remoteConfigInitProvider.future);

  final rc = ref.read(remoteConfigServiceProvider);
  final repo = ref.read(remotePromptRepoProvider);

  // 1) Load cached remote OR asset immediately
  final prompts = await repo.loadPromptsFromCacheOrAsset(
    assetPath: 'assets/prompts/prompts.json',
  );

  // 2) Background refresh only once per app session
  final didRefresh = ref.read(_didRemoteRefreshProvider);
  if (!didRefresh) {
    ref.read(_didRemoteRefreshProvider.notifier).state = true;

    final url = rc.remotePromptsUrl.trim();
    if (url.isNotEmpty) {
      // ignore: unawaited_futures
      repo.fetchAndCacheRemotePrompts(url).then((updated) {
        if (updated) ref.invalidateSelf();
      });
    }
  }

  return prompts;
});
