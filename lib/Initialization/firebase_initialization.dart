import 'package:firebase_core/firebase_core.dart';
import 'package:horseandriderscompanion/Utilities/app_logger.dart';
import 'package:horseandriderscompanion/firebase_options.dart';

class FirebaseInitialization {
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
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
