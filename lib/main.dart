import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
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

  try {
    await Firebase.initializeApp(
      // name: "Horse and Rider's Companion",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing firebase: $e');
  }

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
