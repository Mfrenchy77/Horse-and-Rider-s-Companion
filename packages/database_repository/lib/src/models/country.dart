/// Represents a country with an ID, name, and ISO2 code.
// ignore_for_file: sort_constructors_first

class Country {
  /// Constructs a [Country] instance.
  Country({
    required this.id,
    required this.name,
    required this.iso2,
  });

  /// The ID of the country.
  final int id;

  /// The name of the country.
  final String name;

  /// The ISO2 code of the country.
  final String iso2;

  /// Creates a [Country] from a JSON object.
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as int,
      name: json['name'] as String,
      iso2: json['iso2'] as String,
    );
  }
}
