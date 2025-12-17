import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

import 'package:local_text_sync/config/defaults.dart';
import 'package:local_text_sync/features/sync/models/server_data_model.dart';

class SyncServer {
  final Stream<ServerData> stream;
  final String address;

  final StreamController<ServerData> _controller;
  final HttpServer _server;
  final Set<WebSocket> clients;

  SyncServer._(
    this._server,
    this._controller,
    this.address,
    this.clients,
  ) : stream = _controller.stream;

  /// Останавливаем сервер и закрываем все подключения
  Future<void> stop() async {
    for (final c in clients) {
      await c.close();
    }
    await _server.close(force: true);
    await _controller.close();
  }
}

/// Запускает локальный сервер с WebSocket
Future<SyncServer> startServer({
  String htmlTemplatePath = '',
  int port = 8080,
  Logger? externalLogger,
}) async {
  final log = StringBuffer();
  final host = InternetAddress.anyIPv4;

  log.writeln('host: $host');

  final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  log.writeln('--- Interfaces');
  for (final iface in interfaces) {
    log.writeln('Interface: ${iface.name}');
    for (final addr in iface.addresses) {
      log.writeln('  Address: ${addr.address} (тип: ${addr.type})');
    }
  }
  log.writeln('---');

  final localIp = _chooseRealLocalIp(interfaces, log) ?? '0.0.0.0';
  log.writeln('localIp: $localIp');

  // HTML-шаблон
  String htmlTemplate;
  try {
    htmlTemplate = await rootBundle.loadString(htmlTemplatePath);
  } catch (e) {
    htmlTemplate = defaultFailSafeHtmlTemplate;
    externalLogger?.w('Use fail safe template: $e');
  }

  final html = htmlTemplate
      .replaceAll('{{HOST}}', localIp)
      .replaceAll('{{PORT}}', port.toString());

  externalLogger?.d(log.toString());

  final controller = StreamController<ServerData>.broadcast();
  final server = await HttpServer.bind(host, port);
  final clients = <WebSocket>{};
  final address = 'http://$localIp:$port (ws://$localIp:$port/ws)';
  externalLogger?.i('Server running on $address');

  server.listen((HttpRequest req) async {
    try {
      // WebSocket endpoint
      if (req.uri.path == '/ws' && WebSocketTransformer.isUpgradeRequest(req)) {
        final socket = await WebSocketTransformer.upgrade(req);
        clients.add(socket);
        externalLogger?.i('WebSocket client connected');

        socket.listen(
          (message) {
            final data = json.decode(message);
            final serverData = ServerData()..text = data['text'] ?? '';
            final dataLength = serverData.text.length;

            // Если данные не удалось преобразовать в текст - логируем исходный объект.
            // Если удалось - логируем только размер текста.
            externalLogger?.d(
              'WS received '
              '${serverData.text.isEmpty ? data.toString() : dataLength}'
            );
            
            // Отправляем в поток приложения
            controller.add(serverData);

            // Рассылаем всем подключенным клиентам
            final payload = json.encode({'type': 'sync', 'text': serverData.text});
            for (final c in clients) {
              c.add(payload);
            }
          },
          onDone: () {
            clients.remove(socket);
            externalLogger?.i('WebSocket client disconnected');
          },
          onError: (e) {
            clients.remove(socket);
            externalLogger?.w('WebSocket error: $e');
          },
        );

        return;
      }

      // HTTP GET: отдаём HTML
      if (req.method == 'GET') {
        req.response
          ..headers.contentType = ContentType.html
          ..write(html);
      } else {
        req.response.statusCode = HttpStatus.notFound;
        externalLogger?.w('Unsupported HTTP method: ${req.method}');
      }
    } catch (e, st) {
      req.response.statusCode = HttpStatus.internalServerError;
      req.response.write('Error: $e\n$st');
      externalLogger?.e('Internal Server Error: $e\n$st');
    } finally {
      await req.response.close();
    }
  });

  return SyncServer._(server, controller, address, clients);
}

/// Выбираем реальный локальный IP (не loopback, не виртуальные)
String? _chooseRealLocalIp(List<NetworkInterface> interfaces, StringBuffer log) {
  for (final iface in interfaces) {
    final name = iface.name.toLowerCase();
    log.writeln('Looking at interface $name');

    if (name.contains('virtual') ||
        name.contains('vm') ||
        name.contains('docker') ||
        name.contains('hyper') ||
        name.contains('vpn') ||
        name.contains('wg') ||
        name.contains('tap') ||
        name.contains('vbox') ||
        name.contains('wsl')) {
      log.writeln('Interface Rejected.');
      continue;
    }

    if (name.contains('wi-fi') ||
        name.contains('беспроводная сеть') ||
        name.contains('wifi') ||
        name.contains('wlan') ||
        name.contains('ethernet') ||
        name.contains('eth')) {
      log.writeln('Interface accepted.');
      final ip = iface.addresses.first.address;
      if (!ip.startsWith('127.')) return ip;
    }
  }
  log.writeln('No interface choosed.');
  return null;
}
