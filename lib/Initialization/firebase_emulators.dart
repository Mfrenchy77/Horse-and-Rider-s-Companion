import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseEmulators {
  static const enabled =
      kIsWeb && kDebugMode && bool.fromEnvironment('FIREBASE_EMULATORS');
  static const projectId = 'demo-horse-rules';

  static const _host = '127.0.0.1';

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:1234567890:web:1234567890abcdef',
        messagingSenderId: '1234567890',
        projectId: projectId,
      ),
    );
    await FirebaseAuth.instance.useAuthEmulator(_host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_host, 8080);
  }

  static Uri coachingEndpoint() =>
      Uri.http('$_host:5001', '/$projectId/us-central1/coachingConnection');
}
