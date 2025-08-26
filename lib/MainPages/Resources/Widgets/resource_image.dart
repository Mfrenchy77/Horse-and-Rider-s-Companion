import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';

class ResourceImage extends StatelessWidget {
  const ResourceImage({super.key, required this.url, this.size = 150});
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Image.asset(
        'assets/horse_logo_and_text_dark.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SmartImage(
        url,
        maxLogicalWidth: 480,
        config: const SmartImageConfig(
          forceWebP: true,
          domainS3Buckets: {
            // maps WordPress domain -> S3 bucket name
            'practicalhorsemanmag.com': 'wp-s3-practicalhorsemanmag.com',
          },
          // Optional: if you’ve discovered a version segment for some files
          domainExtraSegmentGuesses: {
            'practicalhorsemanmag.com': ['14143428'],
          },
        ),
      ),
    );
  }
}
