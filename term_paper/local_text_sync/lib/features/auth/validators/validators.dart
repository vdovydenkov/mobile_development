String? validateLoginField(String? value) {
  const minLength = 3;
  const maxLength = 48;

  // Проверяем на пустое поле
  if (value == null || value.trim().isEmpty) {
    return 'Поле не может быть пустым';
  }

  if (value.length < minLength) {
    return 'Имя должно быть не менее $minLength символов';
  }

  if (value.length > maxLength) {
    return 'Имя должно быть не более $maxLength символов';
  }

  return null;
}

String? validatePasswordField(String? value) {
  const minLength = 6;
  const maxLength = 32;

  if (value == null || value.isEmpty) {
    return 'Введите пароль';
  }

  if (value.length < minLength) {
    return 'Пароль должен быть не менее $minLength символов';
  }

  if (value.length > maxLength) {
    return 'Пароль должен быть не более $maxLength символов';
  }

  return null;
}
