import 'dart:async';
import 'dart:convert';
import 'dart:collection';

import 'package:local_text_sync/features/sync/server/sync_http_server.dart';
import 'package:local_text_sync/features/sync/models/server_data_model.dart';
import 'package:local_text_sync/features/sync/models/sync_data_model.dart';
import 'package:local_text_sync/config/configurator.dart';
import 'package:local_text_sync/core/logging/logging_service.dart';

class SyncService {
  // --- Внешние свойства

  // Поток главного сервисного контроллера: через него идут все сообщения
  Stream<SyncData> get dataStream => _controller.stream;

  // Статус сервера
  bool get isServerRunning => _server != null;
  // Адрес сервера
  String get address => _address;

  // --- Геттеры очереди текстов сервера
  // Размер очереди (сколько в ней текстов)
  int get queueLength => _queueText.length;

  // --- Внутренние свойства

  // --- Параметры конструктора
  // Храним конфигурацию, переданную в параметре конструктора
  final Config _cfg;
  // Сервис логгера — тоже передали в параметре конструктора
  final LoggingService _log;

  // --- Серверный API
  // Сервер может не запуститься, поэтому nullable
  SyncServer? _server;
  // Адрес от сервера
  String _address = '';

  // Главный сервисный контроллер потока:
  // через него передаем данные от сервера и буфера обмена
  final _controller = StreamController<SyncData>.broadcast();

  // Слушатель сервера делаем nullable - непонятно, активируется ли сервер
  StreamSubscription<ServerData>? _serverSubscription;
  // Слушатель буфера обмена активируем в конструкторе, поэтому late
  late StreamSubscription<String> _clipbSubscription;

  // В очередь собираем все тексты от сервера — отдаем по запросу
  final _queueText = Queue<String>();
  
  // Конструктор
  // Параметром передаем конфиг и логгер
  SyncService(this._cfg, this._log) {
    LoggingService.prefix = 'SyncService';
  }
  
  /// Асинхронно запускаем сервер
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

  // --- Для UI
  // Нажали "Отправить" - рассылаем текст по веб-клиентам
  void onSendPressed(String text) {
    _sendToWeb(text);
  }

  // Нажали "Принять" - отдаем в поток текст из очереди, если есть
  void onRetrievePressed() {
    if (_queueText.isEmpty) return;

    // Отправляем в поток и удаляем текст из очереди
    _emit(
      _queueText.removeFirst(),
      DataSource.server,
    );
  }

  /// Останавливаем поток и сервер
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
  }

  // Рассылка текста по всем подключенным websocket-клиентам
  void _sendToWeb(String text) {
    // Приземляем _server, чтобы сделать non-nullable
    final server = _server;
    if (server == null) return;

    final jsontemplate = json.encode({
      'type': 'app-text',
      'text': text
    });

    // Рассылаем по веб-клиентам
    for (final client in server.clients) {
      client.add(jsontemplate);
    }
  }

  // Сюда приходят данные из серверного потока
  void _onServer(ServerData dataFromServer) {
    _log.d('_onServer: Data from server: ${dataFromServer.text.length} bytes.');
    _queueText.add(dataFromServer.text);
  }

  void _emit(String text, DataSource source) {
    _controller.add(
      SyncData(
        text:   text,
        source: source,
      )
    );
  }
}
