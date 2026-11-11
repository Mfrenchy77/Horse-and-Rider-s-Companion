import 'package:flutter/foundation.dart' show kIsWeb;

/// Shared metadata resolver for the editor and failed preview recovery.
const resourceImageResolverEndpoint =
    'https://us-central1-horse-and-riders-compani-d2bd4.cloudfunctions.net/resolveImage';

/// Parses an absolute HTTP(S) URL. Protocol-relative image URLs are handled
/// separately by [imageSourceUrl].
Uri? resourceWebUri(String? raw) {
  final uri = Uri.tryParse(raw?.trim() ?? '');
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

/// Opens cross-origin links in a browser tab to avoid frame failures.
bool shouldOpenResourceExternally(
  String? raw, {
  bool isWeb = kIsWeb,
  bool blocksEmbedding = false,
  Uri? appUri,
}) {
  final uri = resourceWebUri(raw);
  if (uri == null) return false;
  final host = uri.host.toLowerCase();
  if (host == 'facebook.com' ||
      host.endsWith('.facebook.com') ||
      host == 'fb.com' ||
      host.endsWith('.fb.com')) {
    return true;
  }
  if (!isWeb) return false;

  final app = resourceWebUri((appUri ?? Uri.base).toString());
  return blocksEmbedding || uri.origin != app?.origin;
}

/// Recovers the source image from stored wsrv/weserv URLs, including old
/// previews with several layers of proxying.
Uri? imageSourceUrl(String? raw) {
  var source = raw?.trim() ?? '';
  for (var depth = 0; depth < 8; depth++) {
    final uri = resourceWebUri(
      source.startsWith('//') ? 'https:$source' : source,
    );
    if (uri == null) return null;
    if (uri.host != 'wsrv.nl' && uri.host != 'images.weserv.nl') return uri;

    try {
      final proxy = Uri.parse(source.replaceAll('&amp;', '&'));
      source = proxy.queryParameters['url']?.trim() ?? '';
    } on FormatException {
      return null;
    }
    // WSRV also accepts schemeless source hosts.
    if (source.isNotEmpty &&
        !source.startsWith('//') &&
        !(Uri.tryParse(source)?.hasScheme ?? false)) {
      source = 'https://$source';
    }
  }
  return null;
}

final _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Returns a watch URL for a YouTube video link. Other pages, such as channel
/// links, keep the normal resource navigation.
Uri? youtubeWatchUri(String? raw) {
  final uri = resourceWebUri(raw);
  if (uri == null) return null;
  try {
    final segments = uri.pathSegments;
    final params = uri.queryParameters;
    final id = switch (uri.host) {
      'youtu.be' when segments.length == 1 => segments.first,
      'youtube.com' ||
      'www.youtube.com' ||
      'm.youtube.com' when uri.path == '/watch' => params['v'],
      'youtube.com' ||
      'www.youtube.com' ||
      'm.youtube.com' ||
      'www.youtube-nocookie.com' ||
      'youtube-nocookie.com'
          when segments.length == 2 &&
              const ['embed', 'shorts', 'live', 'v'].contains(segments.first) =>
        segments[1],
      _ => null,
    };
    if (id == null || !_youtubeId.hasMatch(id)) return null;

    final start = params['start'];
    final watch = Uri.https('www.youtube.com', '/watch', {
      ...params,
      'v': id,
      if (!params.containsKey('t') && start != null) 't': start,
    });
    return uri.hasFragment ? watch.replace(fragment: uri.fragment) : watch;
  } on FormatException {
    return null;
  }
}
