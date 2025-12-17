import 'package:flutter/material.dart';
import 'package:local_text_sync/features/sync/services/sync_service.dart';
import 'package:local_text_sync/features/sync/state/sync_state.dart';
import 'package:provider/provider.dart';

const screenTitle = 'Local Text Sync';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  static const _tooltip = 'СИНХРОНИЗИРОВАННЫЙ ТЕКСТ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(screenTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(_tooltip),
            Text(
              // Вынимаем из провайдера слой state
              context.watch<SyncState>().latestText,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: context.read<SyncService>().pasteFromClipboard,
        tooltip: 'Paste',
        child: const Icon(Icons.add),
      ),

      // Статусная строка
      bottomNavigationBar: Container(
        height: 28,
        color: Colors.black12,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.watch<SyncState>().status,
              style: const TextStyle(fontSize: 14),
            ),
            Row(
              children: [
                Text(
                  context.watch<SyncState>().serverInfo,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
