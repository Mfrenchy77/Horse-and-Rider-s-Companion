/// Model for a State.
// ignore_for_file: sort_constructors_first

class StateLocation {
  /// Constructs a [StateLocation] instance.
  StateLocation({
    required this.id,
    required this.name,
    required this.countryId,
    required this.countryCode,
    required this.iso2,
  });

  /// The id of the state.
  final int id;

  /// The name of the state.
  final String name;

  /// The id of the country.
  final int countryId;

  /// The country code.
  final String countryCode;

  /// The ISO2 code of the state.
  final String iso2;

  /// Creates a [StateLocation] from a JSON object.
  factory StateLocation.fromJson(Map<String, dynamic> json) {
    return StateLocation(
      id: json['id'] as int,
      name: json['name'] as String,
      countryId: json['country_id'] as int,
      countryCode: json['country_code'] as String,
      iso2: json['iso2'] as String,
    );
  }
}
