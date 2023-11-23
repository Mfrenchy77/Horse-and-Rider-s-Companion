import 'package:flutter/material.dart';

class InformationDialog {
  static void show(
    BuildContext context,
    Text contentText,
    Offset position,
  ) {
    // Removed the fixed dialogHeight

    final screenSize = MediaQuery.of(context).size;

    final dialogWidth = screenSize.width * 0.4;
    var adjustedX = position.dx;
    final adjustedY = position.dy;

    if (adjustedX + dialogWidth > screenSize.width) {
      adjustedX = screenSize.width - dialogWidth;
    }

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (overlayEntry != null) {
                  overlayEntry.remove();
                }
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          Positioned(
            top: adjustedY,
            left: adjustedX,
            child: Card(
              elevation: 4,
              child: Container(
                width: dialogWidth,
                padding: const EdgeInsets.all(20),
                // Wrap the contentText in a Wrap widget
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [contentText],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }
}
