/// Stub implementation for non-web platforms where Web Share API is absent.
Future<bool> tryNativeWebShare({
  required String title,
  required String url,
  String? text,
}) async =>
    false;
