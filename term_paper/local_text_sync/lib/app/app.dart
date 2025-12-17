import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

import 'package:local_text_sync/features/auth/screens/login_screen.dart';
import 'package:local_text_sync/features/sync/screens/sync_screen.dart'; // SyncScreen
import 'package:local_text_sync/config/configurator.dart';
import 'package:local_text_sync/features/auth/state/auth_state.dart';
import 'package:local_text_sync/features/sync/services/sync_service.dart';
import 'package:local_text_sync/features/sync/state/sync_state.dart';
import 'package:local_text_sync/core/logging/logging_service.dart';

/// Корневой виджет приложения, который решает,
/// какой экран показывать: LoginScreen или SyncScreen
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    context.read<Config>().load();
  }

  @override
  Widget build(BuildContext context) {
    // Здесь храним состояние аутентификации
    final auth = context.watch<AuthState>();
    // Здесь храним конфиг
    final cfg = context.watch<Config>();
    // Достаем логгер из DI
    final log = GetIt.instance<LoggingService>();

    // Пока идёт загрузка, показываем кружок
    if (auth.loading || cfg.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Показываем вход если режим не гостевой и аутентификация не пройдена
    if (cfg.guestMode == false && auth.isAuthenticated == false) {
      log.i('Show a login screen.');
      return const LoginScreen();
    }

    // Все проверки пройдены,
    // Передаем сервис и состояние в основной экран синхронизации
    log.i('Show a main sync screen.');
    return MultiProvider(
      providers: [
        Provider<SyncService>(
          create: (_) {
            // Нужно для запуска сервера
            final service = SyncService(cfg, log);
            service.init();
            return service;
          },

          // Корректно удаляем
          dispose: (_, service) =>
            service.dispose(),
        ),
        ChangeNotifierProvider<SyncState>(
          create: (context) => SyncState(
            // В параметре передаем сервис
            context.read<SyncService>(),
          ),
        ),
      ],
      child: const SyncScreen(),
    );
  }
}
