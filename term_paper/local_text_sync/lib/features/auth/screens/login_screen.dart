// lib\features\auth\screens\login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:local_text_sync/config/configurator.dart';
import 'package:local_text_sync/features/auth/validators/validators.dart';

const screenTitle = 'Вход';

/// Экран входа (LoginScreen).
/// - Поля: "Имя пользователя", "Пароль"
/// - Кнопки: "Вход", "Регистрация", "Войти без аккаунта"
/// - Предупреждение: восстановление пароля невозможно (локальное хранение)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Контроллеры для полей ввода — чтобы позже можно было взять текст.
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Форм-кей для валидации (например, минимальная длина пароля).
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Флаг, чтобы показать/скрыть пароль по нажатию иконки.
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Освобождаем контроллеры при удалении виджета
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Утилитный метод: показывает временное сообщение внизу экрана.
  void _showPlaceholderMessage(String text) {
    // Если контекст ещё валиден — показать SnackBar.
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  // Заглушка для кнопки "Вход"
  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      // Здесь позже будет реальная логика входа.
      _showPlaceholderMessage('Заглушка: обработка входа');
    } else {
      _showPlaceholderMessage('Проверьте введённые данные');
    }
  }

  // Заглушка для кнопки "Регистрация"
  void _onRegisterPressed() {
    // Здесь позже будет логика регистрации.
    _showPlaceholderMessage('Заглушка: регистрация');
  }

  // Кнопка "Войти без аккаунта": переключает состояние корневого виджета,
  // Переводит к основному экрану в гостевом режиме.
  void _onContinueAsGuest() {
    context.read<Config>().guestMode = true;
  }

  @override
  Widget build(BuildContext context) {
    // Основной Scaffold экрана входа.
    return Scaffold(
      appBar: AppBar(
        // Заголовок экрана
        title: const Text(screenTitle),
        centerTitle: true,
      ),
      // Touchable area: GestureDetector не нужен — используем Form и стандартные виджеты.
      body: SafeArea(
        child: Center(
          // Ограничиваем ширину для больших экранов — будет аккуратно на планшетах и десктопе.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // Карточка визуально выделяет форму
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Небольшой заголовок внутри карточки
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Войдите в приложение',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),

                      // Форма (валидация будет простая)
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Поле "Имя пользователя"
                            TextFormField(
                              controller: _loginController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Имя пользователя',
                                hintText: 'Введите имя пользователя',
                                prefixIcon: Icon(Icons.person),
                              ),
                              // Проверяем на пустоту и размер
                              validator: (value) => validateLoginField(value),
                            ),
                            const SizedBox(height: 12),

                            // Поле "Пароль"
                            TextFormField(
                              controller: _passwordController,
                              textInputAction: TextInputAction.done,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Пароль',
                                hintText: 'Введите пароль',
                                prefixIcon: const Icon(Icons.lock),
                                // Иконка для показа/скрытия пароля
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword ? 'Показать пароль' : 'Скрыть пароль',
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              // Проверяем на пустоту и размер
                              validator: (value) => validatePasswordField(value),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Кнопки: Вход (primary) и Регистрация (secondary)
                      Row(
                        children: [
                          // Вход — основной (Expanded, чтобы занимать пространство)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _onLoginPressed,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text('Войти'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Регистрация — альтернативная кнопка
                          OutlinedButton(
                            onPressed: _onRegisterPressed,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                              child: Text('Регистрация'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Кнопка "Войти без аккаунта" — оборачиваем в Tooltip,
                      // чтобы при наведении показать подсказку "История и настройки не будут сохранены".
                      // Tooltip работает на десктопе/веб при наведении, на мобильных — при долгом нажатии.
                      Tooltip(
                        message: 'История и настройки не будут сохранены',
                        waitDuration: const Duration(milliseconds: 300),
                        showDuration: const Duration(seconds: 2),
                        child: TextButton(
                          onPressed: _onContinueAsGuest,
                          child: const Text('Войти без аккаунта'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Информационное предупреждение о невозможности восстановления пароля.
                      // Выделено иконкой и мягким фоном.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.30), // заменяет withOpacity(0.3)
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(right: 10.0),
                              child: Icon(Icons.info_outline, size: 20),
                            ),
                            const Expanded(
                              child: Text(
                                'Внимание: данные и пароль хранятся только на этом устройстве.'
                                'Если вы забудете пароль, восстановление будет невозможно. Сохранённые данные будут потеряны.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
