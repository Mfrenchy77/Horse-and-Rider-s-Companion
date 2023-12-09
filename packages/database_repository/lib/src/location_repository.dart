import 'dart:convert';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Repository for handling location-based API calls.
class LocationRepository {
  /// Constructs a [LocationRepository] instance with an [apiKey].
  LocationRepository({required this.apiKey});

  /// The API key used to authenticate requests to the API.
  final String apiKey;

  /// Retrieves a list of countries from the API.
  ///
  /// Returns a [Future] that resolves to a list of [Country] objects.
  /// Throws an [Exception] if the API call fails.
  Future<List<Country>> getCountries() async {
    final headers = {
      'X-CSCAPI-KEY': apiKey,
    };

    final request = http.Request(
      'GET',
      Uri.parse('https://api.countrystatecity.in/v1/countries'),
    );

    request.headers.addAll(headers);

    final response = await request.send();

    if (response.statusCode == 200) {
      final data = await response.stream.bytesToString();
      final json = jsonDecode(data) as Iterable<dynamic>;
      return json
          .map<Country>(
            (country) => Country.fromJson(country as Map<String, dynamic>),
          )
          .toList();
    } else {
      throw Exception('Failed to load countries: ${response.reasonPhrase}');
    }
  }

  /// Fetches a list of states within a specified country from the API.
  ///
  /// [countryIso]: The ISO2 code of the country to filter states.
  ///
  /// Returns a [Future] that resolves to a list of [StateLocation] objects.
  /// Throws an [Exception] if the API call fails.
  Future<List<StateLocation>> getStates({required String countryIso}) async {
    final headers = {
      'X-CSCAPI-KEY': apiKey,
    };

    final request = http.Request(
      'GET',
      Uri.parse(
        'https://api.countrystatecity.in/v1/countries/$countryIso/states',
      ),
    );

    request.headers.addAll(headers);

    final response = await request.send();

    if (response.statusCode == 200) {
      final data = await response.stream.bytesToString();
      final json = jsonDecode(data) as Iterable<dynamic>;
      return json
          .map<StateLocation>(
            (state) => StateLocation.fromJson(state as Map<String, dynamic>),
          )
          .toList();
    } else {
      throw Exception('Failed to load states: ${response.reasonPhrase}');
    }
  }

  /// Fetches a list of cities from the API.
  ///
  /// [countryCode]: The country code (ISO 3166-1 alpha-2) to filter states.
  /// [stateId]: The unique identifier of the state.
  ///
  /// Returns a [Future] that resolves to a list of [City] objects.
  /// Throws an [Exception] if the API call fails.
  Future<List<City>> getCities({
    required String countryCode,
    required String stateIso,
  }) async {
    final headers = {
      'X-CSCAPI-KEY': apiKey,
    };

    final request = http.Request(
      'GET',
      Uri.parse(
        'https://api.countrystatecity.in/v1/countries/$countryCode/states/$stateIso/cities',
      ),
    );

    request.headers.addAll(headers);
    debugPrint('City request: $request');
    final response = await request.send();

    if (response.statusCode == 200) {
      final data = await response.stream.bytesToString();
      final json = jsonDecode(data) as Iterable<dynamic>;
      return json
          .map<City>((city) => City.fromJson(city as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load cities: ${response.reasonPhrase}');
    }
  }
}
