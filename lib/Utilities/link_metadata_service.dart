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
