import 'dart:convert';

import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;

/// {@template url_metadata_exception}
/// An exception class for the metadata extraction failures.
/// {@endtemplate}
class UrlMetadataException with EquatableMixin implements Exception {
  /// {@macro url_metadata_exception}
  const UrlMetadataException(this.error);

  /// The associated error code.
  final String error;

  @override
  List<Object?> get props => [error];
}

/// A repository for retrieving URL metadata.
///
/// This repository is responsible for fetching metadata for URLs.
/// It requires an API key for authentication.
class UrlMetadataRepository {
  /// Constructs a [UrlMetadataRepository] instance with an [apiKey].
  UrlMetadataRepository({required this.apiKey, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// The API key used to authenticate requests to the API.
  final String apiKey;
  final http.Client _httpClient;

  /// Fetches the metadata for a given URL.

  Future<UrlMetadata> extractUrlMetadata({required String url}) async {
    Uri uri;

    try {
      uri = Uri.parse(url);
    } on FormatException catch (_) {
      throw const UrlMetadataException('Invalid URL Format');
    }

    http.Response response;

    try {
      // Include the API key as a query parameter
      final requestUrl =
          Uri.parse('https://jsonlink.io/api/extract?url=$uri&api_key=$apiKey');
      response = await _httpClient.get(requestUrl);
    } on Exception catch (error) {
      throw UrlMetadataException(error.toString());
    }
    Map<String, dynamic> body;

    try {
      body = json.decode(response.body) as Map<String, dynamic>;
    } on Exception catch (_) {
      throw const UrlMetadataException('Unable to decode the JSON response');
    }

    if (response.statusCode != 200) {
      throw const UrlMetadataException('HTTP Exception occurred');
    }

    UrlMetadata metadata;

    try {
      metadata = UrlMetadata.fromJson(body);
    } on Exception catch (_) {
      throw const UrlMetadataException(
        'Error while de-serializing the response',
      );
    }

    return metadata;
  }
}
