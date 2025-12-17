// lib/core/logging/early_logger.dart
import 'package:logger/logger.dart';

/// Запись логов в буфер лог-по уровням
class EarlyLogger {
  // Префикс: добавляется перед любыми сообщениями в лог
  String _prefix = '';
  
  // Сюда пишем все буферы всех уровней
  final Map<Level, StringBuffer> _buffer = {};

  // Наружу отдаем ридонли геттер буффера
  Map<Level, StringBuffer> get buffer => Map.unmodifiable(_buffer);

  EarlyLogger({String prefix = ''}) {
    if (prefix.isNotEmpty) {
      _prefix = '[$prefix] ';
    }
  }
  
  /// Добавляем запись: строку на заданном уровне
  /// Уровень по умолчанию - Level.trace
  void add(
    String msg, {
    Level msgLevel = Level.trace,
  }) {
    final buf = _buffer.putIfAbsent(msgLevel, () => StringBuffer());
    buf.writeln('$_prefix$msg');
  }

  /// Возвращает всё содержимое буффера заданного уровня в виде String?
  String? get(Level logLevel) => _buffer[logLevel]?.toString();

  /// Очищает весь буфер
  void clear() {
    _buffer.clear();
  }

  /// Выгружает все строки из буферов в лог переданного логгера и очищает буфер
  void flushTo({required Logger vessel}) {
    for (final entry in _buffer.entries) {
      final text = entry.value.toString();
      if (text.isNotEmpty) {
        vessel.log(entry.key, text);
      }
    }
  }
}