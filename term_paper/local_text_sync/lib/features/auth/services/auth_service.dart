// lib/features/auth/services/auth_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  /// Локальный secure storage
  final _storage = FlutterSecureStorage();

  // null - значит не проверили
  bool? _hasExistsProfile;
  /// Свойство: загружен ли профиль для этого пользователя
  bool? get hasExistsProfile => _hasExistsProfile;

  Future<void> checkProfile() async {
    _hasExistsProfile = await _storage.containsKey(key: 'local_text_sync');
  }
}
