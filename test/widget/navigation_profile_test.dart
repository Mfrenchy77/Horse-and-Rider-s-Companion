import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(Keys.reset);

  setUpAll(() async {
    // Provide a mock SharedPreferences instance for tests and initialize
    // the app SharedPrefs singleton so widgets can read preferences.
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
  });

  testWidgets('navigate between profile pages without key collisions',
      (tester) async {
    final pageA = Scaffold(
      appBar: AppBar(title: const Text('A')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ProfilePhoto(size: 120),
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/b'),
                  child: const Text('Go B'),
                );
              },
            ),
          ],
        ),
      ),
    );

    final pageB = Scaffold(
      appBar: AppBar(title: const Text('B')),
      body: const Center(child: ProfilePhoto(size: 120)),
    );

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (context) => pageA,
          '/b': (context) => pageB,
        },
        initialRoute: '/',
      ),
    );

    await tester.pumpAndSettle();

    // Verify page A is shown
    expect(find.text('A'), findsOneWidget);
    expect(find.byType(ProfilePhoto), findsOneWidget);

    // Tap the button to navigate to B
    await tester.tap(find.widgetWithText(ElevatedButton, 'Go B'));
    await tester.pumpAndSettle();

    // Verify page B and profile photo present
    expect(find.text('B'), findsOneWidget);
    expect(find.byType(ProfilePhoto), findsOneWidget);
  });
}
