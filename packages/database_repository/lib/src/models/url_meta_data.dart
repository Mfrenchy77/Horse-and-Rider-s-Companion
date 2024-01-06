import 'package:equatable/equatable.dart';

/// a class that represents the url meta data
class UrlMetadata extends Equatable {
  /// a class that represents the url meta data
  const UrlMetadata({
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.duration,
    required this.domain,
    required this.url,
  });

  /// The title of the URL.
  final String title;

  /// The description of the URL.
  final String description;

  /// The list of image URLs associated with the URL.
  final List<String?> imageUrls;

  /// The duration of the URL.
  final int duration;

  /// The domain of the URL.
  final String domain;

  /// The URL itself.
  final String url;

  /// Converts the [UrlMetadata] to a JSON object.
  // ignore: sort_constructors_first
  factory UrlMetadata.fromJson(Map<String, dynamic> json) => UrlMetadata(
        title: json['title'] as String,
        description: json['description'] as String,
        imageUrls: (json['images'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        duration: json['duration'] as int,
        domain: json['domain'] as String,
        url: json['url'] as String,
      );

  @override
  List<Object?> get props => [
        title,
        description,
        imageUrls,
        duration,
        domain,
        url,
      ];
}
