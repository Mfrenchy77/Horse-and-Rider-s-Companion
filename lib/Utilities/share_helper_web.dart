import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Attempts to invoke the browser Web Share API (`navigator.share`).
///
/// Returns `true` if the share sheet completed, or `false` if unavailable,
/// cancelled, or unsupported so the caller can fall back to Copy Link.
Future<bool> tryNativeWebShare({
  required String title,
  required String url,
  String? text,
}) async {
  try {
    final nav = globalContext.getProperty<JSObject?>('navigator'.toJS);
    if (nav == null || !nav.has('share')) return false;
    final data = JSObject()
      ..setProperty('title'.toJS, title.toJS)
      ..setProperty('url'.toJS, url.toJS);
    if (text != null && text.isNotEmpty) {
      data.setProperty('text'.toJS, text.toJS);
    }
    await nav.callMethod<JSPromise<JSAny?>>('share'.toJS, data).toDart;
    return true;
  } catch (_) {
    return false;
  }
}
