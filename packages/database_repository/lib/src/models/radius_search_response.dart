/// Represents the response from a radius search query to the Zipcodebase API.
///
/// This class holds a list of postal codes that are within a specified radius
/// from a given postal code. It provides a convenient way to parse and
/// access the postal codes from the JSON response returned by the API.
class RadiusSearchResponse {
  /// Constructs a [RadiusSearchResponse] instance with a list of postal codes.
  RadiusSearchResponse({required this.postalCodes});

  /// Factory constructor that creates a [RadiusSearchResponse] from JSON data.
  ///
  /// Parses the 'codes' key from the provided JSON map to extract a list of
  /// postal codes. If the 'codes' key does not exist or is not a list, an
  /// empty list of postal codes is assigned.
  ///
  /// [json]: The JSON map containing the radius search results.
  factory RadiusSearchResponse.fromJson(Map<String, dynamic> json) {
    // Explicitly cast the JSON 'codes' value to a list of dynamic and then
    // map each element to a string. If 'codes' is not a list, initialize
    // postalCodes with an empty list.
    var postalCodes = <String>[];
    if (json['codes'] is List) {
      postalCodes = (json['codes'] as List).map((e) => e.toString()).toList();
    }
    return RadiusSearchResponse(postalCodes: postalCodes);
  }

  /// A list of postal codes found within the specified radius.
  final List<String> postalCodes;
}
