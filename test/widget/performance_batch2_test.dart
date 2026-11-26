import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/CommonWidgets/smart_image.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_matcher.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SettingsController caches light and dark ThemeData', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final controller = SettingsController(SettingsService());
    expect(identical(controller.theme, controller.theme), isTrue);
    expect(identical(controller.darkTheme, controller.darkTheme), isTrue);
  });

  test('matchDictionaryTerms single pass, excludeEntryId, 500 entries', () {
    final entries = <DictionaryEntry>[
      DictionaryEntry({
        'id': 'half',
        'slug': 'half',
        'term': 'Half',
        'definition': 'Short definition',
        'synonyms': <String>[],
        'status': 'published',
        'contextual': true,
      }),
      DictionaryEntry({
        'id': 'half-halt',
        'slug': 'half-halt',
        'term': 'Half Halt',
        'definition': 'A balancing cue.',
        'synonyms': <String>['rebalancing'],
        'status': 'published',
        'contextual': true,
      }),
      for (var i = 0; i < 498; i++)
        DictionaryEntry({
          'id': 'term-$i',
          'slug': 'term-$i',
          'term': 'Equestrian Concept $i',
          'definition': 'Definition $i',
          'synonyms': <String>['concept-alias-$i'],
          'status': 'published',
          'contextual': true,
        }),
    ];

    const sample =
        'Use a Half Halt and concept-alias-250 before Equestrian Concept 497.';
    final matches = matchDictionaryTerms(sample, entries);
    expect(matches.map((m) => m.entry.id), [
      'half-halt',
      'term-250',
      'term-497',
    ]);

    final excluded = matchDictionaryTerms(
      sample,
      entries,
      excludeEntryId: 'half-halt',
    );
    expect(excluded.map((m) => m.entry.id), [
      'half',
      'term-250',
      'term-497',
    ]);

    final sw = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      matchDictionaryTerms(sample, entries);
    }
    sw.stop();
    // ignore: avoid_print
    print('BENCH DictionaryMatcher 100x500: ${sw.elapsedMilliseconds}ms');
    expect(sw.elapsedMilliseconds, lessThan(250));
  });

  testWidgets('SmartImage proxy avoids double DPR multiplication', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(devicePixelRatio: 2),
        child: MaterialApp(
          home: SmartImage(
            'https://media.example.com/horse.jpg',
            maxLogicalWidth: 300,
            config: SmartImageConfig(
              proxyMode: SmartImageProxyMode.always,
              preferDirectFirst: false,
            ),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final resize = image.image as ResizeImage;
    expect(resize.width, 600);
    final uri = Uri.parse((resize.imageProvider as NetworkImage).url);
    expect(uri.host, 'wsrv.nl');
    expect(uri.queryParameters['w'], '300');
    expect(uri.queryParameters['dpr'], '2.00');
  });
}
