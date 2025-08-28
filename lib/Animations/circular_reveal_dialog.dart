import 'dart:math';
import 'package:flutter/material.dart';

Future<T?> showCircularRevealDialog<T>({
  required BuildContext context,
  required Offset centerGlobal,
  required WidgetBuilder builder,
  Duration duration = const Duration(milliseconds: 420),
  Color barrierColor = Colors.black54,
  bool barrierDismissible = true,
}) {
  final overlayBox =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final center = overlayBox.globalToLocal(centerGlobal);
  final size = overlayBox.size;

  double maxRadius() {
    final tl = (center - Offset.zero).distance;
    final tr = (center - Offset(size.width, 0)).distance;
    final bl = (center - Offset(0, size.height)).distance;
    final br = (center - Offset(size.width, size.height)).distance;
    return [tl, tr, bl, br].reduce(max);
  }

  final endRadius = maxRadius();

  return showGeneralDialog<T>(
    context: context,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    transitionDuration: duration,
    pageBuilder: (context, _, __) {
      // Fill the screen so the clip path has full canvas to reveal.
      return SizedBox.expand(
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: builder(context),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final radius =
          Tween<double>(begin: 0, end: endRadius).transform(curved.value);

      return ClipPath(
        clipper: _CircularRevealClipper(center: center, radius: radius),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}

class _CircularRevealClipper extends CustomClipper<Path> {
  _CircularRevealClipper({required this.center, required this.radius});
  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircularRevealClipper old) =>
      old.radius != radius || old.center != center;
}
