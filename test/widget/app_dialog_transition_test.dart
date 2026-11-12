import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';

void main() {
  testWidgets('dialog enters and stays mounted through its shorter exit', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showAppDialog<bool>(
                  context: context,
                  builder: (context) => Dialog(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirm'),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    final dialog = find.byType(Dialog);
    final scale = find.ancestor(
      of: dialog,
      matching: find.byType(ScaleTransition),
    );
    final slide = find.ancestor(
      of: dialog,
      matching: find.byType(SlideTransition),
    );
    final barrier = find.byType(AnimatedModalBarrier);
    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(
      tester.widget<ScaleTransition>(scale).scale.value,
      closeTo(.88, .001),
    );
    expect(
      tester.widget<SlideTransition>(slide).position.value.dy *
          tester.getSize(slide).height,
      closeTo(20, .01),
    );
    expect(tester.widget<AnimatedModalBarrier>(barrier).color.value!.a, 0);

    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.widget<ScaleTransition>(scale).scale.value, greaterThan(1));
    await tester.pump(const Duration(milliseconds: 91));
    expect(tester.widget<ScaleTransition>(scale).scale.value, 1);
    expect(
      tester.widget<AnimatedModalBarrier>(barrier).color.value!.a,
      closeTo(.55, .005),
    );

    await tester.tap(find.text('Confirm'));
    await tester.pump();
    expect(result, isTrue);
    await tester.pump(const Duration(milliseconds: 115));
    expect(
      tester.widget<ScaleTransition>(scale).scale.value,
      closeTo(1 - .12 * Curves.easeInCubic.transform(.5), .001),
    );
    expect(dialog, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 115));
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(dialog, findsOneWidget);
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(result, isNull);
  });

  testWidgets('reduced motion and protected barriers retain dismissal rules', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (context) => Dialog(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(find.text('Close').hitTestable(), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(Dialog),
        matching: find.byType(ScaleTransition),
      ),
      findsNothing,
    );
    await tester.tapAt(const Offset(4, 4));
    await tester.pump();
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Close'), findsNothing);
  });
}
