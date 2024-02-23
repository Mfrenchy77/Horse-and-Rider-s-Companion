import 'dart:convert';
import 'package:database_repository/database_repository.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

/// Exception thrown when there is an error fetching metadata for a URL.
class UrlMetadataException implements Exception {
  /// Creates a [UrlMetadataException] with an optional error message and code.
  const UrlMetadataException({this.message, this.code});

  /// A message describing the error.
  final String? message;

  /// An optional error code for categorizing the error.
  final String? code;

  @override
  String toString() => 'UrlMetadataException: $message (Code: $code)';
}

/// Exception thrown when metadata extraction fails.
class MetadataExtractionException implements Exception {
  /// Creates a [MetadataExtractionException] with an error [message].
  MetadataExtractionException(this.message);

  /// Creates a [MetadataExtractionException] with an error [message].
  final String message;

  @override
  String toString() => 'MetadataExtractionException: $message';
}

/// A repository responsible for fetching URL metadata.
class UrlMetadataRepository {
  /// Constructs an instance of [UrlMetadataRepository].
  ///
  /// Requires an [apiKey] for authenticating with the metadata service.
  /// An optional [httpClient] can be provided for making HTTP requests.
  UrlMetadataRepository({required this.apiKey, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// The API key used to authenticate with the metadata service.
  final String apiKey;

  /// The HTTP client used to make network requests.
  final http.Client _httpClient;

  /// Fetches and returns the metadata for a given [url].
  ///
  /// Throws [UrlMetadataException] if the URL format is invalid,
  /// the network request fails, the response cannot be decoded,
  /// or if the metadata cannot be parsed.
  Future<UrlMetadata> extractUrlMetadata({required String url}) async {
    Uri uri;

    try {
      uri = Uri.parse(url);
    } on FormatException {
      throw const UrlMetadataException(
        message: 'Invalid URL format.',
        code: 'invalid_url',
      );
    }

    http.Response response;

    try {
      final requestUrl = Uri.https('jsonlink.io', '/api/extract', {
        'url': uri.toString(),
        'api_key': apiKey,
      });
      response = await _httpClient.get(requestUrl);
    } catch (error) {
      throw UrlMetadataException(
        message: 'Network request failed: $error',
        code: 'network_error',
      );
    }

    if (response.statusCode != 200) {
      throw UrlMetadataException(
        message: 'HTTP error: ${response.statusCode}',
        code: 'http_error_${response.statusCode}',
      );
    }

    Map<String, dynamic> body;

    try {
      body = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const UrlMetadataException(
        message: 'Failed to decode JSON response.',
        code: 'json_decode_error',
      );
    }

    UrlMetadata metadata;

    try {
      metadata = UrlMetadata.fromJson(body);
    } catch (_) {
      throw const UrlMetadataException(
        message: 'Failed to parse URL metadata.',
        code: 'parse_error',
      );
    }

    return metadata;
  }

  /// Fetches and extracts metadata from the specified [url].
  ///
  /// Returns an instance of [UrlMetadata] containing the extracted information.
  /// Throws [MetadataExtractionException] for any errors
  ///  encountered during the process.
  Future<UrlMetadata> extractMetadataFromUrl(String url) async {
    http.Response response;
    try {
      response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'YourAppName/1.0 (contact@yourapp.com)', // Customize your User-Agent
        },
      );

      if (response.statusCode != 200) {
        throw MetadataExtractionException(
          'Failed to fetch URL with status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw MetadataExtractionException('Failed to fetch URL: $e');
    }

    Document document;
    try {
      document = parse(response.body);
    } catch (e) {
      throw MetadataExtractionException('Failed to parse HTML content: $e');
    }

    final title = document.querySelector('title')?.text ?? 'No title found';
    final description = document
            .querySelector('meta[name="description"]')
            ?.attributes['content'] ??
        'No description available';
    final imageUrls = document
        .querySelectorAll('meta[property="og:image"]')
        .map((e) => e.attributes['content'])
        .toList();
    // Note: Extracting duration and
    //domain might require additional logic or assumptions
    const duration = 0;
    final domain = Uri.parse(url).host;

    return UrlMetadata(
      title: title,
      description: description,
      imageUrls: imageUrls,
      duration: duration,
      domain: domain,
      url: url,
    );
  }
}
