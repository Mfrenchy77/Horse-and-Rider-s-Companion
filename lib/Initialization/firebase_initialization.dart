import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:horseandriderscompanion/Utilities/app_logger.dart';
import 'package:horseandriderscompanion/firebase_options.dart';

class FirebaseInitialization {
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      } catch (e, stackTrace) {
        AppLogger.warning(
          LogCategory.app,
          'Firestore persistence configuration skipped',
          error: e,
          stackTrace: stackTrace,
        );
      }
      AppLogger.info(LogCategory.app, 'Firebase initialized');
    } catch (e, stackTrace) {
      AppLogger.error(
        LogCategory.app,
        'Error initializing Firebase',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
