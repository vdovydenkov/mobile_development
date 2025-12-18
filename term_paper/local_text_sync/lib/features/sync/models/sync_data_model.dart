enum DataSource {
  // Источник данных
  empty,       // Пусто, ничего не делаем
  server,      // Что-то прислал сервер
  statusInfo,  // Информация для статусной строки
  queue,       // Изменилась очередь текстов
}

class SyncData {
  final String     text;
  final DataSource source;
  final DateTime   updatedAt = DateTime.now();

  SyncData({
    this.text   = '',
    this.source = DataSource.empty,
  });
}