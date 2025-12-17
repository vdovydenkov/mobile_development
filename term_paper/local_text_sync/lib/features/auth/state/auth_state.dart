// lib/features/auth/state/auth_state.dart

import 'package:flutter/foundation.dart';

import 'package:local_text_sync/features/auth/models/user_model.dart';
import 'package:local_text_sync/features/auth/services/auth_service.dart';

/// Центральное состояние авторизации.
///
/// Отвечает за:
/// - хранение текущего пользователя (или null, если гость)
/// - признак, что пользователь вошёл как гость
/// - обновление lastLoginAt
/// - уведомление UI через ChangeNotifier
class AuthState extends ChangeNotifier {
  // Текущий пользователь, если он вошёл под учётной записью.
  UserModel? _user;

  // Вспомогательные процедуры: экземпляр создадим в конструкторе
  late final AuthService _service;

  // Пометка гостя (вход без пароля)
  bool _isGuest = false;

  // Аутентификация прошла успешно
  bool _isAuthenticated = false;

  // Флаг загрузки
  bool _loading = false;

  /// Геттеры
  UserModel? get user => _user;
  bool get isGuest => _isGuest;
  bool get isAuthenticated => _isAuthenticated;
  bool get loading => _loading;

  /// Полная очистка состояния (выход из аккаунта или завершение гостевого режима)
  void logout() {
    _user = null;
    _isGuest = false;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// Вход под учётной записью.
  Future<void> login(UserModel user) async {
    _loading = true;
    notifyListeners();

    await _service.checkProfile();
    _user = user;

    // Обновляем время последнего входа (не меняем createdAt!)
    _user = _user!.copyWith(
      lastLoginAt: DateTime.now().toUtc(),
    );

    _isAuthenticated = true;

    _loading = false;
    notifyListeners();
  }

  /// Замена пользователя (например, после изменения пароля).
  void updateUser(UserModel updated) {
    _user = updated;
    notifyListeners();
  }
}
