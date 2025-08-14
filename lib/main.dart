// ignore_for_file: lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:horseandriderscompanion/App/View/app.dart';
import 'package:horseandriderscompanion/App/bloc_observer.dart';
import 'package:horseandriderscompanion/Initialization/ads_initialization.dart';
import 'package:horseandriderscompanion/Initialization/firebase_initialization.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';

late final FirebaseApp app;
late final FirebaseAuth auth;

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (your helper)
  try {
    await FirebaseInitialization.initializeFirebase();
  } catch (e, stack) {
    debugPrint('Firebase initialization failed: $e');
    debugPrintStack(stackTrace: stack);
  }

  // Initialize Google Sign-In v7 ONCE:
  // - clientId (iOS/macOS): your iOS Client ID
  // - serverClientId (native platforms): your Web Client ID
  try {
    await GoogleSignIn.instance.initialize(
      clientId:
          '854658032014-q869gh7ekm1n0rahk51vc927j8v5m2o8.apps.googleusercontent.com',
      serverClientId:
          '854658032014-hlrq1mf9jkv4qv0fkj59h7un5cfddnet.apps.googleusercontent.com',
    );
  } catch (e) {
    // Safe to ignore if already initialized elsewhere or provided via plist
    debugPrint('GoogleSignIn initialize skipped/failed: $e');
  }

  // Pretty URLs for Flutter web
  usePathUrlStrategy();

  // Keep splash screen displayed during init
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // App services
  await SharedPrefs().init();
  await AdsInitialization.initializeAds();

  // Remove splash
  FlutterNativeSplash.remove();

  // Observe BLoC transitions in debug
  Bloc.observer = AppBlocObserver();

  // Create repositories
  final messagesRepository = MessagesRepository();
  final skillTreeRepository = SkillTreeRepository();
  final resourcesRepository = ResourcesRepository();
  final riderProfileRepository = RiderProfileRepository();
  final horseProfileRepository = HorseProfileRepository();

  // Auth repo—uses FirebaseAuth + GoogleSignIn singleton
  final authenticationRepository = AuthenticationRepository(
    firebaseAuth: FirebaseAuth.instance,
    // You can inject GoogleSignIn.instance explicitly if you prefer:
    // googleSignIn: GoogleSignIn.instance,
  );

  // Helpful debug log whenever auth state changes
  authenticationRepository.user.listen((value) {
    debugPrint('User is $value');
  });

  // Load user settings
  final settingsController = SettingsController(SettingsService());
  await settingsController.loadSettings();

  // Boot the app
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
