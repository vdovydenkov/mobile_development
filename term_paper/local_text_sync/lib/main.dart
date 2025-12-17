import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

import 'package:local_text_sync/app/app.dart';
import 'package:local_text_sync/config/configurator.dart';
import 'package:local_text_sync/features/auth/state/auth_state.dart';
import 'package:local_text_sync/core/logging/logging_service.dart';

const appTitle = 'Local Text Sync';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final log = await LoggingService.create(
    isDebug: true,
    prefix: 'app'
  );

  log.i('LoggingService initialized.');

  // Сохраняем в DI
  GetIt.instance.registerSingleton<LoggingService>(log);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => Config()
        ),
        ChangeNotifierProvider(
          create: (_) => AuthState()
        ),
      ],
      child: const LocalTextSyncApp()
    ),
  );
}

class LocalTextSyncApp extends StatelessWidget {
  const LocalTextSyncApp({super.key});

  // Корневой виджет приложения
  // Ссылается на AppRoot из app.dart: там начальная маршрутизация
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AppRoot(),
    );
  }
}
