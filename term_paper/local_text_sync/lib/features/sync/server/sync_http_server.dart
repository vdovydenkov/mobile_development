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

  SyncServer._(
    this._server,
    this._controller,
    this.address,
  ) : stream = _controller.stream;

  Future<void> stop() async {
    await _server.close(force: true);
    await _controller.close();
  }
} 

/// Запускает локальный HTTP-сервер
/// Возвращает `Stream<ServerData>` с данными для синхронизации
Future<SyncServer> startServer({
  // Параметры
  // Путь к HTML-шаблону
  String  htmlTemplatePath = '',
  // Порт по умолчанию
  int     port             = 8080,
  // Внешний логгер, необязательно
  Logger? externalLogger,
}) async {
  // Сюда собираем лог
  final log = StringBuffer();

  // Берём адрес
  final host = InternetAddress.anyIPv4;

  log.writeln('host: $host');

  final List<NetworkInterface> interfaces =
    await NetworkInterface.list(
      type: InternetAddressType.IPv4
    );

  log.writeln('--- Interfaces');
  for (final interface in interfaces) {
    log.writeln('Interface: ${interface.name}');
    for (final address in interface.addresses) {
      log.writeln('  Address: ${address.address} (тип: ${address.type})');
    }
  }
  log.writeln('---');
  
  final localIp = _chooseRealLocalIp(interfaces, log) ?? '0.0.0.0';

  log.writeln('localIp: $localIp');


  // Читаем HTML-шаблон
  String htmlTemplate;

  log.writeln('Try to load html template from: $htmlTemplatePath');

  try {
    htmlTemplate = await rootBundle.loadString(htmlTemplatePath);
  } catch (e) {
    log.writeln('Template loading error: $e');
    // Берем значение по умолчанию
    htmlTemplate = defaultFailSafeHtmlTemplate;
    log.writeln('Use a fail safe template from config.');
  }

  log.writeln('Raw html template length: ${htmlTemplate.length}');

  // Формируем страницу с подстановкой адреса и порта
  final html = htmlTemplate
      .replaceAll('{{HOST}}', localIp)
      .replaceAll('{{PORT}}', port.toString());
  log.writeln('html length: ${html.length}');
  
  // Собрали отладочный лог, выводим, если передали логгер
  externalLogger?.d(log.toString());
  
  // Контроллер для команд
  final controller = StreamController<ServerData>.broadcast();

  // Запускаем сервер
  final server = await HttpServer.bind(host, port);

  final address = 'http://$localIp:$port';
  externalLogger?.i('The app local server running on $address');

  // Обработка запросов
  server.listen((HttpRequest req) async {
    try {
      if (req.method == 'GET') {
        // Отдаём страницу
        req.response
          ..headers.contentType = ContentType.html
          ..write(html);
      } else if (req.method == 'POST' && req.uri.path == '/content') {
        // Может прийти в json или x-www-form-urlencoded
        final contentType = req.headers.contentType?.mimeType;
        final body = await utf8.decoder.bind(req).join();

        externalLogger?.d(
          'Server request:\n'
          '  contenttype: $contentType\n'
          '  Body: $body'
        );
        
        final serverData = ServerData();

        if (contentType == 'application/json') {
          final data = json.decode(body);

          externalLogger?.d(
            'application/json detected.'
            'data: ${data.toString()}'
          );

          serverData.text = data['syncText'] ?? data.toString();
        } else if (contentType == 'application/x-www-form-urlencoded') {
          final data = Uri.splitQueryString(body);
          serverData.text = data['content'] ?? data.toString();

          externalLogger?.d(
            'application/x-www-form-urlencoded detected.\n'
            'serverData.text: ${serverData.text}'
          );
        } else {
          req.response.statusCode = HttpStatus.unsupportedMediaType;
          externalLogger?.w('Server request contains a Unsupported Media Type: $contentType');
          return;
        }

        // Добавляем данные в поток
        controller.add(serverData);

        // Возвращаем подтверждение
        req.response
          ..headers.contentType = ContentType.text
          ..write('Synchronized.');
        externalLogger?.d('Response: OK.');
      } else {
        req.response.statusCode = HttpStatus.notFound;
        externalLogger?.w('Server request contains unsupported HTTP method.');
      }
    } catch (e, st) {
      req.response.statusCode = HttpStatus.internalServerError;
      req.response.write('Error: $e\n$st');
      externalLogger?.e('Internal Server Error: $e\n$st');
    } finally {
      await req.response.close();
    }
  });

  return SyncServer._(
    server,
    controller,
    address,
  );
}

String? _chooseRealLocalIp(List<NetworkInterface> interfaces, StringBuffer log) {
  for (final iface in interfaces) {
    final name = iface.name.toLowerCase();

    log.writeln('Looking at interface $name');
    // Отсекаем виртуальные, VPN, Docker, WSL
    if (name.contains('virtual') ||
        name.contains('vm') ||
        name.contains('docker') ||
        name.contains('hyper') ||
        name.contains('vpn') ||
        name.contains('wg') ||
        name.contains('tap') ||
        name.contains('vbox') ||
        name.contains('wsl'))
    {
      log.writeln('Interface Rejected.');
      continue;
    }

    // Оставляем "правильные" адаптеры
    if (name.contains('wi-fi') ||
        name.contains('беспроводная сеть') ||
        name.contains('wifi') ||
        name.contains('wlan') ||
        name.contains('ethernet') ||
        name.contains('eth')) 
    {
      log.writeln('Interface accepted.');
      final ip = iface.addresses.first.address;
      if (!ip.startsWith('127.')) {
        return ip;
      }
    }
  }
  log.writeln('No interface choosed.');
  return null;
}



