enum DataSource {
  empty,
  server,
  clipboard,
  serverInfo,
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