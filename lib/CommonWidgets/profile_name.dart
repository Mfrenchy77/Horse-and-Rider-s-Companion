import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

/// The name of the profile being viewed.
class ProfileName extends StatelessWidget {
  const ProfileName({
    super.key,
    this.name,
    this.profilePicUrl,
  });
  final String? name;
  final String? profilePicUrl;
  @override
  Widget build(BuildContext context) {
    final appBarColor =
        Theme.of(context).appBarTheme.backgroundColor ?? Colors.white;
    // return BlocBuilder<AppCubit, AppState>(
    //   builder: (context, state) {
    if (name != null) {
      return Row(
        children: [
          Expanded(
            child: ColoredBox(
              color: appBarColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Photo
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: CircleBorder(),
                      ),
                      child: () {
                        final tag =
                            (profilePicUrl != null && profilePicUrl!.isNotEmpty)
                                ? 'profilePic-${profilePicUrl.hashCode}'
                                : null;
                        if (tag != null) {
                          return Hero(
                            transitionOnUserGestures: true,
                            tag: tag,
                            child: ProfilePhoto(
                              size: 100,
                              profilePicUrl: profilePicUrl,
                              heroTag: tag,
                            ),
                          );
                        }
                        return ProfilePhoto(
                          size: 100,
                          profilePicUrl: profilePicUrl,
                        );
                      }(),
                    ),
                  ),
                  if (name != null && name!.isNotEmpty)
                    Hero(
                      transitionOnUserGestures: true,
                      tag: 'profileName-${name.hashCode}',
                      child: Text(
                        name!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: ColoredBox(
              color: HorseAndRidersTheme()
                      .getTheme()
                      .appBarTheme
                      .backgroundColor ??
                  Colors.white,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Welcome, Guest',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
