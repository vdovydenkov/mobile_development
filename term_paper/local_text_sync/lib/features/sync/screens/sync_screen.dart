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

  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final latestText = context.watch<SyncState>().latestText;

    if (_textController.text != latestText) {
      _textController.text = latestText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncService = context.read<SyncService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(screenTitle),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(_tooltip),
            ),

            // Основное редактируемое текстовое поле
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _textController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ),

            // Кнопки "Отправить" и "Принять"
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        syncService.onSendPressed(_textController.text);
                      },
                      child: const Text('Отправить'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer<SyncState>(
                      builder: (context, state, _) {
                        final queueInfo = state.queueInfo;
                        final isEnabled = queueInfo.isNotEmpty;

                        return OutlinedButton(
                          onPressed: isEnabled
                              ? syncService.onRetrievePressed
                              : null,
                          child: Text(
                            isEnabled
                                ? 'Принять ($queueInfo)'
                                : 'Принять',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            Text(
              context.watch<SyncState>().statusInfo,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
