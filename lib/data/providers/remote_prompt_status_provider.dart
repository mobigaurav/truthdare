import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/remote_prompt_repository.dart';
import '../../data/providers/prompt_providers.dart';

final remotePromptUpdatedAtProvider = FutureProvider<String?>((ref) async {
  final repo = ref.read(remotePromptRepoProvider);
  return repo.getCachedUpdatedAt();
});
