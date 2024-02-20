import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsInitialization {
  static Future<void> initializeAds() async {
    try {
      debugPrint('defaultTargetPlatform: $defaultTargetPlatform');
      if (kIsWeb) {
        debugPrint('Launching Ads on WEB');
        // Implement web-specific ads initialization here
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android) {
        debugPrint('Launching Ads on Mobile');
        await MobileAds.instance.initialize();
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: ['E7C14B0D4151AA33B08FEE7522155C21'],
          ),
        );
      } else if (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows) {
        // Implement desktop-specific ads initialization or handling here
        debugPrint('Ads not supported on this platform');
      }
    } catch (e) {
      debugPrint('Error initializing ads: $e');
    }
  }
}
