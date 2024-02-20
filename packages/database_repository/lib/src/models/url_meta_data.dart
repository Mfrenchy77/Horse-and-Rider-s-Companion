import 'package:equatable/equatable.dart';

/// a class that represents the url meta data
class UrlMetadata extends Equatable {
  /// a class that represents the url meta data
  const UrlMetadata({
    required this.url,
    required this.title,
    required this.domain,
    required this.duration,
    required this.imageUrls,
    required this.description,
  });

  /// The URL itself.
  final String url;

  /// The title of the URL.
  final String title;

  /// The duration of the URL.
  final int duration;

  /// The domain of the URL.
  final String domain;

  /// The description of the URL.
  final String description;

  /// The list of image URLs associated with the URL.
  final List<String?> imageUrls;

  /// Converts the [UrlMetadata] to a JSON object.
  // ignore: sort_constructors_first
  factory UrlMetadata.fromJson(Map<String, dynamic> json) => UrlMetadata(
        url: json['url'] as String,
        title: json['title'] as String,
        domain: json['domain'] as String,
        duration: json['duration'] as int,
        description: json['description'] as String,
        imageUrls:
            (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      );

  @override
  List<Object?> get props => [
        url,
        title,
        domain,
        duration,
        imageUrls,
        description,
      ];
}
