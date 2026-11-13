import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Utilities/link_metadata_service.dart';
import 'package:horseandriderscompanion/Utilities/resource_urls.dart';

/// When to use the image proxy.
enum SmartImageProxyMode { none, webOnly, always }

class SmartImageConfig {
  const SmartImageConfig({
    this.proxyMode = SmartImageProxyMode.webOnly,
    this.forceWebP = false,
    this.preferDirectFirst = true,
  });

  final SmartImageProxyMode proxyMode;
  final bool forceWebP;
  final bool preferDirectFirst;
}

/// Loads the original image, then optionally tries one proxy and one
/// replacement discovered from the resource page.
class SmartImage extends StatelessWidget {
  const SmartImage(
    this.url, {
    super.key,
    this.resourceUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.maxLogicalWidth = 600,
    this.config = const SmartImageConfig(),
    this.linkMetadataService,
  });

  final String? url;
  final String? resourceUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;
  final double maxLogicalWidth;
  final SmartImageConfig config;
  final LinkMetadataService? linkMetadataService;

  // Share the current candidate, resolver request and terminal outcome across
  // resource cards and detail pages. Flutter's ImageCache shares image loads.
  static final _previews =
      <(Uri, Uri?, Uri?, bool, LinkMetadataService?), _Preview>{};
  static const _cacheLimit = 512;

  @override
  Widget build(BuildContext context) {
    final source = _normalizedSource(url);
    if (source == null) return _placeholder(context, 'Invalid image URL');

    final page = resourceWebUri(resourceUrl);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final targetWidth = max(1, (maxLogicalWidth * dpr).round());
    final proxyEnabled = switch (config.proxyMode) {
      SmartImageProxyMode.none => false,
      SmartImageProxyMode.webOnly => kIsWeb,
      SmartImageProxyMode.always => true,
    };
    final isPhoton = const [
      'i0.wp.com',
      'i1.wp.com',
      'i2.wp.com',
    ].contains(source.host);

    Uri proxyFor(Uri uri) => Uri.parse(
      'https://wsrv.nl/?url=${Uri.encodeComponent(uri.toString())}'
      '&w=$targetWidth&dpr=${dpr.toStringAsFixed(2)}&we=1'
      '${config.forceWebP ? '&output=webp' : ''}',
    );

    final proxy = proxyEnabled && !isPhoton ? proxyFor(source) : null;
    final key = (
      source,
      page,
      proxy,
      config.preferDirectFirst,
      linkMetadataService,
    );
    final resolver =
        linkMetadataService ?? const CloudFunctionsLinkMetadataService();
    final preview =
        _previews.remove(key) ??
        _Preview(
          [
            if (proxy != null && !config.preferDirectFirst) proxy,
            source,
            if (proxy != null && config.preferDirectFirst) proxy,
          ],
          page == null || page == source
              ? null
              : () async {
                  final replacement = await _resolveReplacement(
                    resolver,
                    page,
                    source,
                  );
                  if (replacement == null || replacement == source) return null;
                  return proxyEnabled && replacement.scheme == 'http'
                      ? proxyFor(replacement)
                      : replacement;
                },
        );
    _previews[key] = preview;
    if (_previews.length > _cacheLimit) _previews.remove(_previews.keys.first);

    return ValueListenableBuilder<Uri?>(
      valueListenable: preview,
      builder: (context, candidate, child) {
        if (candidate == null) {
          return _placeholder(context, 'Image unavailable');
        }

        return Image.network(
          candidate.toString(),
          key: ValueKey(candidate),
          width: width,
          height: height,
          fit: fit,
          // An HTML image can display external images without fetch CORS.
          webHtmlElementStrategy: candidate.host != 'wsrv.nl'
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.never,
          cacheWidth: kIsWeb ? null : targetWidth,
          errorBuilder: (context, error, stack) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(preview.advance(candidate));
            });
            return _placeholder(context, 'Image unavailable');
          },
        );
      },
    );
  }

  Widget _placeholder(BuildContext context, String message) =>
      fallback ??
      Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHigh.withValues(alpha: .40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image, size: 32),
            const SizedBox(height: 6),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );

  static Uri? _normalizedSource(String? raw) {
    final uri = imageSourceUrl(raw);
    if (uri == null) return null;
    if (uri.host == 'ytimg.com' || uri.host.endsWith('.ytimg.com')) {
      final segments = uri.path.split('/');
      final index = segments.indexWhere((p) => p == 'vi' || p == 'vi_webp');
      if (index != -1 && segments.length > index + 1) {
        return Uri.https(
          'i.ytimg.com',
          '/vi/${segments[index + 1]}/hqdefault.jpg',
        );
      }
    }
    return uri;
  }

  static Future<Uri?> _resolveReplacement(
    LinkMetadataService resolver,
    Uri page,
    Uri source,
  ) async {
    try {
      final resolved = await resolver.resolveImage(
        page.toString(),
        imageHint: source.toString(),
      );
      return imageSourceUrl(resolved);
    } catch (_) {
      return null;
    }
  }
}

class _Preview extends ValueNotifier<Uri?> {
  _Preview(this._candidates, this._replacement) : super(_candidates.first);

  final List<Uri> _candidates;
  Future<Uri?> Function()? _replacement;
  var _index = 0;

  Future<void> advance(Uri failed) async {
    if (value != failed) return;
    _index++;
    if (_index < _candidates.length) {
      value = _candidates[_index];
      return;
    }

    value = null;
    final resolve = _replacement;
    _replacement = null;
    if (resolve == null) return;
    final replacement = await resolve();
    if (replacement != null && !_candidates.contains(replacement)) {
      value = replacement;
    }
  }
}
