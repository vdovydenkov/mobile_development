// lib/config/configurator.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:local_text_sync/config/defaults.dart';

class Config extends ChangeNotifier {
  // Позже финально инициализируем в конструкторе
  late final SharedPreferencesAsync _prefs;

  // Метка загрузки
  bool _loading = false;
  
  // Вход в приложение без аккаунта
  bool _guestMode = defaultGuestMode;

  Config() : _prefs = SharedPreferencesAsync();

  // Простые геттеры
  bool   get guestMode => _guestMode;
  bool   get loading => _loading;

  // Значения пока из констант
  // Минимальный HTML-шаблон для локального http-сервера
  String get failSafeHtmlTemplate => defaultFailSafeHtmlTemplate;
  String get htmlTemplatePath     => defaultHtmlTemplatePath;
  int    get httpServerPort       => defaultHttpServerPort;

  /// Если значение обновляется - сообщаем всем желающим и сохраняем.
  set guestMode(bool value) {
    if (value == _guestMode) return;

    _guestMode = value;
    notifyListeners();
    saveGuestMode();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final stored = await _prefs.getBool('guestMode');
    if (stored != null) _guestMode = stored;

    _loading = false;
    notifyListeners();
  }

  Future<void> saveGuestMode() async {
    await _prefs.setBool('guestMode', _guestMode);
  }

  Future<void> saveAll() async {
    await saveGuestMode();
  }
}

