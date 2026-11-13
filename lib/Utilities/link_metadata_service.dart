import 'dart:convert';

import 'package:horseandriderscompanion/Utilities/resource_urls.dart';
import 'package:http/http.dart' as http;

/// Result returned by a [LinkMetadataService] lookup.
class LinkMetadataResult {
  const LinkMetadataResult({
    this.title,
    this.description,
    this.imageUrl,
    this.blocksEmbedding = false,
  });

  final String? title;
  final String? description;
  final String? imageUrl;
  final bool blocksEmbedding;
}

/// Backend-neutral interface for fetching link metadata and resolving preview
/// images without coupling Cubits to specific Cloud Functions endpoints.
abstract interface class LinkMetadataService {
  /// Fetches metadata for [url], returning `null` if unavailable.
  Future<LinkMetadataResult?> fetchMetadata(String url);

  /// Resolves a direct image URL for [pageUrl] using an optional [imageHint].
  Future<String?> resolveImage(String pageUrl, {String? imageHint});
}

/// Default [LinkMetadataService] backed by the Firebase Cloud Functions
/// `resolveImage` endpoint.
class CloudFunctionsLinkMetadataService implements LinkMetadataService {
  const CloudFunctionsLinkMetadataService({
    this.resolveImageEndpoint = resourceImageResolverEndpoint,
    this.timeout = const Duration(seconds: 12),
  });

  final String resolveImageEndpoint;
  final Duration timeout;

  @override
  Future<LinkMetadataResult?> fetchMetadata(String url) async => null;

  @override
  Future<String?> resolveImage(String pageUrl, {String? imageHint}) async {
    try {
      final response = await http
          .post(
            Uri.parse(resolveImageEndpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'url': pageUrl,
              'hint': imageHint ?? '',
            }),
          )
          .timeout(timeout);
      if (response.statusCode != 200) return null;
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      return imageSourceUrl(result['resolvedUrl'] as String?)?.toString();
    } catch (_) {
      return null;
    }
  }
}
