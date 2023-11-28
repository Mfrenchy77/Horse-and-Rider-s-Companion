import 'package:flutter/material.dart';

/// Represents location details associated with a specific postal code.
///
/// This class holds information about the geographical and administrative
/// aspects of a location identified by its postal code.
class LocationInfo {
  /// Constructs an instance of [LocationInfo] with the given details.
  ///
  /// [postalCode]: The postal code associated with the location.
  /// [countryCode]: The country code of the location.
  /// [latitude]: The latitude coordinate of the location.
  /// [longitude]: The longitude coordinate of the location.
  /// [city]: The city where the location is based.
  /// [state]: The state where the location is based.
  /// [stateCode]: The code of the state.
  /// [province]: The province where the location is based (optional).
  /// [provinceCode]: The code of the province (optional).
  LocationInfo({
    required this.postalCode,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    required this.stateCode,
    this.province,
    this.provinceCode,
  });

  /// The postal code of the location.
  final String postalCode;

  /// ISO 3166-1 alpha-2 country code of the location.
  final String countryCode;

  /// Latitude of the location.
  final String latitude;

  /// Longitude of the location.
  final String longitude;

  /// Name of the city where the location is situated.
  final String city;

  /// Name of the state where the location is situated.
  final String state;

  /// Code of the state where the location is situated.
  final String stateCode;

  /// Name of the province where the location is situated, if applicable.
  final String? province;

  /// Code of the province where the location is situated, if applicable.
  final String? provinceCode;

  /// Creates an instance of [LocationInfo] from a JSON object.
  ///
  /// [json]: The JSON map containing the location details.
  // ignore: sort_constructors_first
  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      postalCode: json['postal_code'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '',
      longitude: json['longitude'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      stateCode: json['state_code'] as String? ?? '',
      province: json['province'] as String?,
      provinceCode: json['province_code'] as String?,
    );
  }
}

/// PostalCodeResults holds a map of postal codes to their corresponding
/// location information.
///
/// This class parses and stores a collection of [LocationInfo] objects
/// for each postal code. It's typically used to represent the results
/// section of a response from the Zipcodebase API.
class PostalCodeResults {
  /// Constructs a [PostalCodeResults] instance with the given map of results.
  PostalCodeResults({required this.results});

  /// A map where each key is a postal code and the value is a list of
  /// [LocationInfo] objects corresponding to that postal code.
  final Map<String, List<LocationInfo>> results;

  /// Creates an instance of [PostalCodeResults] from a JSON object.
  ///
  /// [json]: The JSON map containing the postal code results.
  // ignore: sort_constructors_first
  factory PostalCodeResults.fromJson(Map<String, dynamic> json) {
    final results = <String, List<LocationInfo>>{};

    json.forEach((key, value) {
      if (value is List) {
        final locations = value.map<LocationInfo>((item) {
          return LocationInfo.fromJson(item as Map<String, dynamic>);
        }).toList();

        results[key] = locations;
      } else {
        debugPrint(
          'Something went Wrong in PostalCodeREsults: value is not a list',
        );
      }
    });

    return PostalCodeResults(results: results);
  }
}

/// ZipcodeApiResponse represents the entire response structure returned
/// by the Zipcodebase API.
///
/// This class encapsulates the query details and the results, which include
/// a detailed breakdown of location information for each postal code queried.
class ZipcodeApiResponse {
  /// Constructs a [ZipcodeApiResponse] instance with the given query
  /// details and results.
  ZipcodeApiResponse({required this.query, required this.results});

  /// The query details, typically containing information about the
  /// postal codes and countries queried.

  final Map<String, dynamic> query;

  /// The results of the query in the form of [PostalCodeResults],
  /// which is a map of postal codes to lists of [LocationInfo].
  final PostalCodeResults results;

  /// Creates an instance of [ZipcodeApiResponse] from a JSON object.
  ///
  /// [json]: The JSON map representing the entire API response.
  // ignore: sort_constructors_first
  factory ZipcodeApiResponse.fromJson(Map<String, dynamic> json) {
    return ZipcodeApiResponse(
      query: json['query'] as Map<String, dynamic>,
      results:
          PostalCodeResults.fromJson(json['results'] as Map<String, dynamic>),
    );
  }
}
