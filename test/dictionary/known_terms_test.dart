// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/known_terms_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/known_terms_settings_section.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

DictionaryEntry _entry({
  required String id,
  required String term,
  required String definition,
  List<String> synonyms = const [],
  List<String> categories = const ['Training'],
  bool published = true,
  bool contextual = true,
}) => DictionaryEntry({
  'id': id,
  'slug': id,
  'term': term,
  'definition': definition,
  'synonyms': synonyms,
  'categories': categories,
  'status': published ? 'published' : 'draft',
  'contextual': contextual,
});

ThemeData _withScreenshotFonts(ThemeData base) => base.copyWith(
  textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
  primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
  appBarTheme: base.appBarTheme.copyWith(
    titleTextStyle: (base.appBarTheme.titleTextStyle ?? const TextStyle())
        .copyWith(fontFamily: 'Roboto'),
  ),
);

Future<void> _loadScreenshotFonts() async {
  Future<void> register(String family, List<String> paths) async {
    final loader = FontLoader(family);
    var loadedAny = false;
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
        loadedAny = true;
      }
    }
    if (loadedAny) await loader.load();
  }

  await register('Roboto', [
    '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf',
    '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf',
  ]);
  await register('Georgia', [
    '/usr/share/fonts/dejavu-serif-fonts/DejaVuSerif.ttf',
    '/usr/share/fonts/dejavu-serif-fonts/DejaVuSerif-Bold.ttf',
  ]);
  await register('MaterialIcons', [
    'build/web/assets/fonts/MaterialIcons-Regular.otf',
  ]);
}

Widget _wrapWithTheme({
  required ThemeData theme,
  required Widget child,
  GlobalKey? boundaryKey,
}) {
  Widget app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    builder: (context, inner) {
      final gradients = Theme.of(context).extension<SurfaceGradients>();
      return DecoratedBox(
        decoration: BoxDecoration(gradient: gradients?.background),
        child: inner ?? const SizedBox.shrink(),
      );
    },
    home: child,
  );
  if (boundaryKey != null) {
    app = RepaintBoundary(key: boundaryKey, child: app);
  }
  return app;
}

Future<void> _capturePng(
  WidgetTester tester,
  GlobalKey key,
  String outputPath,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData != null) {
      final file = File(outputPath);
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(byteData.buffer.asUint8List());
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleEntries = [
    _entry(
      id: 'canter',
      term: 'Canter',
      definition: 'A three-beat gait with a moment of suspension.',
      synonyms: ['lope', 'cantering', 'loping'],
      categories: ['Gaits'],
    ),
    _entry(
      id: 'counter-canter',
      term: 'Counter-Canter',
      definition: 'Cantering intentionally on the outside lead.',
      synonyms: ['counter canter'],
      categories: ['Gaits'],
    ),
    _entry(
      id: 'half-halt',
      term: 'Half-Halt',
      definition: 'A brief, coordinated aid to rebalance the horse.',
      synonyms: ['half halt'],
      categories: ['Aids'],
    ),
    _entry(
      id: 'collection',
      term: 'Collection',
      definition: 'Increased engagement of the hindquarters and lightness.',
      categories: ['Training Scales'],
    ),
    _entry(
      id: 'impulsion',
      term: 'Impulsion',
      definition: 'Controlled, energetic forward thrust from behind.',
      categories: ['Training Scales'],
    ),
    _entry(
      id: 'poll',
      term: 'Poll',
      definition: 'The joint directly behind the horse’s ears.',
      categories: ['Anatomy'],
    ),
  ];

  setUpAll(_loadScreenshotFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    KnownTermsRepository.instance.resetForTest();
    await KnownTermsRepository.instance.load();
  });

  tearDown(KnownTermsRepository.instance.resetForTest);

  group('KnownTermsRepository unit tests', () {
    test(
      'starts empty, persists known/unknown transitions, and deduplicates',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final repo = KnownTermsRepository(preferences: prefs);
        await repo.load();

        expect(repo.isLoaded, isTrue);
        expect(repo.count, 0);
        expect(repo.getKnownTerms(), isEmpty);
        expect(repo.isKnown('canter'), isFalse);

        var notifications = 0;
        repo.addListener(() => notifications++);

        await repo.markKnown('canter');
        await repo.markKnown(' canter ');
        await repo.markKnown('half-halt');
        expect(repo.count, 2);
        expect(repo.getKnownTerms(), {'canter', 'half-halt'});
        expect(repo.isKnown('canter'), isTrue);
        expect(notifications, 2);

        // Persist across repository recreation on the same device storage.
        final recreated = KnownTermsRepository(preferences: prefs);
        await recreated.load();
        expect(recreated.getKnownTerms(), {'canter', 'half-halt'});

        await recreated.markUnknown('canter');
        expect(recreated.getKnownTerms(), {'half-halt'});

        final reloaded = KnownTermsRepository(preferences: prefs);
        await reloaded.load();
        expect(reloaded.getKnownTerms(), {'half-halt'});

        await reloaded.clearKnownTerms();
        expect(reloaded.count, 0);
        expect(prefs.getString(KnownTermsRepository.storageKey), isNull);
      },
    );

    test(
      'handles malformed local values and deleted term IDs gracefully',
      () async {
        for (final corruptValue in <String>[
          '{not valid json',
          '{"canter": true}',
          '42',
          jsonEncode(['canter', 123, null, '   ', 'deleted-legacy-id']),
        ]) {
          SharedPreferences.setMockInitialValues({
            KnownTermsRepository.storageKey: corruptValue,
          });
          final prefs = await SharedPreferences.getInstance();
          final repo = KnownTermsRepository(preferences: prefs);
          await repo.load();
          if (corruptValue.startsWith('[')) {
            expect(repo.getKnownTerms(), {'canter', 'deleted-legacy-id'});
          } else {
            expect(repo.getKnownTerms(), isEmpty);
          }
        }

        // Integer stored under key instead of string.
        SharedPreferences.setMockInitialValues({
          KnownTermsRepository.storageKey: 99,
        });
        final prefsInt = await SharedPreferences.getInstance();
        final repoInt = KnownTermsRepository(preferences: prefsInt);
        await repoInt.load();
        expect(repoInt.getKnownTerms(), isEmpty);
      },
    );
  });

  group('Contextual Dictionary matcher known-term filtering', () {
    test(
      'skips known canonical entries and aliases while leaving unrelated & manual lookups intact',
      () {
        const text =
            'ASK for a CANTER, then loping smoothly before a half-halt and Poll flexion.';
        final allMatches = matchDictionaryTerms(text, sampleEntries);
        expect(allMatches.map((m) => m.entry.id).toSet(), {
          'canter',
          'half-halt',
          'poll',
        });

        final filtered = matchDictionaryTerms(
          text,
          sampleEntries,
          knownTermIds: {'canter'},
        );
        // Both "CANTER" and alias "loping" map to canonical ID "canter".
        expect(filtered.map((m) => m.entry.id).toList(), ['half-halt', 'poll']);

        // Manual lookup still resolves known terms on demand.
        final manual = lookupSelectedDictionaryTerm('canter', sampleEntries);
        expect(manual.exactMatch?.id, 'canter');
      },
    );

    test(
      'handles overlapping terminology without leaking sub-terms or suppressing super-terms',
      () {
        const text =
            'Practice a clean counter-canter before transitioning to canter.';
        // Known counter-canter must NOT falsely highlight inner "canter" inside
        // "counter-canter", while the separate "canter" remains highlighted.
        final hideSuperTerm = matchDictionaryTerms(
          text,
          sampleEntries,
          knownTermIds: {'counter-canter'},
        );
        expect(hideSuperTerm.length, 1);
        expect(hideSuperTerm.single.entry.id, 'canter');
        expect(hideSuperTerm.single.start, greaterThan(text.indexOf('to')));

        // Known "canter" must NOT suppress "counter-canter".
        final hideSubTerm = matchDictionaryTerms(
          text,
          sampleEntries,
          knownTermIds: {'canter'},
        );
        expect(hideSubTerm.length, 1);
        expect(hideSubTerm.single.entry.id, 'counter-canter');
      },
    );

    test('known terms do not consume maxMatches allowance', () {
      const text = 'Check the poll, canter, half-halt, and collection.';
      final matches = matchDictionaryTerms(
        text,
        sampleEntries,
        maxMatches: 2,
        knownTermIds: {'poll', 'canter'},
      );
      expect(matches.map((m) => m.entry.id).toList(), [
        'half-halt',
        'collection',
      ]);
    });
  });

  group('Definition dialog checkbox and live highlighting widget tests', () {
    testWidgets(
      'checking in definition dialog updates highlighting immediately without closing, persists, and does not rebuild unrelated text',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();
        final repo = KnownTermsRepository(preferences: prefs);
        await repo.load();

        var unrelatedRebuildCount = 0;

        await tester.pumpWidget(
          _wrapWithTheme(
            theme: mainThemeDark,
            child: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DictionaryText(
                    text:
                        'Ask for a balanced canter or quiet lope, plus a half-halt.',
                    entries: sampleEntries,
                    knownTermsRepository: repo,
                  ),
                  Builder(
                    builder: (context) {
                      unrelatedRebuildCount++;
                      return DictionaryText(
                        text: 'Keep softness through the poll.',
                        entries: sampleEntries,
                        knownTermsRepository: repo,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('canter'), findsOneWidget);
        expect(find.text('half-halt'), findsOneWidget);
        expect(find.text('poll'), findsOneWidget);
        final initialUnrelatedBuilds = unrelatedRebuildCount;

        // Open definition dialog for Canter.
        await tester.tap(find.text('canter'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('dictionaryDefinitionDialog')),
          findsOneWidget,
        );
        final checkboxFinder = find.byKey(
          const Key('dictionaryKnownTermCheckbox'),
        );
        expect(checkboxFinder, findsOneWidget);
        expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);

        // Placement: below definition and above Close / View full definition.
        final defRect = tester.getRect(
          find.text('A three-beat gait with a moment of suspension.'),
        );
        final checkboxRect = tester.getRect(checkboxFinder);
        final closeRect = tester.getRect(find.text('Close'));
        expect(checkboxRect.top, greaterThanOrEqualTo(defRect.bottom));
        expect(checkboxRect.bottom, lessThanOrEqualTo(closeRect.top + 20));

        // Toggle checkbox -> stays open, persists locally, updates highlight live.
        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('dictionaryDefinitionDialog')),
          findsOneWidget,
        );
        expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
        expect(repo.isKnown('canter'), isTrue);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // "canter" is no longer a highlighted TextButton, while "half-halt"
        // and unrelated "poll" remain highlighted with zero rebuild of
        // unrelated DictionaryText.
        expect(find.widgetWithText(TextButton, 'canter'), findsNothing);
        expect(find.widgetWithText(TextButton, 'half-halt'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'poll'), findsOneWidget);
        expect(
          find.textContaining(
            'Ask for a balanced canter or quiet lope, plus a',
            findRichText: true,
          ),
          findsOneWidget,
        );
        expect(unrelatedRebuildCount, initialUnrelatedBuilds);

        // Reopen via manual lookup -> checkbox reflects saved checked state,
        // and unchecking restores highlighting immediately.
        final reopenFuture = showSelectedTermDefinition(
          tester.element(find.byType(Scaffold)),
          selectedText: 'canter',
          entries: sampleEntries,
          knownTermsRepository: repo,
        );
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

        await tester.tap(checkboxFinder);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        await reopenFuture;

        expect(find.widgetWithText(TextButton, 'canter'), findsOneWidget);
        expect(repo.isKnown('canter'), isFalse);
      },
    );

    testWidgets(
      'works in SkillDetailV2Panel educational criteria while preserving explicit Skill Tree links',
      (tester) async {
        DictionaryRepository.entriesNotifier.value = sampleEntries;
        final repo = KnownTermsRepository.instance;
        await repo.markKnown('canter');

        const relatedSkill = CurriculumSkill(
          id: 'rider.mounted.posting_trot',
          familyId: 'rider.mounted.gaits',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          name: 'Posting Trot',
          summary: 'Maintain balance in trot.',
          purpose: 'Build rhythm and balance.',
          availableLevels: [DifficultyState.Introductory],
          levels: {
            DifficultyState.Introductory: SkillLevelDefinition(
              overview: 'Maintain balanced rhythm in posting trot.',
              learning: 'Maintains diagonal posting.',
              proficient: 'Maintains effortless posting.',
            ),
          },
        );
        const targetSkill = CurriculumSkill(
          id: 'rider.mounted.canter_transitions',
          familyId: 'rider.mounted.gaits',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          name: 'Canter Transitions',
          summary: 'Prepare canter with a clean half-halt.',
          purpose: 'Develop balanced upward transitions.',
          availableLevels: [DifficultyState.Introductory],
          relatedSkills: [
            RelatedSkill(
              skillId: 'rider.mounted.posting_trot',
              relation: SkillRelationType.foundation,
            ),
          ],
          levels: {
            DifficultyState.Introductory: SkillLevelDefinition(
              overview: 'Develop upward transitions to canter.',
              learning: 'Prepares with a steady half-halt.',
              proficient: 'Executes calm transitions without rush.',
            ),
          },
        );
        const state = SkillTreeV2State(
          isLoading: false,
          families: [
            SkillFamily(
              id: 'rider.mounted.gaits',
              subject: SkillSubject.rider,
              realm: SkillCategory.Mounted,
              name: 'Gaits, Rhythm & Transitions',
              description: 'Rhythm and transitions.',
            ),
          ],
          skills: [targetSkill, relatedSkill],
          selectedSkillId: 'rider.mounted.canter_transitions',
          selectedLevel: DifficultyState.Introductory,
        );

        final harness = await AppTestHarness.create();
        addTearDown(harness.close);

        String? tappedRelatedId;
        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: _wrapWithTheme(
              theme: mainThemeDark,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: SkillDetailV2Panel(
                    state: state,
                    skill: targetSkill,
                    allResources: const [],
                    canSelfAssess: false,
                    selfAssessDisabledReason: 'Preview',
                    canVerify: false,
                    onSelectLevel: (_) {},
                    onSelfAssess: (_, _) {},
                    onVerifyLevel: (_, {required verified}) {},
                    onSelectRelatedSkill: (id) => tappedRelatedId = id,
                    onChangeResourceSort: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Known "canter" is not highlighted as TextButton, unknown "half-halt"
        // is highlighted, and authored ActionChip link stays active.
        expect(find.widgetWithText(TextButton, 'canter'), findsNothing);
        expect(find.widgetWithText(TextButton, 'half-halt'), findsWidgets);
        await tester.tap(find.widgetWithText(ActionChip, 'Posting Trot'));
        await tester.pumpAndSettle();
        expect(tappedRelatedId, 'rider.mounted.posting_trot');
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('KnownDictionaryTermsSection & Settings management', () {
    testWidgets(
      'displays empty state, known terms with missing-ID fallback, individual Remove, clear-all confirmation, and Dark/Light responsive layouts',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();
        final repo = KnownTermsRepository(preferences: prefs);
        await repo.load();

        Future<void> pumpSection(Size size, ThemeData theme) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(
            _wrapWithTheme(
              theme: theme,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: KnownDictionaryTermsSection(
                    repository: repo,
                    entriesOverride: sampleEntries,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // 1) Empty state on Dark Mobile.
        await pumpSection(const Size(390, 844), mainThemeDark);
        expect(find.byKey(const Key('knownTermsEmptyState')), findsOneWidget);
        expect(find.text('0 terms'), findsOneWidget);
        expect(find.byKey(const Key('clearAllKnownTermsButton')), findsNothing);

        // 2) Add 5 terms including a missing/deleted term ID to test fallback & filter.
        await repo.markKnown('canter');
        await repo.markKnown('half-halt');
        await repo.markKnown('collection');
        await repo.markKnown('impulsion');
        await repo.markKnown('deleted-legacy-term');
        await tester.pumpAndSettle();

        expect(find.text('5 terms'), findsOneWidget);
        expect(find.text('Canter'), findsOneWidget);
        expect(find.text('Half-Halt'), findsOneWidget);
        expect(find.text('Deleted Legacy Term'), findsOneWidget);
        expect(find.text('No longer in Dictionary'), findsOneWidget);
        expect(find.byKey(const Key('knownTermsSearchField')), findsOneWidget);

        // Search filter narrows list cleanly.
        await tester.enterText(
          find.byKey(const Key('knownTermsSearchField')),
          'half',
        );
        await tester.pumpAndSettle();
        expect(find.text('Half-Halt'), findsOneWidget);
        expect(find.text('Canter'), findsNothing);

        // Clear filter and remove an individual term.
        await tester.enterText(
          find.byKey(const Key('knownTermsSearchField')),
          '',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('removeKnownTerm_half-halt')));
        await tester.pumpAndSettle();
        expect(repo.isKnown('half-halt'), isFalse);
        expect(find.text('4 terms'), findsOneWidget);

        // 3) Clear all -> cancel preserves, confirm clears all.
        await tester.ensureVisible(
          find.byKey(const Key('clearAllKnownTermsButton')),
        );
        await tester.tap(find.byKey(const Key('clearAllKnownTermsButton')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('clearKnownTermsConfirmDialog')),
          findsOneWidget,
        );

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(repo.count, 4);

        await tester.tap(find.byKey(const Key('clearAllKnownTermsButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirmClearKnownTermsButton')));
        await tester.pumpAndSettle();
        expect(repo.count, 0);
        expect(find.byKey(const Key('knownTermsEmptyState')), findsOneWidget);

        // 4) Re-populate and verify Desktop Light Theme without overflows.
        await repo.markKnown('canter');
        await repo.markKnown('collection');
        await pumpSection(const Size(1180, 820), mainThemeLight);
        expect(find.text('2 terms'), findsOneWidget);
        expect(find.text('Canter'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SettingsView integrates KnownDictionaryTermsSection cleanly on Mobile & Desktop with zero Firebase calls',
      (tester) async {
        final harness = await AppTestHarness.create();
        addTearDown(harness.close);
        DictionaryRepository.entriesNotifier.value = sampleEntries;
        await KnownTermsRepository.instance.markKnown('collection');

        final settings = SettingsController(SettingsService());
        await settings.loadSettings();
        addTearDown(settings.dispose);

        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(412, 860);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: _wrapWithTheme(
              theme: _withScreenshotFonts(mainThemeLight),
              child: SettingsView(controller: settings),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final card = find.byKey(const Key('knownTermsSettingsCard'));
        expect(card, findsOneWidget);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(find.text('Collection'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Screenshots (CAPTURE_KNOWN_TERMS_SCREENSHOTS=1)', () {
    testWidgets('captures Dark and Light screenshots of dialog and Settings', (
      tester,
    ) async {
      if (Platform.environment['CAPTURE_KNOWN_TERMS_SCREENSHOTS'] != '1') {
        return;
      }

      const outDir =
          '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7';
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;

      final prefs = await SharedPreferences.getInstance();
      final repo = KnownTermsRepository(preferences: prefs);
      await repo.load();

      Future<void> snapDialog({
        required ThemeData theme,
        required bool checked,
        required String fileName,
      }) async {
        if (checked) {
          await repo.markKnown('canter');
        } else {
          await repo.markUnknown('canter');
        }
        tester.view.physicalSize = const Size(480, 680);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          _wrapWithTheme(
            theme: _withScreenshotFonts(theme),
            boundaryKey: boundaryKey,
            child: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: FilledButton(
                    onPressed: () => showDictionaryDefinitionDialog(
                      context,
                      sampleEntries.first,
                      knownTermsRepository: repo,
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await _capturePng(tester, boundaryKey, '$outDir/$fileName');
      }

      await snapDialog(
        theme: mainThemeDark,
        checked: false,
        fileName: 'known_terms_dialog_unchecked_dark.png',
      );
      await snapDialog(
        theme: mainThemeDark,
        checked: true,
        fileName: 'known_terms_dialog_checked_dark.png',
      );
      await snapDialog(
        theme: mainThemeLight,
        checked: false,
        fileName: 'known_terms_dialog_unchecked_light.png',
      );
      await snapDialog(
        theme: mainThemeLight,
        checked: true,
        fileName: 'known_terms_dialog_checked_light.png',
      );

      // Capture Settings Known Terms management screens (Dark & Light).
      await repo.markKnown('canter');
      await repo.markKnown('half-halt');
      await repo.markKnown('collection');

      for (final item in [
        (theme: mainThemeDark, file: 'known_terms_settings_dark.png'),
        (theme: mainThemeLight, file: 'known_terms_settings_light.png'),
      ]) {
        tester.view.physicalSize = const Size(430, 660);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        final key = GlobalKey();
        await tester.pumpWidget(
          _wrapWithTheme(
            theme: _withScreenshotFonts(item.theme),
            boundaryKey: key,
            child: Scaffold(
              appBar: AppBar(title: const Text('Settings')),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    KnownDictionaryTermsSection(
                      repository: repo,
                      entriesOverride: sampleEntries,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await _capturePng(tester, key, '$outDir/${item.file}');
      }
    });
  });
}
