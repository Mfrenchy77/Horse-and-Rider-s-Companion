/// Represents a city.
///
/// This model contains the basic information about a city,
/// including its unique identifier and name.
// ignore_for_file: sort_constructors_first

class City {
  /// Constructs a [City] instance from the given [id] and [name].
  City({required this.id, required this.name});

  /// The unique identifier of the city.
  final int id;

  /// The name of the city.
  final String name;

  /// Creates a [City] instance from a JSON object.
  ///
  /// The JSON object should contain 'id' and 'name' fields.
  /// [json]: The JSON object to parse.
  ///
  /// Returns a new [City] instance based on the JSON object.
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
