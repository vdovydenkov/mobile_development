// lib/config/defaults.dart

const bool defaultGuestMode = false;

// ---------- Опции локального сервера

/// Если HTML-шаблон не считался — берем минимальный
const String defaultFailSafeHtmlTemplate = '''
<!doctype html>
<html>
  <head>
    <meta charset="utf-8"/>
    <title>Local Text Sync (limited)</title>
  </head>

  <body>
    <form action="http://{{HOST}}:{{PORT}}/content" method="post">
      <input name="content">
      <button>Sync</button>
    </form>
  </body>
</html>
''';

/// Порт локального сервера по умолчанию
const int    defaultHttpServerPort = 2234;
/// Путь до шаблона HTML-страницы
const String defaultHtmlTemplatePath = 'assets/html/sync_page_template.html';
