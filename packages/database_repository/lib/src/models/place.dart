import 'package:database_repository/src/models/address.dart';

/// Represents a location place as returned by the Nominatim API.
/// This model captures essential details about a place, including its
/// geographic, address, and additional tag information.
class Place {
  /// Constructs a [Place] instance with the provided details.
  Place({
    this.icon,
    this.extratags,
    this.placeRank,
    required this.type,
    required this.osmId,
    required this.placeId,
    required this.licence,
    required this.osmType,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.importance,
    required this.displayName,
    required this.boundingbox,
  });

  /// Main OSM tag value for the place, indicating the place's type.
  final String type;

  /// URL to an icon representing the place's category, if available.
  final String? icon;

  /// The OSM ID of the object.
  final String osmId;

  /// Search rank of the object, included in JSONv2 format.
  final int? placeRank;

  /// An internal identifier assigned by the Nominatim database.
  /// Note: This ID is not persistent and may change upon data re-import.
  final String placeId;

  /// License information for the data used by Nominatim.
  final String licence;

  /// Type of the OpenStreetMap (OSM) object (node, way, or relation).
  final String osmType;

  /// Detailed breakdown of the address into its components.
  final Address address;

  /// Latitude of the place's centroid.
  final double latitude;

  /// Main OSM tag key for the place, renamed to 'category' in JSONv2 format.
  final String category;

  /// Longitude of the place's centroid.
  final double longitude;

  /// Computed importance rank of the place,
  ///  helping to determine relevance in search.
  final double importance;

  /// Full, comma-separated address of the place.
  final String displayName;

  /// Geographic bounding box surrounding the place,
  ///  represented by corner coordinates.
  final List<String> boundingbox;

  /// Additional tags providing extra information about the place,
  ///  like website or population.
  final Map<String, String>? extratags;

  /// Constructs a [Place] instance from a JSON map.
  // ignore: sort_constructors_first
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      type: json['type'] as String,
      icon: json['icon'] as String?,
      osmId: json['osm_id'] as String,
      category: json['class'].toString(), // Adapt based on JSON vs JSONv2
      licence: json['licence'] as String,
      osmType: json['osm_type'] as String,
      placeId: json['place_id'] as String,
      placeRank: json['place_rank'] as int?,
      importance: json['importance'] as double,
      displayName: json['display_name'] as String,
      latitude: double.parse(json['lat'] as String),
      longitude: double.parse(json['lon'] as String),
      address: Address.fromJson(json['address'] as Map<String, String>),
      boundingbox: List<String>.from(json['boundingbox'] as List<dynamic>),
      extratags: (json['extratags'] as Map?)
          ?.map((key, value) => MapEntry(key.toString(), value.toString())),
    );
  }
}
