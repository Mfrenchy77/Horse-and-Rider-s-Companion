import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/guest_onboarding_dialog.dart';

void main() {
  testWidgets('Guest onboarding shows tabs and has Create Account CTA',
      (tester) async {
    var skipped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => GuestOnboardingDialog(
                      onSkip: () => skipped = true,
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

    expect(find.byKey(const Key('guest_onboarding_dialog')), findsOneWidget);
    expect(find.byKey(const Key('guest_onboarding_tab_bar')), findsOneWidget);
    expect(
      find.byKey(const Key('guest_create_account_button')),
      findsOneWidget,
    );

    // Close should trigger onSkip
    await tester.tap(find.byKey(const Key('guest_onboarding_close')));
    await tester.pumpAndSettle();
    expect(skipped, isTrue);
  });
}
