// ignore_for_file: omit_local_variable_types, prefer_final_locals

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:universal_html/html.dart';

class AdHelper {
  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      debugPrint('This is causeing the crash on web');
      // TODO(mfrenchy77): implement Web ad here
      throw UnsupportedError('Unsupported platform');
    }
  }
}

class WebAdBanner extends StatelessWidget {
  WebAdBanner({super.key}) {
    // Register the HTML factory
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => IFrameElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..src = 'adsense.html'
        ..style.border = 'none',
    );
  }
  final String viewType = 'adsense-html-container';

  @override
  Widget build(BuildContext context) {
    // Getting screen width
    final screenWidth = MediaQuery.of(context).size.width;
    // Determine size based on the screen width
    double adWidth = screenWidth > 728 ? 728 : screenWidth;
    double adHeight = screenWidth > 728
        ? 90
        : 50; // Adjust height proportionally or by another logic

    return Center(
      child: SizedBox(
        width: adWidth,
        height: adHeight,
        child: HtmlElementView(
          viewType: viewType,
        ),
      ),
    );
  }
}
