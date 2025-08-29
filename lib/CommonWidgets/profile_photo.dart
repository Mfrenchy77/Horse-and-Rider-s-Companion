import 'package:flutter/material.dart';
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
              onTap: () => showDialog<AlertDialog>(
                context: context,
                builder: (context) {
                  return Scaffold(
                    backgroundColor: Colors.transparent,
                    appBar: AppBar(
                      backgroundColor: Colors.black.withValues(alpha: .5),
                      leading: IconButton(
                        icon: const Icon(Icons.close),
                        // Use maybePop to avoid accidentally popping the last
                        // app route if this dialog is presented as an overlay.
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      elevation: 0,
                    ),
                    body: PhotoView(
                      minScale: PhotoViewComputedScale.contained * 0.8,
                      heroAttributes: computedHeroTag != null
                          ? PhotoViewHeroAttributes(
                              tag: computedHeroTag,
                              transitionOnUserGestures: true,
                            )
                          : null,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      imageProvider: NetworkImage(profilePicUrl!),
                    ),
                  );
                },
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
