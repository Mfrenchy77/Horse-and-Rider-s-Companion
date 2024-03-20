import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:horseandriderscompanion/firebase_options.dart';

class FirebaseInitialization {
  static Future<void> initializeFirebase() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp(
     //   name: 'Horse & Riders Companion',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase Initialized Successfully');
    } catch (e) {
      // If Firebase initialization fails, debugPrint an error message
      // or handle it as needed.
      debugPrint('Error initializing Firebase: $e');
    }
  }
}
