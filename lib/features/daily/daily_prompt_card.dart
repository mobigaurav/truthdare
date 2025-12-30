import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/prompt.dart';
import '../../widgets/prompt_card.dart';

class DailyPromptCard extends ConsumerWidget {
  final String title;
  final String countdownText;
  final AsyncValue<Prompt?> dailyAsync;
  final VoidCallback? onTap;

  const DailyPromptCard({
    super.key,
    required this.title,
    required this.countdownText,
    required this.dailyAsync,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: dailyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text("Daily prompt error: $e"),
            data: (prompt) {
              if (prompt == null) return Text("$title: No prompts available.");

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.today),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        "New in $countdownText",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PromptCard(
                    title:
                        "${prompt.type.name} • ${prompt.level.toUpperCase()}",
                    text: prompt.text,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
