import 'dart:async';

import 'package:flutter/services.dart';

/// Взаимодействие с буфером обмена
class ClipboardService {
  final _controller = StreamController<String>.broadcast();
  
  Stream<String> get stream => _controller.stream;

  ClipboardService();

  Future<void> pasteText() async {
    final buffer = await Clipboard.getData(Clipboard.kTextPlain);
    final text = buffer?.text;

    if (text != null && text.isNotEmpty) {
      _controller.add(text);
    }
  }

  void dispose() {
    _controller.close();
  }
}