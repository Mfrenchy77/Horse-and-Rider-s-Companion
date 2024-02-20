import 'dart:convert';
import 'package:database_repository/src/models/place.dart';
import 'package:http/http.dart' as http;

/// A repository that uses the Nominatim (OpenStreetMap) API
/// to search for places based on a query.
class OpenMapsRepository {
  /// Initializes a new instance of [OpenMapsRepository] with an [http.Client].
  /// The [httpClient] is injected to allow for easier testing and
  ///  configuration.
  OpenMapsRepository({http.Client? httpClient})
      : httpClient = httpClient ?? http.Client();

  /// The base URL for the Nominatim API.
  final String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// The HTTP client used to make requests to the API.
  final http.Client httpClient;

  /// Searches for places matching the given [query].
  ///
  /// Throws [FormatException] if the response cannot be parsed,
  /// [HttpException] for non-successful responses,
  /// and [Exception] for other types of errors.
  Future<List<Place>> searchPlaces(String query) async {
    final url = Uri.parse('$_baseUrl?format=jsonv2&q=$query');
    try {
      final response = await httpClient.get(
        url,
        headers: {
          'User-Agent':
              "Horse & Rider's Companion (horseandriderscompanion@gmail.com)",
        },
      );

      // Check for non-successful response (e.g., 404, 500)
      if (response.statusCode != 200) {
        throw HttpException('Failed to load places', uri: url);
      }

      // Attempt to parse the JSON response
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map((json) => Place.fromJson(json as Map<String, dynamic>))
          .toList();
    } on http.ClientException {
      throw Exception('Network error occurred while fetching data.');
    } on FormatException {
      throw const FormatException('Failed to parse places data.');
    } catch (e) {
      // Catch-all for other types of errors
      throw Exception('An unexpected error occurred: $e');
    }
  }
}

/// Custom exception for handling HTTP errors.
class HttpException implements Exception {
  /// Creates a new [HttpException] with an optional error [message]
  HttpException(this.message, {this.uri});

  /// Creates a new [HttpException] with an optional error [message]
  final String message;

  /// The URI of the request that caused the exception
  final Uri? uri;

  @override
  String toString() => 'HttpException: $message, URI: $uri';
}
