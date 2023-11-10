import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class ProfileHeader extends SliverPersistentHeaderDelegate {
  ProfileHeader({
    required this.imageUrl,
    required this.title,
  });

  final String? imageUrl;
  final String title;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = shrinkOffset / maxExtent;
    return Material(
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: progress,
            duration: const Duration(milliseconds: 150),
            child: ColoredBox(
              color: HorseAndRidersTheme()
                      .getTheme()
                      .appBarTheme
                      .backgroundColor ??
                  Colors.black,
            ),
          ),
          AnimatedOpacity(
            opacity: 1 - progress,
            duration: const Duration(milliseconds: 150),
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/horse_background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.lerp(
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              const EdgeInsets.only(bottom: 16),
              progress,
            ),
            alignment: Alignment.lerp(
              Alignment.bottomLeft,
              Alignment.bottomCenter,
              progress,
            ),
            child: Text(
              title,
              style: TextStyle.lerp(
                const TextStyle(fontSize: 30),
                const TextStyle(fontSize: 20),
                progress,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 264;

  @override
  double get minExtent => 84;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
