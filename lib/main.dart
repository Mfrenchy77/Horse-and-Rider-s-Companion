// ignore_for_file: lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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
  Bloc.observer = AppBlocObserver();
  await FirebaseInitialization.initializeFirebase();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SharedPrefs().init();
  await AdsInitialization.initializeAds();
  FlutterNativeSplash.remove();

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
