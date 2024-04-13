import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
        ..width = '100%'
        ..height = '100%'
        ..src = 'adsense.html'
        ..style.border = 'none',
    );
  }
  final String viewType = 'adsense-html-container';
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 75,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      child: HtmlElementView(
        viewType: viewType,
      ),
    );
  }
}
