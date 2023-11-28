// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'package:database_repository/database_repository.dart';
import 'package:http/http.dart' as http;

/// Exception thrown when an API call to the Zipcodebase API fails.
///
/// This exception is used to encapsulate general errors that occur during
/// the API request, such as network failures or unexpected exceptions.
class ZipcodeApiException implements Exception {
  ZipcodeApiException(this.message);

  /// A message describing the error.
  final String message;

  @override
  String toString() => 'ZipcodeApiException: $message';
}

/// Exception thrown when the Zipcodebase API returns a non-200 status code.
///
/// This exception indicates that the API request was unsuccessful.
/// The HTTP status code can be used to determine
///  the specific nature of the failure.
class ZipcodeApiRequestException implements Exception {
  ZipcodeApiRequestException(this.statusCode);

  /// The HTTP status code returned by the API.
  final int statusCode;

  @override
  String toString() =>
      'ZipcodeApiRequestException: HTTP status code $statusCode';
}

/// Exception thrown when there is an error parsing the
///  response from the Zipcodebase API.
///
/// This exception is used when the response from the API cannot be successfully
/// parsed into the expected format or data structure.
class ZipcodeApiResponseParsingException implements Exception {
  ZipcodeApiResponseParsingException(this.message);

  /// A message describing the parsing error.
  final String message;

  @override
  String toString() => 'ZipcodeApiResponseParsingException: $message';
}

/// A repository for interacting with the Zipcodebase API.
///
/// This class provides methods to query the Zipcodebase API for information
/// about postal codes. It requires an API key to authenticate requests.
class ZipcodeRepository {
  /// Creates an instance of [ZipcodeRepository] with the provided API key.
  ///
  /// The [apiKey] is required to authenticate requests to the Zipcodebase API.
  ZipcodeRepository({required this.apiKey});

  /// The base URL of the Zipcodebase API.
  final String _baseUrl = 'https://app.zipcodebase.com/api/v1/search';

  /// The API key for accessing the Zipcodebase API.
  final String apiKey;

  /// Queries the Zipcodebase API for information
  ///  about the specified postal code.
  ///
  /// [postalCode]: The postal code for which information is being requested.
  /// [country]: Optional. The ISO 3166-1 alpha-2 country code to
  ///  limit the search to a specific country.
  ///
  /// Returns a [ZipcodeApiResponse] containing the query results, or `null` if
  /// the request fails or the API does not return a successful response.
  Future<ZipcodeApiResponse?> queryZipcode(
    String postalCode, {
    String? country,
  }) async {
    var url = Uri.parse('$_baseUrl?apikey=$apiKey&codes=$postalCode');
    if (country != null) {
      url = Uri.parse(
        '$_baseUrl?apikey=$apiKey&codes=$postalCode&country=$country',
      );
    }

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return ZipcodeApiResponse.fromJson(json);
        } catch (e) {
          throw ZipcodeApiResponseParsingException(e.toString());
        }
      } else {
        throw ZipcodeApiRequestException(response.statusCode);
      }
    } catch (e) {
      throw ZipcodeApiException(e.toString());
    }
  }
}
