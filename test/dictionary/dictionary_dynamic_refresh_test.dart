// ignore_for_file: lines_longer_than_80_chars

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    DictionaryRepository.invalidateCache();
    DictionaryRepository.clock = DateTime.now;
    DictionaryRepository.cacheTtl = const Duration(minutes: 10);
  });

  group('Dynamic Dictionary highlighting & cache refresh', () {
    testWidgets(
      'newly published terms, synonyms, definition edits, contextual toggles, and unpublishing update already-open screens while preserving scroll position',
      (tester) async {
        final db = FakeFirebaseFirestore();
        await db.collection('DictionaryPublic').doc('catalogue').set({
          'initialized': true,
        });
        await db.collection('DictionaryEntries').doc('half-halt').set({
          'id': 'half-halt',
          'slug': 'half-halt',
          'term': 'Half Halt',
          'definition': 'Initial definition of half halt.',
          'synonyms': ['half-halt'],
          'categories': ['Riding'],
          'status': 'published',
          'contextual': true,
          'revision': 1,
        });
        // Unpublished draft must NEVER be highlighted or manually defined.
        await db.collection('DictionaryEntries').doc('secret-draft').set({
          'id': 'secret-draft',
          'slug': 'secret-draft',
          'term': 'Cavaletti',
          'definition': 'Unpublished draft definition.',
          'synonyms': <String>[],
          'categories': ['Training'],
          'status': 'draft',
          'contextual': true,
          'revision': 1,
        });

        // Prime shared cache from fake Firestore.
        await DictionaryRepository.refreshCachedEntries(firestore: db);

        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            home: Scaffold(
              body: ListView(
                controller: scrollController,
                children: const [
                  SizedBox(height: 300),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: ContextualDictionaryText(
                      text:
                          'Use a half halt before sidepass, lateral flexion, '
                          'or cavaletti work.',
                    ),
                  ),
                  SizedBox(height: 800),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Scroll down to verify scroll position is preserved across updates.
        scrollController.jumpTo(150);
        await tester.pump();
        expect(scrollController.offset, 150);

        // Initially: only 'half halt' is highlighted; 'sidepass', 'lateral flexion',
        // and unpublished 'cavaletti' are NOT highlighted.
        expect(find.widgetWithText(TextButton, 'half halt'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'sidepass'), findsNothing);
        expect(
          find.widgetWithText(TextButton, 'lateral flexion'),
          findsNothing,
        );
        expect(find.widgetWithText(TextButton, 'cavaletti'), findsNothing);

        // 1. Publish a NEW term ('Sidepass') in Firestore + edit 'Half Halt'.
        await db.collection('DictionaryEntries').doc('sidepass').set({
          'id': 'sidepass',
          'slug': 'sidepass',
          'term': 'Sidepass',
          'definition': 'Moving directly sideways across a line or rail.',
          'synonyms': <String>[],
          'categories': ['Riding'],
          'status': 'published',
          'contextual': true,
          'revision': 1,
        });
        await db.collection('DictionaryEntries').doc('half-halt').update({
          'definition': 'Updated rebalancing definition.',
          'revision': 2,
        });

        await DictionaryRepository.refreshCachedEntries(firestore: db);
        await tester.pumpAndSettle();

        // Already-open screen updated automatically AND kept scroll position!
        expect(scrollController.offset, 150);
        expect(find.widgetWithText(TextButton, 'sidepass'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'cavaletti'), findsNothing);

        // 1b. Publish a NEW longer synonym ('lateral flexion') -> takes
        //     precedence over shorter 'sidepass' for the same meaning.
        await db.collection('DictionaryEntries').doc('sidepass').update({
          'synonyms': ['lateral flexion'],
          'revision': 2,
        });
        await DictionaryRepository.refreshCachedEntries(firestore: db);
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(TextButton, 'lateral flexion'),
          findsOneWidget,
        );
        expect(find.widgetWithText(TextButton, 'sidepass'), findsNothing);

        // Popup shows the UPDATED definition for Half Halt.
        await tester.tap(find.widgetWithText(TextButton, 'half halt'));
        await tester.pumpAndSettle();
        expect(find.text('Updated rebalancing definition.'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // 2. Disable contextual matching on Sidepass -> removes auto-highlight
        //    but keeps Sidepass available for manual Define lookup.
        await db.collection('DictionaryEntries').doc('sidepass').update({
          'contextual': false,
          'revision': 3,
        });
        await DictionaryRepository.refreshCachedEntries(firestore: db);
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(TextButton, 'lateral flexion'),
          findsNothing,
        );
        expect(find.widgetWithText(TextButton, 'sidepass'), findsNothing);
        final manualLookup = lookupSelectedDictionaryTerm(
          'lateral flexion',
          DictionaryRepository.peekCachedEntries!,
        );
        expect(manualLookup.exactMatch?.id, 'sidepass');

        // 3. Unpublish / archive Half Halt -> removed from cache and highlighting.
        await db.collection('DictionaryEntries').doc('half-halt').update({
          'status': 'archived',
          'revision': 3,
        });
        await DictionaryRepository.refreshCachedEntries(firestore: db);
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextButton, 'half halt'), findsNothing);
        expect(
          lookupSelectedDictionaryTerm(
            'half halt',
            DictionaryRepository.peekCachedEntries!,
          ).hasMatch,
          isFalse,
        );
        expect(scrollController.offset, 150);
      },
    );

    test('cache TTL marks entries stale after cacheTtl elapses', () async {
      var now = DateTime(2026, 11, 25, 12);
      DictionaryRepository.clock = () => now;
      DictionaryRepository.cacheTtl = const Duration(minutes: 5);

      final db = FakeFirebaseFirestore();
      await db.collection('DictionaryPublic').doc('catalogue').set({
        'initialized': true,
      });
      await db.collection('DictionaryEntries').doc('withers').set({
        'id': 'withers',
        'slug': 'withers',
        'term': 'Withers',
        'definition': 'Ridge between the shoulder blades.',
        'status': 'published',
        'contextual': true,
      });

      expect(DictionaryRepository.isCacheStale, isTrue);
      await DictionaryRepository.refreshCachedEntries(firestore: db);
      expect(DictionaryRepository.isCacheStale, isFalse);

      now = now.add(const Duration(minutes: 4));
      expect(DictionaryRepository.isCacheStale, isFalse);

      now = now.add(const Duration(minutes: 2));
      expect(DictionaryRepository.isCacheStale, isTrue);
    });

    test(
      'handles multiple published definitions sharing a term safely and matches efficiently on a large 500-entry catalogue',
      () {
        final largeCatalogue = <DictionaryEntry>[
          for (var i = 0; i < 498; i++)
            DictionaryEntry({
              'id': 'term-$i',
              'slug': 'term-$i',
              'term': 'Equine Term $i',
              'definition': 'Definition for term $i.',
              'synonyms': ['alias-$i-a', 'alias-$i-b'],
              'status': 'published',
              'contextual': true,
            }),
          DictionaryEntry({
            'id': 'lead-gait',
            'slug': 'lead-gait',
            'term': 'Lead',
            'definition': 'Which foreleg advances farther in the canter.',
            'synonyms': <String>[],
            'status': 'published',
            'contextual': true,
          }),
          DictionaryEntry({
            'id': 'lead-rope',
            'slug': 'lead-rope',
            'term': 'Lead',
            'definition': 'A rope clipped to a halter.',
            'synonyms': <String>[],
            'status': 'published',
            'contextual': true,
          }),
        ];

        const sampleText =
            'Check the Lead and practice Equine Term 42, alias-250-a, and '
            'Equine Term 497 calmly.';

        // First call builds the Expando-cached compiled index.
        final first = matchDictionaryTerms(sampleText, largeCatalogue);
        // 'Lead' is ambiguous across two published entries so it is NOT auto-highlighted.
        expect(first.map((m) => m.entry.id), [
          'term-42',
          'term-250',
          'term-497',
        ]);

        // Manual Define on 'Lead' returns both published meanings safely.
        final lookup = lookupSelectedDictionaryTerm('Lead', largeCatalogue);
        expect(lookup.exactMatch, isNull);
        expect(
          lookup.ambiguousMatches.map((e) => e.id),
          containsAll(['lead-gait', 'lead-rope']),
        );

        // Repeated matching reuses the compiled index and stays fast.
        final sw = Stopwatch()..start();
        for (var i = 0; i < 20; i++) {
          final result = matchDictionaryTerms(sampleText, largeCatalogue);
          expect(result, hasLength(3));
        }
        sw.stop();
        expect(
          sw.elapsedMilliseconds,
          lessThan(500),
          reason:
              '20 matches across 500 entries should stay fast via Expando index',
        );
      },
    );
  });
}
