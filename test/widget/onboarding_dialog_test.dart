import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/onboarding_dialog.dart';

void main() {
  testWidgets('Onboarding dialog shows tabs and completes profile',
      (tester) async {
    Map<String, String>? profileResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<Map<String, String>?>(
                    context: context,
                    builder: (_) => OnboardingDialog(
                      onProfileComplete: (m) => profileResult = m,
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding_dialog')), findsOneWidget);
    expect(find.byKey(const Key('onboarding_tab_bar')), findsOneWidget);

    // switch to Signed In tab
    await tester.tap(find.text('Signed In'));
    await tester.pumpAndSettle();

    // Expect the complete profile button exists
    expect(
      find.byKey(const Key('onboarding_complete_profile_button')),
      findsOneWidget,
    );

    // open complete profile
    await tester
        .tap(find.byKey(const Key('onboarding_complete_profile_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('complete_profile_dialog')), findsOneWidget);

    // try saving with empty fields -> validation
    await tester.tap(find.byKey(const Key('complete_profile_save')));
    await tester.pumpAndSettle();

    // fill fields
    await tester.enterText(
      find.byKey(const Key('complete_profile_name')),
      'Test User',
    );
    await tester.enterText(
      find.byKey(const Key('complete_profile_email')),
      'test@example.com',
    );

    await tester.tap(find.byKey(const Key('complete_profile_save')));
    await tester.pumpAndSettle();

    // dialog should be closed and profileResult set
    expect(find.byKey(const Key('complete_profile_dialog')), findsNothing);
    expect(profileResult, isNotNull);
    expect(profileResult!['name'], 'Test User');
    expect(profileResult!['email'], 'test@example.com');
  });
}
