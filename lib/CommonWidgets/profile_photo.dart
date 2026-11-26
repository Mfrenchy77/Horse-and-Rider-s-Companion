import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:photo_view/photo_view.dart';

class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    required this.size,
    this.profilePicUrl,
    this.heroTag,
  });

  final double size;
  final String? profilePicUrl;
  // Optional hero tag; if null, no hero animation will be used
  // (defaults to using profilePicUrl when available).
  // Keeping this so callers can override if needed in special cases.
  final String? heroTag;
  @override
  Widget build(BuildContext context) {
    final isDark = SharedPrefs().isDarkMode;
    // Compute a stable hero tag: prefer provided heroTag, otherwise derive
    // from the profilePicUrl. Use a short, stable string to avoid issues
    // with very long URLs and to ensure uniqueness per profile.
    final computedHeroTag = () {
      if (heroTag != null && heroTag!.isNotEmpty) return heroTag;
      if (profilePicUrl != null && profilePicUrl!.isNotEmpty) {
        return 'profilePic-${profilePicUrl.hashCode}';
      }
      return null;
    }();
    return profilePicUrl != null && profilePicUrl!.isNotEmpty
        ? Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => showProfilePhoto(
                context,
                profilePicUrl!,
                heroTag: computedHeroTag,
              ),
              child: CircleAvatar(
                radius: size / 3,
                backgroundColor: Colors.grey,
                backgroundImage: NetworkImage(profilePicUrl!),
              ),
            ),
          )
        : CircleAvatar(
            radius: size / 3,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage(
              isDark
                  ? 'assets/horse_icon_circle_dark.png'
                  : 'assets/horse_icon_circle.png',
            ),
          );
  }
}

/// Opens the full photo with pinch-to-zoom and optional educational metadata.
Future<void> showProfilePhoto(
  BuildContext context,
  String url, {
  String? heroTag,
  String? caption,
  String? explanation,
  String? imageTypeLabel,
  String? attribution,
}) {
  final hasMetadata = [
    caption,
    explanation,
    imageTypeLabel,
    attribution,
  ].any((value) => value != null && value.trim().isNotEmpty);

  return showAppGlassDialog<void>(
    context: context,
    builder: (context) => Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: .5),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: caption != null && caption.trim().isNotEmpty
            ? Text(
                caption.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              )
            : null,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: PhotoView(
              minScale: PhotoViewComputedScale.contained * 0.8,
              heroAttributes: heroTag == null
                  ? null
                  : PhotoViewHeroAttributes(
                      tag: heroTag,
                      transitionOnUserGestures: true,
                    ),
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              imageProvider: NetworkImage(url),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.white70,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Unable to load image',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (hasMetadata)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Container(
                      key: const Key('immersivePhotoMetadataOverlay'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          if (imageTypeLabel != null &&
                              imageTypeLabel.trim().isNotEmpty)
                            Text(
                              imageTypeLabel.trim(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (caption != null && caption.trim().isNotEmpty)
                            Text(
                              caption.trim(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (explanation != null &&
                              explanation.trim().isNotEmpty)
                            Text(
                              explanation.trim(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          if (attribution != null &&
                              attribution.trim().isNotEmpty)
                            Text(
                              'Contributed by ${attribution.trim()}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
