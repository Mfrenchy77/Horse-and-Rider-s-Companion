import 'dart:convert';

import 'package:universal_html/html.dart' as html;

/// Thrown when direct browser file download is unavailable on the current
/// platform.
class CurriculumDownloadUnsupportedException implements Exception {
  const CurriculumDownloadUnsupportedException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Triggers a browser file download of [content] named [fileName] on Flutter
/// Web using a UTF-8 JSON Blob and anchor download link.
Future<void> downloadCurriculumFile(String fileName, String content) async {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  try {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor
      ..click()
      ..remove();
  } finally {
    html.Url.revokeObjectUrl(url);
  }
}
