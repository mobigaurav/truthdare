import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'players_controller.dart';

class PlayersSheet extends ConsumerStatefulWidget {
  const PlayersSheet({super.key});

  @override
  ConsumerState<PlayersSheet> createState() => _PlayersSheetState();
}

class _PlayersSheetState extends ConsumerState<PlayersSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playersControllerProvider);
    final ctrl = ref.read(playersControllerProvider.notifier);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Players', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Add player name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      await ctrl.addPlayer(_controller.text);
                      _controller.clear();
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.players.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Add players to take turns automatically.'),
                )
              else
                ...state.players.map(
                  (p) => ListTile(
                    title: Text(p.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ctrl.removePlayer(p.id),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
