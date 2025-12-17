// lib/core/logging/logging_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:local_text_sync/core/logging/early_logger.dart';

/// Название модуля, используется в логах
const String _moduleName = 'logging_service';

/// Сервис работы с логгером
/// -----------------------------------
/// Настраивает вывод в консоль и, по возможности, в файл.
/// ! create вызывается один раз, до использования instance.
/// Параметры:
/// 1) bool isDebug : true - отладка, false - прод.
/// 2) необязательный, String? prefix : добавляется в начало каждой записи в лог.
///     формат: '[prefix] '
/// 3) необязательный, String? logDirectory : путь к каталогу с лог-файлами.
/// Файловый лог сначала пытаемся создать в предложенном каталоге, если не получается, то:
/// 1) в каталоге приложения;
/// 2) в подкаталоге "logs",
/// 3) просто в текущем каталоге;
/// 4) в каталоге исполняемого файла.
class LoggingService {
  /// Префикс для сообщений в лог: как правило, название модуля/функции.
  /// В лог запишется в квадратных скобках с пробелом: '[prefix] Message'
  String _prefix = '[$_moduleName] ';

  // Единственный экземпляр класса
  static late final LoggingService _instance;

  // Поля экземпляра
  final Logger _logger;
  final List<LogOutput> _outputs;

  // Сюда пишем всё до создания логгера
  static final _earlyLog = EarlyLogger();
  // Флаг инициализации
  static bool _isInitialized = false;

  // Анонимный конструктор
  LoggingService._(this._logger, this._outputs);

  /// Создает и возвращает экземпляр LoggingService.
  /// Присваивает этот экземпляр _instance.
  static Future<LoggingService> create({
    required bool isDebug,
    String? prefix,
    String? logDirectory,
  }) async {
    assert(
      !_isInitialized,
      'LoggingService.create() called more than once.'
      'This is a configuration error.',
    );

    if (_isInitialized) {
      return _instance;
    }

    final outputs = <LogOutput>[];
    outputs.add(ConsoleOutput());

    _earlyLog.add('starting...', msgLevel: Level.info);
    
    final checkedLogDirectory =
      await _getCheckedLogDirectory(logDirectory);

    if (checkedLogDirectory != null) {
      try {
        _earlyLog.add(
          'Try to initialize AdvancedFileOutput. '
          'Checked log directory: $checkedLogDirectory',
          msgLevel: Level.debug,
        );

        final advanced = AdvancedFileOutput(
          path: checkedLogDirectory,
          overrideExisting: false,
          fileHeader: '',
          fileFooter: '',
          writeImmediately: [Level.error, Level.fatal],
          maxDelay: const Duration(seconds: 2),  
          maxBufferSize: 2000,  
          maxFileSizeKB: 1024,
          maxRotatedFilesCount: 3,
          latestFileName: 'latest.log',
        );

        await advanced.init();
        outputs.add(advanced);
      } catch (e) {
        // Остаёмся с ConsoleOutput и логируем предупреждение
        _earlyLog.add(
          'Cannot initialize file output, '
          'falling back to console. Error:\n$e',
          msgLevel: Level.warning,
        );
      }
    } else {
      _earlyLog.add(
        'Cannot initialize file output, '
        'falling back to console. Error: checkedLogDirectory is null.',
        msgLevel: Level.warning,
      );
    }

    final logger = Logger(
      filter: isDebug ? DevelopmentFilter() : ProductionFilter(),
      printer: SimplePrinter(),
      output: MultiOutput(outputs),
      // В прод-режиме пишем начиная с warning
      level: isDebug ? Level.trace : Level.warning,
    );

    _instance = LoggingService._(logger, outputs);

    // Записываем в лог лог накопленный буфер
    _earlyLog.flushTo(vessel: _instance._logger);
     
    // Проверяем и присваиваем переданный префикс
    if (prefix != null && prefix.isNotEmpty) {
      _instance._prefix = '[$prefix] ';
    }

    // Страхуемся от повторного вызова фабрики
    _isInitialized = true;

    return _instance;
  }

  Logger get logger => _logger;

  /// Возвращает экземпляр синглтона.
  static LoggingService get instance {
    assert(
      _isInitialized,
      'LoggingService.instance accessed before create(). '
      'Call LoggingService.create() during application startup.',
    );
    return _instance;
  }

  static String get prefix {
    assert(_isInitialized, 'LoggingService.prefix accessed before create()');
    return _instance._prefix;
  }

  static set prefix(String newPrefix) {
    if (_isInitialized && newPrefix.isNotEmpty) {
      _instance._prefix = '[$newPrefix] ';
    }
  }

  // Дублируем все методы записи в лог
  // Для краткости и ради добавления префикса
  void t(String msg) => _logger.t('$prefix$msg');
  void d(String msg) => _logger.d('$prefix$msg');
  void i(String msg) => _logger.i('$prefix$msg');
  void w(String msg) => _logger.w('$prefix$msg');
  void e(String msg) => _logger.e('$prefix$msg');
  void f(String msg) => _logger.f('$prefix$msg');

  /// Негарантированная попытка корректно завершить/освободить ресурсы.
  Future<void> dispose() async {
    // сначала flush/закончить logger (если нужна явная операция) — тут просто вызываем destroy у outputs
    final futures = <Future>[];
    for (final out in _outputs) {
      try {
        futures.add(out.destroy());
      } catch (_) {
        // если out.destroy отсутствует или бросает — игнорируем
      }
    }
    await Future.wait(futures);
  }

  static Future<String?> _getCheckedLogDirectory(String? proposedDir) async {
    // 0. Проверяем что прислали
    _earlyLog.add('Check proposed log directory: $proposedDir');
    if (proposedDir != null &&
        proposedDir.isNotEmpty)
    {
      // Удаляем финальный слэш, если есть
      final safeDir = _cutSlashIfExists(proposedDir);
      if (await _isAvailable(logDirectory: safeDir)) {
        return safeDir;
      }
    }

    // 1. Приоритет - каталог приложения
    final supportDir = await getApplicationSupportDirectory();
    final appSupportDir = '${supportDir.path}/logs';
    _earlyLog.add('Check app support log directory: $appSupportDir');
    if (await _isAvailable(logDirectory: appSupportDir)) {
      return appSupportDir;
    }

    // 2. Просто подкаталог в текущем каталоге
    const logsDir = 'logs';
    _earlyLog.add('Check subdirectory: $logsDir');
    if (await _isAvailable(logDirectory: logsDir)) {
      return logsDir;
    }

    // 3. Совсем простой вариант!
    const emptyDirname = '';
    _earlyLog.add('Check current directory: $emptyDirname');
    if (await _isAvailable(logDirectory: emptyDirname)) {
      return emptyDirname;
    }

    // 4. Пытаемся взять каталог исполняемого файла
    // (плохая идея, но вдруг это тот случай...)
    final String execDir = File(Platform.executable).parent.path;
    final String appExecDir = '$execDir/logs';
    _earlyLog.add('Check exec directory: $appExecDir');
    if (await _isAvailable(logDirectory: appExecDir)) {
      return appExecDir;
    }

    // Всё перебрали, возвращаем null
    _earlyLog.add(
      'Unable to locate log write directory.',
      msgLevel: Level.warning,
    );

    return null;
  }

  static Future<bool> _isAvailable({required String logDirectory}) async {
    // Сначала пробуем создать каталог
    try {
      _earlyLog.add('Try to create log directory: $logDirectory');
      await Directory(logDirectory)
        .create(recursive: true);
    } catch (e) {
      // Ошибка при создании каталога
      _earlyLog.add('Creating log directory error:\n${e.toString()}');
      return false;
    }

    final tempFilename =
      '$logDirectory/test_${DateTime.now().microsecondsSinceEpoch}.tmp';
    final testFile = File(tempFilename);
    // Проверяем, что можем писать туда
    try {
      _earlyLog.add('Try to create temp file for directory checking: $tempFilename');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      // Не можем писать в папку
      _earlyLog.add('Test file creating error: ${e.toString()}');
      return false;
    }
  }
}

String _cutSlashIfExists(String dir) {
  if (dir.isEmpty) return dir;

  if (dir.endsWith('/') || dir.endsWith('\\')) {
    dir = dir.substring(0, dir.length - 1);
  }      
  return dir;
}