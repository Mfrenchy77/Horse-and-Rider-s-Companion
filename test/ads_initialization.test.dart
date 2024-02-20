import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Initialization/ads_initialization.dart';

void main() {
  group('Ads Initialization', () {
    test('Google Mobile Ads SDK initializes successfully', () async {
      expect(
        () async {
          await AdsInitialization.initializeAds();
        },
        returnsNormally,
      );
    });
  });
}
