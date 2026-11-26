import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:horseandriderscompanion/Utilities/app_logger.dart';

class AdsInitialization {
  static Future<void> initializeAds() async {
    try {
      if (kIsWeb) return; // AdSense is initialized by the web entry point.
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android) {
        AppLogger.info(LogCategory.ads, 'Initializing mobile ads');
        await MobileAds.instance.initialize();
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: ['E7C14B0D4151AA33B08FEE7522155C21'],
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows) {
        AppLogger.debug(
          LogCategory.ads,
          'Mobile ads unsupported on $defaultTargetPlatform',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        LogCategory.ads,
        'Error initializing ads',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
