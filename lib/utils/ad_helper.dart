import 'package:flutter/foundation.dart';

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
