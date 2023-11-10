import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class TransitionAppBar extends StatelessWidget {
  const TransitionAppBar({
    required this.avatar,
    required this.title,
    this.extent = 250,
    super.key,
  });

  final Widget avatar;
  final double extent;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TransitionAppBarDelegate(
        avatar: avatar,
        title: title,
        extent: extent > 200 ? extent : 200,
      ),
    );
  }
}

class _TransitionAppBarDelegate extends SliverPersistentHeaderDelegate {
  _TransitionAppBarDelegate({
    required this.avatar,
    required this.title,
    this.extent = 250,
  }) : assert(extent >= 200, '');

  final Widget avatar;
  final double extent;
  final String title;

  final _avatarAlignTween =
      AlignmentTween(begin: Alignment.bottomCenter, end: Alignment.topLeft);
  final _avatarMarginTween = EdgeInsetsTween(
    end: const EdgeInsets.only(left: 14, top: 36),
  );

  final _iconAlignTween =
      AlignmentTween(begin: Alignment.bottomRight, end: Alignment.topRight);
  final _titleMarginTween = EdgeInsetsTween(
    begin: const EdgeInsets.only(bottom: 20),
    end: const EdgeInsets.only(left: 64, top: 45),
  );

  @override
  double get maxExtent => extent;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(_TransitionAppBarDelegate oldDelegate) {
    return avatar != oldDelegate.avatar || title != oldDelegate.title;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tempVal = maxExtent * 72 / 100;
    final progress = shrinkOffset > tempVal ? 1.0 : shrinkOffset / tempVal;
    final avatarMargin = _avatarMarginTween.lerp(progress);
    final titleMargin = _titleMarginTween.lerp(progress);

    final avatarAlign = _avatarAlignTween.lerp(progress);
    final iconAlign = _iconAlignTween.lerp(progress);

    final avatarSize = (1 - progress) * 200 + 32;

    return Stack(
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 100,
          constraints: BoxConstraints(maxHeight: minExtent),
          color: HorseAndRidersTheme().getTheme().appBarTheme.backgroundColor,
        ),
       
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            height: progress < 0.4 ? 100 * (1 - progress) * 1.5 : 0,
            decoration: BoxDecoration(
              color: HorseAndRidersTheme()
                  .getTheme()
                  .appBarTheme
                  .backgroundColor,
              image: const DecorationImage(
                image: AssetImage(
                  'assets/horse_background.png',
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Padding(
          padding: titleMargin,
          child: Align(
            alignment: avatarAlign,
            child: Text(
              title,
            ),
          ),
        ),
        Padding(
          padding: titleMargin,
          child: Align(
            alignment: iconAlign,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {},
                child: Icon(
                  Icons.search,
                  size: 30,
                  color: progress < 0.4 ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
         Padding(
          padding: avatarMargin,
          child: Align(
            alignment: avatarAlign,
            child: SizedBox(
              height: avatarSize,
              width: avatarSize,
              child: avatar,
            ),
          ),
        ),
      ],
    );
  }
}
