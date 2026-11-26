// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

DictionaryEntry _entry({
  required String id,
  required String term,
  required String definition,
  List<String> synonyms = const [],
  List<String> categories = const ['Training'],
}) => DictionaryEntry({
  'id': id,
  'slug': id,
  'term': term,
  'definition': definition,
  'synonyms': synonyms,
  'categories': categories,
  'status': 'published',
  'contextual': true,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final entries = [
    _entry(
      id: 'half-halt',
      term: 'Half Halt',
      definition: 'A brief, coordinated balancing aid.',
      synonyms: ['half halt'],
      categories: ['Aids'],
    ),
    _entry(
      id: 'canter',
      term: 'Canter',
      definition: 'A three-beat asymmetrical gait.',
      categories: ['Gaits'],
    ),
  ];

  group('Animated Dictionary definition dialog', () {
    testWidgets(
      'expands from tapped top-left and bottom-right terms and reverses on Close, background tap, and Escape',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 24,
                    top: 24,
                    child: DictionaryText(
                      text: 'Ask for a half halt.',
                      entries: entries,
                    ),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: DictionaryText(
                      text: 'Ride forward in canter.',
                      entries: entries,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        const viewportCenter = Offset(500, 400);
        final topLeftWordFinder = find.widgetWithText(TextButton, 'half halt');
        final bottomRightWordFinder = find.widgetWithText(TextButton, 'canter');
        final topLeftWordCenter = tester.getCenter(topLeftWordFinder);
        final bottomRightWordCenter = tester.getCenter(bottomRightWordFinder);
        expect(topLeftWordCenter.dx, lessThan(viewportCenter.dx - 200));
        expect(topLeftWordCenter.dy, lessThan(viewportCenter.dy - 200));
        expect(bottomRightWordCenter.dx, greaterThan(viewportCenter.dx + 200));
        expect(bottomRightWordCenter.dy, greaterThan(viewportCenter.dy + 200));

        // 1. Open from top-left term -> expands outward from top-left word.
        await tester.tap(topLeftWordFinder);
        await tester.pump();

        final translateFinder = find.byKey(
          const Key('appDialogOriginTranslate'),
        );
        final scaleFinder = find.byKey(const Key('appDialogOriginScale'));
        final dialogFinder = find.byKey(
          const Key('dictionaryDefinitionDialog'),
        );
        expect(translateFinder, findsOneWidget);
        expect(scaleFinder, findsOneWidget);
        expect(dialogFinder, findsOneWidget);

        final initialTranslate = tester.widget<Transform>(translateFinder);
        final initialOffset = Offset(
          initialTranslate.transform.getTranslation().x,
          initialTranslate.transform.getTranslation().y,
        );
        expect(initialOffset.dx, lessThan(-200));
        expect(initialOffset.dy, lessThan(-200));
        final initialScale = tester
            .widget<Transform>(scaleFinder)
            .transform
            .storage[0];
        expect(initialScale, lessThan(0.5));

        // Mid-enter: moving closer to screen center and scaling up.
        await tester.pump(const Duration(milliseconds: 140));
        final midTranslate = tester.widget<Transform>(translateFinder);
        final midOffset = Offset(
          midTranslate.transform.getTranslation().x,
          midTranslate.transform.getTranslation().y,
        );
        expect(midOffset.dx.abs(), lessThan(initialOffset.dx.abs()));
        expect(midOffset.dy.abs(), lessThan(initialOffset.dy.abs()));
        expect(
          tester.widget<Transform>(scaleFinder).transform.storage[0],
          greaterThan(initialScale),
        );

        // Settled at viewport center, full scale.
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(dialogFinder).dx,
          closeTo(viewportCenter.dx, 2),
        );
        expect(
          tester.getCenter(dialogFinder).dy,
          closeTo(viewportCenter.dy, 2),
        );
        expect(
          tester.widget<Transform>(scaleFinder).transform.storage[0],
          closeTo(1.0, 0.001),
        );

        // 2. Reverse on Close button -> contracts back toward top-left word.
        await tester.tap(find.text('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(dialogFinder, findsOneWidget);
        final exitTranslate = tester.widget<Transform>(translateFinder);
        expect(exitTranslate.transform.getTranslation().x, lessThan(0));
        expect(exitTranslate.transform.getTranslation().y, lessThan(0));
        expect(
          tester.widget<Transform>(scaleFinder).transform.storage[0],
          lessThan(1.0),
        );
        await tester.pumpAndSettle();
        expect(dialogFinder, findsNothing);

        // 3. Open from bottom-right term -> expands from bottom-right & dismisses on Escape.
        await tester.tap(bottomRightWordFinder);
        await tester.pump();
        final brInitial = tester.widget<Transform>(translateFinder);
        expect(brInitial.transform.getTranslation().x, greaterThan(200));
        expect(brInitial.transform.getTranslation().y, greaterThan(200));
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(dialogFinder, findsOneWidget);
        final brExit = tester.widget<Transform>(translateFinder);
        expect(brExit.transform.getTranslation().x, greaterThan(0));
        expect(brExit.transform.getTranslation().y, greaterThan(0));
        await tester.pumpAndSettle();
        expect(dialogFinder, findsNothing);

        // 4. Open again & dismiss on background barrier tap.
        await tester.tap(bottomRightWordFinder);
        await tester.pumpAndSettle();
        expect(dialogFinder, findsOneWidget);
        await tester.tapAt(const Offset(4, 4));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(dialogFinder, findsOneWidget);
        await tester.pumpAndSettle();
        expect(dialogFinder, findsNothing);
      },
    );

    testWidgets(
      'tracks scrolled origin offset and falls back to centered transition if scrolled away',
      (tester) async {
        tester.view.physicalSize = const Size(900, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            home: Scaffold(
              body: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 900),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: DictionaryText(
                        text: 'Transition smoothly into canter.',
                        entries: entries,
                      ),
                    ),
                    const SizedBox(height: 1200),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll word into upper-left viewport area before tapping.
        controller.jumpTo(820);
        await tester.pumpAndSettle();

        final wordFinder = find.widgetWithText(TextButton, 'canter');
        final wordCenter = tester.getCenter(wordFinder);
        expect(wordCenter.dy, lessThan(200));

        await tester.tap(wordFinder);
        await tester.pump();

        final translateFinder = find.byKey(
          const Key('appDialogOriginTranslate'),
        );
        expect(translateFinder, findsOneWidget);
        final openTranslate = tester.widget<Transform>(translateFinder);
        // Word is in the upper half after scrolling, so dialog starts upward (< 0).
        expect(openTranslate.transform.getTranslation().y, lessThan(-150));
        await tester.pumpAndSettle();

        // Scroll far away while dialog is open -> dismissal falls back cleanly.
        controller.jumpTo(0);
        await tester.pump();

        await tester.tap(find.text('Close'));
        await tester.pump();
        expect(find.byKey(const Key('appDialogOriginTranslate')), findsNothing);
        expect(
          find.byKey(const Key('dictionaryDefinitionDialog')),
          findsOneWidget,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryDefinitionDialog')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'falls back cleanly when originating word widget is removed while dialog is open',
      (tester) async {
        final showText = ValueNotifier<bool>(true);
        addTearDown(showText.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: showText,
                builder: (_, visible, _) => visible
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: DictionaryText(
                          text: 'Use a half halt cleanly.',
                          entries: entries,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'half halt'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryDefinitionDialog')),
          findsOneWidget,
        );

        // Dispose originating widget before dismissing dialog.
        showText.value = false;
        await tester.pump();

        await tester.tap(find.text('Close'));
        await tester.pump();
        expect(find.byKey(const Key('appDialogOriginTranslate')), findsNothing);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryDefinitionDialog')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'respects reduced-motion setting without origin translation or scale motion',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: DictionaryText(
                  text: 'Ask for a half halt before canter.',
                  entries: entries,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        await tester.tap(find.widgetWithText(TextButton, 'half halt'));
        await tester.pump();

        final dialogFinder = find.byKey(
          const Key('dictionaryDefinitionDialog'),
        );
        expect(dialogFinder, findsOneWidget);
        expect(find.byKey(const Key('appDialogOriginTranslate')), findsNothing);
        expect(find.byKey(const Key('appDialogOriginScale')), findsNothing);

        await tester.tap(find.text('Close'));
        await tester.pump();
        expect(dialogFinder, findsNothing);
      },
    );

    testWidgets(
      'works cleanly on narrow mobile layout with ContextualDictionaryText and navigates to full entry',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        String? pushedSlug;
        final router = GoRouter(
          initialLocation: '/lesson',
          routes: [
            GoRoute(
              path: '/lesson',
              builder: (_, _) => Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ContextualDictionaryText(
                    text: 'Establish a relaxed canter.',
                    entriesOverride: entries,
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/Dictionary/:slug',
              builder: (_, state) {
                pushedSlug = state.pathParameters['slug'];
                return Scaffold(body: Text('Full: $pushedSlug'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(theme: mainThemeDark, routerConfig: router),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'canter'));
        await tester.pump();
        expect(
          find.byKey(const Key('appDialogOriginTranslate')),
          findsOneWidget,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('View full definition'));
        await tester.pumpAndSettle();
        expect(pushedSlug, 'canter');
        expect(find.text('Full: canter'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
