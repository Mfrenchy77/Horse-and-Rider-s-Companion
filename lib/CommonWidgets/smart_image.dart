import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// When to use an image proxy.
enum SmartImageProxyMode {
  none, // Never proxy (load direct).
  webOnly, // Proxy only on Web (avoid CORS).
  always, // Always proxy (Web + Mobile).
}

/// Config for SmartImage behavior.
class SmartImageConfig {
  const SmartImageConfig({
    this.proxyMode = SmartImageProxyMode.webOnly,
    this.proxyBase = 'https://wsrv.nl/?url=',
    this.forceWebP = false,
    this.placeholder,
    this.preferDirectFirst = true, // <— NEW: try direct before proxies
    this.enablePhotonFallback = true, // <— NEW: add i#.wp.com fallbacks
    this.photonSubdomains = const ['i0.wp.com', 'i1.wp.com', 'i2.wp.com'],
    this.domainS3Buckets = const {},
    this.domainExtraSegmentGuesses = const {},
  });

  final SmartImageProxyMode proxyMode;
  final String proxyBase;
  final bool forceWebP;

  /// Optional “default” image URL passed to proxies (if supported).
  final String? placeholder;

  /// If true, candidate order is direct →
  /// photon → wsrv → S3; if false, wsrv first.
  final bool preferDirectFirst;

  /// If true, also try WordPress Photon CDN (i#.wp.com/<host>/path?ssl=1&…).
  final bool enablePhotonFallback;

  /// Photon subdomains to try.
  final List<String> photonSubdomains;

  /// Map host -> S3 bucket name for WP offload.
  final Map<String, String> domainS3Buckets;

  /// Map host -> list of extra path-segment guesses (e.g. object version).
  final Map<String, List<String>> domainExtraSegmentGuesses;
}

/// Loads an image from [url] with:
/// - optional proxying (to avoid CORS on web),
/// - WordPress Photon fallback (very resilient),
/// - optional WordPress→S3 fallbacks,
/// - graceful retry across multiple candidates.
class SmartImage extends StatefulWidget {
  const SmartImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.maxLogicalWidth = 600,
    this.config = const SmartImageConfig(),
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Logical width cap used to downsample via proxy.
  final double maxLogicalWidth;

  final SmartImageConfig config;

  @override
  State<SmartImage> createState() => _SmartImageState();
}

class _SmartImageState extends State<SmartImage> {
  String? _normalizedUrl;
  late double _dpr;
  late int _targetPxWidth;

  /// Ordered list of candidate URLs to try.
  List<String> _candidates = const [];

  /// Index of current candidate.
  int _index = 0;

  String _computeKey() => '${_normalizedUrl ?? ''}|${widget.maxLogicalWidth}|'
      '${widget.config.proxyMode}|${widget.config.proxyBase}|'
      '${widget.config.forceWebP}|${widget.config.preferDirectFirst}|'
      '${widget.config.enablePhotonFallback}|$_dpr';

  String? _lastKey;

  @override
  void initState() {
    super.initState();
    _normalizedUrl = _normalizeUrl(widget.url);
  }

  @override
  void didUpdateWidget(covariant SmartImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url ||
        widget.maxLogicalWidth != oldWidget.maxLogicalWidth ||
        widget.config.proxyMode != oldWidget.config.proxyMode ||
        widget.config.proxyBase != oldWidget.config.proxyBase ||
        widget.config.forceWebP != oldWidget.config.forceWebP ||
        widget.config.preferDirectFirst != oldWidget.config.preferDirectFirst ||
        widget.config.enablePhotonFallback !=
            oldWidget.config.enablePhotonFallback) {
      _normalizedUrl = _normalizeUrl(widget.url);
      _lastKey = null; // force rebuild
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dpr = MediaQuery.of(context).devicePixelRatio;
    _targetPxWidth = max(1, (widget.maxLogicalWidth * _dpr).round());
    _maybeRebuildCandidates();
  }

  void _maybeRebuildCandidates() {
    final key = _computeKey();
    if (_lastKey == key) return;

    _candidates = _buildCandidateUrls(
      _normalizedUrl,
      widget.config,
      _targetPxWidth,
      _dpr,
    );
    _index = 0;
    _lastKey = key;
  }

  @override
  Widget build(BuildContext context) {
    if (_normalizedUrl == null || _candidates.isEmpty) {
      return _errorPlaceholder(context, message: 'Invalid image URL');
    }

    final url = _candidates[_index];

    return Image.network(
      url,
      key: ValueKey(url),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: _targetPxWidth,
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (c, error, stack) {
        debugPrint(
          'SmartImage failed [${_index + 1}/${_candidates.length}]: $error\n→ $url',
        );
        if (_index + 1 < _candidates.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _index++);
          });
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final host = Uri.tryParse(_normalizedUrl!)?.host ?? 'image';
        return _errorPlaceholder(context, message: "Can't load $host");
      },
    );
  }

  /// ---------------------- Helpers ----------------------

  Widget _errorPlaceholder(BuildContext context, {required String message}) {
    return Container(
      alignment: Alignment.center,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHigh
          .withValues(alpha: .40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 32),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  /// Normalize/sanitize URL: strip trailing punctuation, ensure scheme,
  /// normalize YouTube thumbs.
  String? _normalizeUrl(String? raw) {
    if (raw == null) return null;
    var url = raw.trim();
    while (url.endsWith('.') || url.endsWith(',')) {
      url = url.substring(0, url.length - 1);
    }
    Uri u;
    try {
      u = Uri.parse(url);
    } catch (_) {
      return null;
    }
    if (u.host.isEmpty) return null;

    // Normalize YouTube thumbnail to HQ.
    if (u.host.contains('ytimg.com')) {
      final parts = u.path.split('/');
      final idx = parts.indexWhere((p) => p == 'vi' || p == 'vi_webp');
      if (idx != -1 && parts.length > idx + 1) {
        final videoId = parts[idx + 1];
        return 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
      }
    }

    if (u.scheme.isEmpty) u = u.replace(scheme: 'https');
    return u.toString();
  }

  List<String> _buildCandidateUrls(
    String? normalized,
    SmartImageConfig cfg,
    int targetPx,
    double dpr,
  ) {
    if (normalized == null || normalized.isEmpty) return const [];
    final u = Uri.parse(normalized);

    final shouldProxyViaWsrv = switch (cfg.proxyMode) {
      SmartImageProxyMode.none => false,
      SmartImageProxyMode.webOnly => kIsWeb,
      SmartImageProxyMode.always => true,
    };

    var https = normalized;
    String? http;
    if (u.scheme == 'https') {
      http = u.replace(scheme: 'http').toString();
    } else if (u.scheme == 'http') {
      https = u.replace(scheme: 'https').toString();
      http = normalized;
    }

    String wrapWithWsrv(String raw) {
      final enc = Uri.encodeComponent(raw);
      final b = StringBuffer(
        'https://wsrv.nl/?url=$enc&w=$targetPx&dpr=${dpr.toStringAsFixed(2)}&we=1',
      );
      if (cfg.forceWebP) b.write('&output=webp');
      if (cfg.placeholder != null && cfg.placeholder!.isNotEmpty) {
        b.write('&default=${Uri.encodeComponent(cfg.placeholder!)}');
      }
      return b.toString();
    }

    // Photon fallbacks (i#.wp.com/host/path?ssl=1&w=<px>)
    List<String> photonUrlsFor(String raw) {
      if (!cfg.enablePhotonFallback) return const [];
      final p = Uri.parse(raw);
      final basePath = '${p.host}${p.path}'; // Photon takes schemeless original
      final wasHttps = p.scheme == 'https';
      final params = <String>[
        if (wasHttps) 'ssl=1',
        'w=$targetPx',
        'strip=all',
        if (cfg.forceWebP) 'output=webp',
      ].join('&');
      return cfg.photonSubdomains
          .map((sub) => 'https://$sub/$basePath?$params')
          .toList(growable: false);
    }

    // Optional WP→S3 candidates.
    final s3 = _wpS3Candidates(u, cfg);

    // Build in preferred order.
    final out = <String>[];

    if (cfg.preferDirectFirst) {
      // 1) Direct originals
      out.add(https);
      if (http != null) out.add(http);

      // 2) Photon for originals
      out.addAll(photonUrlsFor(https));
      if (http != null) out.addAll(photonUrlsFor(http));

      // 3) WSRV proxy for originals
      if (shouldProxyViaWsrv) {
        out.add(wrapWithWsrv(https));
        if (http != null) out.add(wrapWithWsrv(http));
      }

      // 4) S3 direct, then Photon, then WSRV
      out.addAll(s3);
      for (final s in s3) {
        out.addAll(photonUrlsFor(s));
      }
      if (shouldProxyViaWsrv) {
        for (final s in s3) {
          out.add(wrapWithWsrv(s));
        }
      }
    } else {
      // Original (older) behavior: WSRV first
      if (shouldProxyViaWsrv) {
        out.add(wrapWithWsrv(https));
        if (http != null) out.add(wrapWithWsrv(http));
      }
      out.add(https);
      if (http != null) out.add(http);
      out.addAll(photonUrlsFor(https));
      if (http != null) out.addAll(photonUrlsFor(http));

      // S3
      if (shouldProxyViaWsrv) {
        for (final s in s3) {
          out.add(wrapWithWsrv(s));
        }
      }
      out.addAll(s3);
      for (final s in s3) {
        out.addAll(photonUrlsFor(s));
      }
    }

    // De-dupe preserving order.
    final seen = <String>{};
    final uniq = <String>[];
    for (final s in out) {
      if (seen.add(s)) uniq.add(s);
    }
    return uniq;
  }

  /// Build S3 fallbacks for WordPress offload setups.
  List<String> _wpS3Candidates(Uri original, SmartImageConfig cfg) {
    final path = original.path;
    if (!path.contains('/wp-content/uploads/')) return const [];

    final host = original.host.toLowerCase().replaceFirst('www.', '');
    final bucket = cfg.domainS3Buckets[host];
    if (bucket == null || bucket.isEmpty) return const [];

    final baseTail = '/${path.startsWith('/') ? path.substring(1) : path}';
    final out = <String>[
      'https://s3.amazonaws.com/$bucket$baseTail',
      'https://$bucket.s3.amazonaws.com$baseTail',
    ];

    // Insert optional extra segment guesses after /YYYY/MM/
    final parts =
        path.split('/'); // ["", "wp-content","uploads","YYYY","MM", ...]
    if (parts.length >= 5) {
      final year = parts[3];
      final month = parts[4];
      final rest = parts.sublist(5).join('/');
      for (final g in cfg.domainExtraSegmentGuesses[host] ?? const <String>[]) {
        final tail = '/wp-content/uploads/$year/$month/$g/$rest';
        out
          ..add('https://s3.amazonaws.com/$bucket$tail')
          ..add('https://$bucket.s3.amazonaws.com$tail');
      }
    }

    // De-dupe preserving order.
    final seen = <String>{};
    final uniq = <String>[];
    for (final s in out) {
      if (seen.add(s)) uniq.add(s);
    }
    return uniq;
  }
}
