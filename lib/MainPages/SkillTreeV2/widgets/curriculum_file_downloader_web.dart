import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

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
  final bytes = Uint8List.fromList(utf8.encode(content));
  final blob = web.Blob(
    <JSUint8Array>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  try {
    final anchor = (web.document.createElement('a') as web.HTMLAnchorElement)
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor
      ..click()
      ..remove();
  } finally {
    web.URL.revokeObjectURL(url);
  }
}
