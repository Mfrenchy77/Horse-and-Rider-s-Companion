/// Represents the structured address details of a location place.
/// This model allows for easy access to individual components of an address,
/// such as city, state, and country.
class Address {
  /// Constructs an instance of [Address] with the provided components.
  Address({
    this.city,
    this.state,
    this.country,
    this.postcode,
    this.countryCode,
    this.stateDistrict,
  });

  /// The city component of the address.
  final String? city;

  /// The state component of the address.
  final String? state;

  /// The country name component of the address.
  final String? country;

  /// The postal code component of the address.
  final String? postcode;

  /// The country code component of the address
  /// , typically in ISO 3166-1 alpha-2 format.
  final String? countryCode;

  /// The state district component of the address.
  final String? stateDistrict;

  /// Constructs an [Address] instance from a JSON map.
  // ignore: sort_constructors_first
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postcode: json['postcode'] as String?,
      countryCode: json['country_code'] as String?,
      stateDistrict: json['state_district'] as String?,
    );
  }
}
