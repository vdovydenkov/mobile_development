import 'dart:async';
import 'package:flutter/material.dart';

import 'package:local_text_sync/features/sync/services/sync_service.dart';
import 'package:local_text_sync/features/sync/models/sync_data_model.dart';

class SyncState extends ChangeNotifier {
  // Сюда пойдут данные для UI
  String     _latestText = '';
  DataSource _source     = DataSource.empty;
  DateTime   _updatedAt  = DateTime.now();
  String     _status     = '';
  String     _serverInfo = '';

  // Сервисный слой
  final SyncService _service;
  // Основной поток из сервиса
  late StreamSubscription<SyncData> _subscription;

  // Геттеры
  String     get latestText => _latestText;
  DataSource get source     => _source;
  DateTime   get updatedAt  => _updatedAt;
  String     get status     => _status;
  String     get serverInfo => _serverInfo;

  // Сервис передается в конструктор через параметр
  SyncState(this._service) {
    // Подписываемся на данные из сервиса
    _subscription = _service.dataStream.listen((data) {
      // Разбираем источник
      if (data.source == DataSource.serverInfo) {
        _serverInfo = '* ${data.text}';
      } else {
        // Обновляем свойства
        _latestText = data.text;
        _source     = data.source;
        _updatedAt  = data.updatedAt;
        _status     = _source.name;
      }

      // Передаем в UI
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _service.dispose();
    super.dispose();
  }
}