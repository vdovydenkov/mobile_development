import 'dart:async';
import 'dart:convert';

import 'package:local_text_sync/features/sync/server/sync_http_server.dart';
import 'package:local_text_sync/features/sync/models/server_data_model.dart';
import 'package:local_text_sync/features/sync/models/sync_data_model.dart';
import 'package:local_text_sync/config/configurator.dart';
import 'package:local_text_sync/core/logging/logging_service.dart';
import 'package:local_text_sync/features/sync/services/clipboard_service.dart';

class SyncService {
  // Храним конфигурацию, переданную в параметре конструктора
  final Config _cfg;
  // Сервис передали в параметре конструктора
  final LoggingService _log;

  // Сервис буфер обмена
  final _clipb = ClipboardService();

  // Серверный API
  // Сервер может не запуститься, поэтому nullable
  SyncServer? _server;
  // Адрес от сервера
  String _address = '';

  // Главный контроллер основного потока:
  // через него передаем данные от сервера и буфера обмена
  final _controller = StreamController<SyncData>.broadcast();

  // Главный поток этого контроллера
  Stream<SyncData> get dataStream => _controller.stream;

  // Слушатель сервера делаем nullable - непонятно, активируется ли сервер
  StreamSubscription<ServerData>? _serverSubscription;
  // Слушателя буфера обмена активируем в конструкторе
  late StreamSubscription<String> _clipbSubscription;

  // Сюда кладем самый последний текст
  String _latestText = '';
  
  // Показываем статус сервера наружу
  bool get isServerRunning => _server != null;
  // Показываем адрес
  String get address => _address;

  // Конструктор
  // Параметром передаем конфиг
  SyncService(this._cfg, this._log) {
    _clipbSubscription = _clipb.stream.listen(_onClipboard);
    LoggingService.prefix = 'SyncService';
  }
  
  // Асинхронно запускаем сервер
  Future<void> init() async {
    if (_server != null) {
      return;
    }

    _log.i('Try to start server.');
    try {
      _server = await startServer(
        htmlTemplatePath: _cfg.htmlTemplatePath,
        port:             _cfg.httpServerPort,
        externalLogger:   _log.logger,
      );
    } catch (e, st) {
      _log.f('Server start error: ${e.toString()}\n$st');
      // Отправляем текст ошибки в UI
      _emit('Ошибка сервера: ${e.toString()}', DataSource.serverInfo);
      return;
    }

    // Чтобы приземлить nullable свойство и избежать _server!
    final server = _server;
    // Сервер не запустился
    if (server == null) {
      _log.f('Something wrong: the server has not been activated. Send info to UI.');
      _emit('Сервер не запущен.', DataSource.serverInfo);
      return;
    }

    _serverSubscription = server.stream.listen(_onServer);
    _address = server.address;

    _log.i('Server is activated on address: $_address');

    // Отправляем адрес в SyncState
    _emit(_address, DataSource.serverInfo);
  }

  /// Рассылка текста по всем подключенным websocket-клиентам
  void _sendToWebClients(String payload) {
    // Приземляем _server, чтобы сделать non-nullable
    final server = _server;
    if (server == null) return;

    final jsontemplate = json.encode({
      'type': 'server-text',
      'text': payload
    });

    // Рассылаем по веб-клиентам
    for (final client in server.clients) {
      client.add(jsontemplate);
    }
  }

  // Сюда приходят данные из потока буфера обмена
  void _onClipboard(String textFromClipboard) {
    _latestText = textFromClipboard;
    _emit(textFromClipboard, DataSource.clipboard);
  }

  // Сюда приходят данные из серверного потока
  void _onServer(ServerData dataFromServer) {
    _log.d('_onServer: Data from server: ${dataFromServer.text}');
    _latestText = dataFromServer.text;
    _emit(dataFromServer.text, DataSource.server);
  }

  // ------- Для UI
  Future<void> pasteFromClipboard() async {
    await _clipb.pasteText();
  }

  Future<void> sendToClients() async {
    _sendToWebClients(_latestText);
  }

  void _emit(String text, DataSource source) {
    _controller.add(
      SyncData(
        text:   text,
        source: source,
      )
    );
  }

  // Останавливаем поток, сервис буфера обмена и сервер
  Future<void> dispose() async {
    await _clipbSubscription.cancel();
    await _serverSubscription?.cancel();

    // Чтобы застолбить nullable свойство и избежать _server!
    final server = _server;
    if (server != null) {
      await server.stop();
      _server = null;
    }

    await _controller.close();
    _clipb.dispose();
  }
}
