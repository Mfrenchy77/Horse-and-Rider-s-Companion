/// Thrown when direct browser file download is unavailable on the current
/// platform.
class CurriculumDownloadUnsupportedException implements Exception {
  const CurriculumDownloadUnsupportedException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Non-web stub for downloading curriculum JSON files.
Future<void> downloadCurriculumFile(String fileName, String content) async {
  throw const CurriculumDownloadUnsupportedException(
    'Direct browser file download is only available on Flutter Web.',
  );
}
