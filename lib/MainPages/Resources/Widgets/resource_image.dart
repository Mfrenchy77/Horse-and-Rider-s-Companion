import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';

class ResourceImage extends StatelessWidget {
  const ResourceImage({
    super.key,
    required this.url,
    this.resourceUrl,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final String url;
  final String? resourceUrl;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Image.asset(
        'assets/horse_logo.png',
        fit: BoxFit.contain,
        semanticLabel: 'Preview unavailable. Horse & Rider logo.',
      ),
    );

    return SizedBox(
      width: 200,
      height: 150,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: url.trim().isEmpty
            ? fallback
            : SmartImage(
                url,
                resourceUrl: resourceUrl,
                fallback: fallback,
                maxLogicalWidth: 480,
                config: const SmartImageConfig(forceWebP: true),
              ),
      ),
    );
  }
}
