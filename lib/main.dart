// ignore_for_file: lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:horseandriderscompanion/App/View/app.dart';
import 'package:horseandriderscompanion/App/bloc_observer.dart';
import 'package:horseandriderscompanion/Initialization/ads_initialization.dart';
import 'package:horseandriderscompanion/Initialization/firebase_initialization.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

late final FirebaseApp app;
late final FirebaseAuth auth;
final localhostServer = InAppLocalhostServer(documentRoot: 'assets');
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitialization.initializeFirebase();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    debugPrint('Setting up WebView for Android');
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    debugPrint('Setting up WebView for iOS');
  } else if (kIsWeb) {
    debugPrint('Setting up WebView for Web');
  } else if (defaultTargetPlatform == TargetPlatform.macOS) {
    debugPrint('Setting up WebView for macOS');
  } else if (defaultTargetPlatform == TargetPlatform.windows) {
    debugPrint('Setting up WebView for Windows');
  } else if (defaultTargetPlatform == TargetPlatform.linux) {
    debugPrint('Setting up WebView for Linux');
  }

  debugPrint('Targer Platform is $defaultTargetPlatform');

  if (!kIsWeb) {
    debugPrint('Setting up localhost server for Web View');
    await localhostServer.start();
  }
  usePathUrlStrategy();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SharedPrefs().init();
  await AdsInitialization.initializeAds();
  FlutterNativeSplash.remove();
  Bloc.observer = AppBlocObserver();

  final messagesRepository = MessagesRepository();
  final skillTreeRepository = SkillTreeRepository();
  final resourcesRepository = ResourcesRepository();
  final riderProfileRepository = RiderProfileRepository();
  final horseProfileRepository = HorseProfileRepository();
  final authenticationRepository = AuthenticationRepository();

  authenticationRepository.user.listen((value) {
    debugPrint('User is $value');
  });
  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();
  runApp(
    App(
      messagesRepository: messagesRepository,
      settingsController: settingsController,
      skillTreeRepository: skillTreeRepository,
      resourcesRepository: resourcesRepository,
      riderProfileRepository: riderProfileRepository,
      horseProfileRepository: horseProfileRepository,
      authenticationRepository: authenticationRepository,
    ),
  );
}
