import 'package:flutter/material.dart';

class RoundedRectIndicator extends Decoration {
  RoundedRectIndicator({
    required Color color,
    required double radius,
    double padding = 0.0,
    double weight = 3.0,
  }) : _painter = _RectPainter(color, radius, padding, weight);
  final BoxPainter _painter;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _painter;
  }
}

class _RectPainter extends BoxPainter {
  _RectPainter(Color color, this.radius, this.padding, this.weight)
      : _paint = Paint()
          ..color = color
          ..isAntiAlias = true;
  final Paint _paint;
  final double radius;
  final double padding;
  final double weight;
  final indicatorPaddingBottom = 4.0;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final width = cfg.size!.width;
    final height = cfg.size!.height;

    var left = 0.0;
    final top = height - indicatorPaddingBottom;
    var right = width;
    final bottom = height - weight - indicatorPaddingBottom;

    //calculate offset
    left = left + offset.dx + padding;
    right = right + offset.dx - padding;

    final rect = RRect.fromLTRBAndCorners(
      left,
      top,
      right,
      bottom,
      topLeft: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
    canvas.drawRRect(rect, _paint);
  }
}
