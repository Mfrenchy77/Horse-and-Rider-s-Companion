// ignore_for_file: lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:horseandriderscompanion/App/View/app.dart';
import 'package:horseandriderscompanion/App/bloc_observer.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/firebase_options.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';

late final FirebaseApp app;
late final FirebaseAuth auth;

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await FirebaseAppCheck.instance.activate(
  //   // You can also use a `ReCaptchaEnterpriseProvider` provider instance as an
  //   // argument for `webProvider`
  //   webProvider:
  //       ReCaptchaV3Provider('6LeFXhwpAAAAAFgd08o3AW1cnwkGryOd6zzX1cVl'),
  //   // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
  //   // your preferred provider. Choose from:
  //   // 1. Debug provider
  //   // 2. Safety Net provider
  //   // 3. Play Integrity provider
  //   androidProvider: AndroidProvider.debug,
  //   // Default provider for iOS/macOS is the Device Check provider. You can use the "AppleProvider" enum to choose
  //   // your preferred provider. Choose from:
  //   // 1. Debug provider
  //   // 2. Device Check provider
  //   // 3. App Attest provider
  //   // 4. App Attest provider with fallback to Device Check provider (App Attest provider is only available on iOS 14.0+, macOS 14.0+)
  //   appleProvider: AppleProvider.debug,
  // );

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SharedPrefs().init();

  try {
    debugPrint('defaultTargetPlatform: $defaultTargetPlatform');
    if (kIsWeb) {
      // TODO(mfrenchy77): this is where we will set web specific ads
      debugPrint('Lauching Ads on WEB');
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      /// this is where we will set mobile specific ads

      debugPrint('Launchin  Ads on Mobile');
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ['E7C14B0D4151AA33B08FEE7522155C21'],
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows) {
      // Some desktop specific code there
    } else {
      debugPrint('Something went wrong with ads');
    }
  } catch (e) {
    debugPrint('Error initializing ads: $e');
  }

  FlutterNativeSplash.remove();

  //auth = FirebaseAuth.instanceFor(app: app);

  Bloc.observer = AppBlocObserver();
  final authenticationRepository = AuthenticationRepository();
  await authenticationRepository.user.first.then((value) {
    debugPrint('User is $value');
  });
  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();
  runApp(
    App(
      // auth: auth,
      settingsController: settingsController,
      authenticationRepository: authenticationRepository,
    ),
  );
}
