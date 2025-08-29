// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:horseandriderscompanion/App/bloc_observer.dart';
import 'package:horseandriderscompanion/Initialization/ads_initialization.dart';
import 'package:horseandriderscompanion/Initialization/firebase_initialization.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (helper encapsulates platform setup)
  try {
    await FirebaseInitialization.initializeFirebase();
  } catch (e, stack) {
    debugPrint('Firebase initialization failed: $e');
    debugPrintStack(stackTrace: stack);
  }

  // Initialize Google Sign-In once (v7 API)
  try {
    await GoogleSignIn.instance.initialize(
      clientId:
          '854658032014-q869gh7ekm1n0rahk51vc927j8v5m2o8.apps.googleusercontent.com',
      serverClientId:
          '854658032014-hlrq1mf9jkv4qv0fkj59h7un5cfddnet.apps.googleusercontent.com',
    );
  } catch (e) {
    // Safe to ignore if already initialized elsewhere or provided via plist/json
    debugPrint('GoogleSignIn initialize skipped/failed: $e');
  }

  // Pretty URLs for Flutter web
  usePathUrlStrategy();

  // Keep splash screen during init
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // App services
  await SharedPrefs().init();
  await AdsInitialization.initializeAds();

  // Remove splash once ready
  FlutterNativeSplash.remove();

  // Observe BLoC transitions in debug
  Bloc.observer = AppBlocObserver();

  // Run the app
  final root = await builder();
  runApp(root);
}
