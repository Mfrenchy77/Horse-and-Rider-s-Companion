import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Initialization/firebase_initialization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Initialization', () {
    test('Firebase initializes successfully', () async {
      expect(
        () async {
          await FirebaseInitialization.initializeFirebase();
        },
        returnsNormally,
      );
    });
  });
}
