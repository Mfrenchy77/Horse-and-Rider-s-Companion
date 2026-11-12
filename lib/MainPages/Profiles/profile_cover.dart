import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';

class ProfileCover extends StatelessWidget {
  const ProfileCover({
    super.key,
    required this.name,
    required this.photoUrl,
    required this.locationName,
    required this.photoKey,
    this.status,
    this.ribbon,
  });

  final String name;
  final String? photoUrl;
  final String? locationName;
  final Key photoKey;
  final String? status;
  final Widget? ribbon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photo = photoUrl?.trim() ?? '';
    final location = locationName?.trim() ?? '';
    final scrim = Color.alphaBlend(
      theme.colorScheme.surface.withValues(alpha: .15),
      Colors.black,
    );
    final fallback = Align(
      alignment: const Alignment(0, -.45),
      child: FractionallySizedBox(
        widthFactor: .5,
        heightFactor: .62,
        child: Image.asset(
          'assets/horse_logo.png',
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );

    return GradientCard(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: (constraints.maxWidth * .63).clamp(220.0, 380.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo.isEmpty)
                fallback
              else
                Image.network(
                  photo,
                  key: photoKey,
                  fit: BoxFit.cover,
                  semanticLabel: 'Photo of $name',
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  frameBuilder: (context, child, frame, synchronouslyLoaded) {
                    if (frame == null) return child;
                    return Tooltip(
                      message: 'View full photo',
                      child: InkWell(
                        onTap: () => showProfilePhoto(context, photo),
                        child: child,
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => fallback,
                ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, scrim],
                      stops: const [.26, 1],
                    ),
                  ),
                ),
              ),
              if (ribbon case final coverRibbon?)
                Positioned(
                  top: 0,
                  left: 0,
                  child: IgnorePointer(child: coverRibbon),
                ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          status!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 17,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                location,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
