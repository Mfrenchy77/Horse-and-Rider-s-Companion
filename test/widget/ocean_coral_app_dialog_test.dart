import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Theme/ocean_coral.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

void main() {
  testWidgets('scrolls long content and wraps actions on a small screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 340));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: mainThemeLight,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => OceanCoralAppDialog(
                  title: const Text('Edit listing'),
                  scrollable: true,
                  content: const Column(
                    children: [
                      SizedBox(height: 600),
                      Text('End of form'),
                    ],
                  ),
                  actions: [
                    SizedBox(
                      width: 180,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ),
              child: const Text('Open form'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    expect(find.text('Save changes').hitTestable(), findsOneWidget);
    expect(find.text('End of form').hitTestable(), findsNothing);

    await tester.scrollUntilVisible(find.text('End of form'), 200);
    expect(find.text('End of form').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.byType(OceanCoralAppDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
