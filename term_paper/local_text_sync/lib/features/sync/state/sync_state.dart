import 'dart:async';
import 'package:flutter/material.dart';

import 'package:local_text_sync/features/sync/services/sync_service.dart';
import 'package:local_text_sync/features/sync/models/sync_data_model.dart';

class SyncState extends ChangeNotifier {
  // --- Публичные геттеры
  // Актуальный текст от сервера
  String     get latestText => _latestText;
  // Кто отправил информацию в поток
  DataSource get source     => _source;
  // Когда отправил
  DateTime   get updatedAt  => _updatedAt;
  // Короткая статусная информация
  String     get status     => _status;
  // Информация для расширенной части статусной строки
  String     get statusInfo => _statusInfo;
  // Информация от очереди текстов
  String     get queueInfo  => _queueInfo;

  // --- Приватные свойства
  String     _latestText = '';
  DataSource _source     = DataSource.empty;
  DateTime   _updatedAt  = DateTime.now();
  String     _status     = '';
  String     _statusInfo = '';
  String     _queueInfo  = '';

  // Сервисный слой
  final SyncService _service;
  // Основной поток из сервиса
  late StreamSubscription<SyncData> _subscription;

  // Сервис передается в конструктор через параметр
  SyncState(this._service) {
    // Подписываемся на данные из сервиса
    _subscription = _service.dataStream.listen((data) {
      // Разбираем источник
      if (data.source == DataSource.statusInfo) {
        // Обновилась статусная строка
        _statusInfo = '* ${data.text}';
      } else if (data.source == DataSource.queue) {
        // Обновилась очередь, актуализируем
        _queueInfo = data.text;
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