// lib/features/auth/models/user_model.dart

import 'dart:convert';

/// Модель локального пользователя.
/// Содержит набор полей для локальной аутентификации:
/// - login: имя пользователя
/// - passwordHash: хеш
/// - salt: соль, использованная при хешировании пароля
/// - createdAt: дата/время создания профиля (UTC)
///
class UserModel {
  /// Логин пользователя. Обязательное поле.
  final String login;

  /// Хеш
  final String passwordHash;

  /// Соль, использованная при хешировании.
  final String salt;

  /// Время создания профиля в UTC.
  final DateTime createdAt;

  /// Время последней успешной аутентификации
  final DateTime lastLoginAt;

  /// Конструктор. Все поля требуются.
  const UserModel({
    required this.login,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
    required this.lastLoginAt,
  });

  /// Создаёт копию модели с возможными заменами полей.
  UserModel copyWith({
    String? login,
    String? passwordHash,
    String? salt,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      login: login ?? this.login,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Преобразует модель в карту (Map), готовую к сериализации в JSON.
  /// Формат:
  /// {
  ///   "login": "ivan",
  ///   "passwordHash": "abcd...",
  ///   "salt": "random-salt",
  ///   "createdAt": "2025-11-21T19:00:00.000Z",
  ///   "lastLoginAt": "2025-11-21T19:00:00.000Z"
/// }
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'login': login,
      'passwordHash': passwordHash,
      'salt': salt,
      // Сохраняем дату в ISO-8601 формате в UTC, это удобно для межплатформенного хранения.
      'createdAt': createdAt.toUtc().toIso8601String(),
      'lastLoginAt': lastLoginAt,
    };
  }

  /// Создаёт модель из Map (например, распарсенного JSON).
  /// Ожидает, что `map['createdAt']` — ISO-8601 строка.
  factory UserModel.fromJson(Map<String, dynamic> map) {
    // Проверяем наличие полей — бросаем понятную ошибку, если что-то отсутствует.
    if (map['login'] == null) {
      throw FormatException('UserModel.fromJson: missing "login"');
    }
    if (map['passwordHash'] == null) {
      throw FormatException('UserModel.fromJson: missing "passwordHash"');
    }
    if (map['salt'] == null) {
      throw FormatException('UserModel.fromJson: missing "salt"');
    }
    if (map['createdAt'] == null) {
      throw FormatException('UserModel.fromJson: missing "createdAt"');
    }
    if (map['lastLoginAt'] == null) {
      throw FormatException('UserModel.fromJson: missing "lastLoginAt"');
    }

    final createdAtRaw = map['createdAt'] as String;
    final createdAt = DateTime.parse(createdAtRaw).toUtc();

    final lastLoginAtRaw = map['lastLoginAt'] as String;
    final lastLoginAt = DateTime.parse(lastLoginAtRaw).toUtc();

    return UserModel(
      login: map['login'] as String,
      passwordHash: map['passwordHash'] as String,
      salt: map['salt'] as String,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  /// Сериализация в JSON строку.
  String toJsonString() => jsonEncode(toJson());

  /// Парсинг из JSON строки.
  factory UserModel.fromJsonString(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserModel.fromJson(map);
  }

  /// Простая локальная проверка корректности модели.
  /// Здесь проверяем базовые условия: непустой логин и наличие хеша/соли.
  bool isValid() {
    return login.trim().isNotEmpty &&
        passwordHash.trim().isNotEmpty &&
        salt.trim().isNotEmpty;
  }

  /// Переопределяем toString для удобства дебага, но не включаем в вывод
  /// `passwordHash` и `salt`.
  @override
  String toString() {
    return 'UserModel(login: $login,'
           'createdAt: ${createdAt.toUtc().toIso8601String()},'
           'lastLoginAt: ${lastLoginAt.toUtc().toIso8601String()})';
  }

  /// Переопределение == и hashCode для удобства сравнения (по всем полям).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.login == login &&
        other.passwordHash == passwordHash &&
        other.salt == salt &&
        other.createdAt.toUtc() == createdAt.toUtc() &&
        other.lastLoginAt.toUtc() == lastLoginAt.toUtc();
  }

  @override
  int get hashCode =>
      login.hashCode ^
      passwordHash.hashCode ^
      salt.hashCode ^
      createdAt.toUtc().hashCode ^
      lastLoginAt.toUtc().hashCode;
}
