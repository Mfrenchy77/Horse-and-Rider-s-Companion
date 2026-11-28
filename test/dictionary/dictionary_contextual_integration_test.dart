// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';
import 'dart:ui' as ui;

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/known_terms_repository.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_page_header.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';
import '../support/visual_test_helpers.dart';

DictionaryEntry _entry({
  required String id,
  required String term,
  required String definition,
  String? slug,
  List<String> synonyms = const [],
  List<String> categories = const ['Training'],
  bool published = true,
  bool contextual = true,
}) => DictionaryEntry({
  'id': id,
  'slug': slug ?? id,
  'term': term,
  'definition': definition,
  'synonyms': synonyms,
  'categories': categories,
  'status': published ? 'published' : 'draft',
  'contextual': contextual,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('dictionary_matcher unit tests', () {
    final entries = [
      _entry(
        id: 'canter',
        term: 'Canter',
        definition: 'A three-beat gait.',
        synonyms: ['lope', 'loping', 'cantering'],
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
        term: 'Half Halt',
        definition: 'A brief, coordinated balancing aid.',
        synonyms: ['half-halt'],
        categories: ['Aids'],
      ),
      _entry(
        id: 'poll',
        term: 'Poll',
        definition: 'The area at the top of the horse’s head behind the ears.',
        categories: ['Anatomy'],
      ),
      _entry(
        id: 'green',
        term: 'Green',
        definition: 'A horse or rider with limited experience.',
        contextual: false,
      ),
      _entry(
        id: 'green-broke',
        term: 'Green Broke',
        definition: 'A horse that has begun ridden training.',
        synonyms: ['green-broken'],
      ),
      _entry(
        id: 'draft-term',
        term: 'Secret Draft',
        definition: 'Must never appear publicly.',
        published: false,
      ),
    ];

    test(
      'matches exact terms, multiword expressions over shorter terms, and synonyms',
      () {
        final matches = matchDictionaryTerms(
          'Ask for a counter-canter, then a relaxed lope and a half halt.',
          entries,
        );
        expect(matches.map((m) => m.entry.id), [
          'counter-canter',
          'canter',
          'half-halt',
        ]);
        expect(
          'Ask for a counter-canter, then a relaxed lope and a half halt.'
              .substring(matches[0].start, matches[0].end),
          'counter-canter',
        );
      },
    );

    test(
      'is case-insensitive, handles punctuation, and enforces whole-word boundaries',
      () {
        final matches = matchDictionaryTerms(
          'Polling the horse near the POLL! (HALF-HALT), not cantered or re-polling.',
          entries,
        );
        expect(matches.map((m) => m.entry.id), ['poll', 'half-halt']);
      },
    );

    test(
      'respects contextual=false, skips unpublished drafts, and skips ambiguous shared names',
      () {
        final ambiguousList = [
          ...entries,
          _entry(
            id: 'lead-gait',
            term: 'Lead',
            definition: 'Which foreleg advances farther in the canter.',
          ),
          _entry(
            id: 'lead-rope',
            term: 'Lead',
            definition: 'A rope attached to a halter for leading a horse.',
          ),
        ];
        final matches = matchDictionaryTerms(
          'A green horse on a lead with Secret Draft and green broke basics.',
          ambiguousList,
        );
        // Only 'green-broke' should auto-highlight ('green' is contextual:false,
        // 'lead' is ambiguous across two published meanings, 'Secret Draft' is draft).
        expect(matches.map((m) => m.entry.id), ['green-broke']);
      },
    );

    test('limits repeated terms to once per meaning and respects maxMatches', () {
      final matches = matchDictionaryTerms(
        'Canter, lope, cantering, loping, and canter again at the poll and half halt.',
        entries,
        maxMatches: 2,
      );
      expect(matches, hasLength(2));
      expect(matches.map((m) => m.entry.id).toSet(), hasLength(2));
    });

    test(
      'manual lookup resolves contextual:false terms, synonyms, hyphen/space variants, punctuation, and ambiguity without leaking drafts',
      () {
        // Contextual=false published term IS found on explicit manual lookup.
        final greenResult = lookupSelectedDictionaryTerm(
          '  "Green."  ',
          entries,
        );
        expect(greenResult.exactMatch?.id, 'green');
        expect(greenResult.normalizedQuery, 'Green');

        // Hyphen/space variant + synonym.
        expect(
          lookupSelectedDictionaryTerm(
            'counter canter',
            entries,
          ).exactMatch?.id,
          'counter-canter',
        );
        expect(
          lookupSelectedDictionaryTerm('loping,', entries).exactMatch?.id,
          'canter',
        );

        // Unpublished draft is NEVER returned.
        final draftResult = lookupSelectedDictionaryTerm(
          'Secret Draft',
          entries,
        );
        expect(draftResult.hasMatch, isFalse);

        // Missing term returns empty result cleanly.
        final missingResult = lookupSelectedDictionaryTerm(
          'unknownword',
          entries,
        );
        expect(missingResult.hasMatch, isFalse);
        expect(missingResult.normalizedQuery, 'unknownword');

        // Ambiguous published term returns all published meanings.
        final ambiguousEntries = [
          _entry(id: 'lead-gait', term: 'Lead', definition: 'Gait lead.'),
          _entry(
            id: 'lead-rope',
            term: 'Lead',
            definition: 'Halter lead rope.',
          ),
        ];
        final ambiguousResult = lookupSelectedDictionaryTerm(
          'lead',
          ambiguousEntries,
        );
        expect(ambiguousResult.exactMatch, isNull);
        expect(
          ambiguousResult.ambiguousMatches.map((e) => e.id),
          containsAll(['lead-gait', 'lead-rope']),
        );
      },
    );
  });

  group('DictionaryText & ContextualDictionaryText widget tests', () {
    late List<DictionaryEntry> seedEntries;
    late AppTestHarness harness;

    setUp(() async {
      DictionaryRepository.invalidateCache();
      seedEntries = await DictionaryRepository.cachedEntries();
      harness = await AppTestHarness.create();
    });

    tearDown(() => harness.close());

    testWidgets(
      'tapping highlighted term opens glass definition popup and navigates to full entry',
      (tester) async {
        String? navigatedSlug;
        final router = GoRouter(
          initialLocation: '/reading',
          routes: [
            GoRoute(
              path: '/reading',
              builder: (_, _) => Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DictionaryText(
                    text: 'Use a light half halt before asking for canter.',
                    entries: seedEntries,
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/Dictionary/:slug',
              builder: (_, state) {
                navigatedSlug = state.pathParameters['slug'];
                return Scaffold(body: Text('Full entry: $navigatedSlug'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(theme: mainThemeDark, routerConfig: router),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'half halt'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('dictionaryDefinitionDialog')),
          findsOneWidget,
        );
        expect(find.text('Half Halt'), findsOneWidget);
        expect(find.text('View full definition'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);

        await tester.tap(find.text('View full definition'));
        await tester.pumpAndSettle();
        expect(navigatedSlug, 'half-halt');
        expect(find.text('Full entry: half-halt'), findsOneWidget);
      },
    );

    testWidgets(
      'manual text selection exposes Define alongside standard actions and opens definitions or not-found message',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: mainThemeDark,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: DictionaryText(
                  text: 'A green horse learns calmly.',
                  entries: seedEntries,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 'green' has contextual=false so it is NOT auto-highlighted as a button.
        expect(find.byType(TextButton), findsNothing);
        expect(find.byType(SelectionArea), findsOneWidget);

        // Drag-select "green" (in Ahem test font each char is 14px wide: "A " = 28px, "green" = 28..98px).
        final textFinder = find.text('A green horse learns calmly.');
        final topLeft = tester.getTopLeft(textFinder);
        final centerY = tester.getCenter(textFinder).dy;

        final gesture = await tester.startGesture(
          Offset(topLeft.dx + 28, centerY),
          kind: PointerDeviceKind.mouse,
        );
        await gesture.moveTo(Offset(topLeft.dx + 100, centerY));
        await gesture.up();
        await tester.pumpAndSettle();

        // Right-click to open the selection context menu.
        final rightClick = await tester.startGesture(
          Offset(topLeft.dx + 56, centerY),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await rightClick.up();
        await tester.pumpAndSettle();

        // Standard Copy action is preserved AND Define is present.
        expect(find.text('Define'), findsOneWidget);
        expect(find.text('Copy'), findsOneWidget);

        await tester.tap(find.text('Define'));
        await tester.pumpAndSettle();

        // Compact definition popup opens for "Green".
        expect(
          find.byKey(const Key('dictionaryDefinitionDialog')),
          findsOneWidget,
        );
        expect(find.text('Green'), findsOneWidget);
        expect(find.text('View full definition'), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        // Direct call to showSelectedTermDefinition for missing term shows non-disruptive dialog.
        final element = tester.element(find.byType(DictionaryText));
        // ignore: unawaited_futures
        showSelectedTermDefinition(
          element,
          selectedText: 'nonexistentterm',
          entries: seedEntries,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('dictionaryNoDefinitionDialog')),
          findsOneWidget,
        );
        expect(find.text('No definition found'), findsOneWidget);
        expect(find.text('Search Dictionary'), findsOneWidget);
      },
    );

    testWidgets(
      'Skill Tree 2.0 (including safety notes) and Resources integrate contextual Dictionary across light/dark themes and responsive viewports',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;

        const sampleSkill = CurriculumSkill(
          id: 'rider.mounted.half_halt',
          name: 'Balancing Aids',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          familyId: 'rider.mounted.aids',
          summary: 'Use a calm half halt to prepare for canter.',
          purpose: 'Support balance before a transition.',
          safety: ['Never rush a green broke horse into counter-canter.'],
          sortOrder: 1,
          availableLevels: [DifficultyState.Introductory],
          levels: {
            DifficultyState.Introductory: SkillLevelDefinition(
              overview: 'Practice smooth transitions.',
              learning: 'Demonstrate a clear half halt on the rail.',
              proficient: 'Maintain relaxed balance in the canter.',
            ),
          },
        );
        const v2State = SkillTreeV2State(
          realm: SkillCategory.Mounted,
          skills: [sampleSkill],
          selectedSkillId: 'rider.mounted.half_halt',
          selectedLevel: DifficultyState.Introductory,
        );

        for (final config in [
          (theme: mainThemeDark, size: const Size(390, 900)),
          (theme: mainThemeLight, size: const Size(1100, 900)),
        ]) {
          tester.view.physicalSize = config.size;
          await tester.pumpWidget(
            BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MaterialApp(
                theme: config.theme,
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        SkillDetailV2Panel(
                          state: v2State,
                          skill: sampleSkill,
                          allResources: const [],
                          canSelfAssess: false,
                          selfAssessDisabledReason: null,
                          canVerify: false,
                          onSelectLevel: (_) {},
                          onSelfAssess: (_, _) {},
                          onVerifyLevel: (_, {required verified}) {},
                          onSelectRelatedSkill: (_) {},
                          onChangeResourceSort: (_) {},
                        ),
                        CommentPageHeader(
                          resource: Resource(
                            id: 'res-1',
                            name: 'Lateral Work Guide',
                            description: 'Introducing shoulder-in calmly.',
                            skillTreeIds: const [],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Safety note, summary, and Resource description all get contextual highlights.
          expect(
            find.widgetWithText(TextButton, 'green broke'),
            findsOneWidget,
          );
          expect(
            find.widgetWithText(TextButton, 'counter-canter'),
            findsOneWidget,
          );
          expect(
            find.widgetWithText(TextButton, 'shoulder-in'),
            findsOneWidget,
          );
          expect(find.byType(SelectionArea), findsWidgets);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'Wave 3 Skill Tree terms highlight cleanly on mobile/desktop and honor Known Terms without extra reads',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;

        final knownRepo = KnownTermsRepository.instance..resetForTest();
        addTearDown(knownRepo.resetForTest);
        expect(seedEntries, hasLength(84));

        const skill = CurriculumSkill(
          id: 'rider.mounted.seat_balance',
          familyId: 'rider.mounted.position_balance_safety',
          name: 'Independent Seat, Position & Balance',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          summary:
              'Developing an independent seat before asking for rein back.',
          purpose: 'Protects balance and avoids learned helplessness.',
          safety: [
            'Maintain an independent seat without bracing on the reins.',
          ],
          availableLevels: [DifficultyState.Introductory],
          levels: {
            DifficultyState.Introductory: SkillLevelDefinition(
              overview: 'Balanced alignment at walk and trot.',
              learning: 'Practices following motion.',
              proficient: 'Rides with balanced alignment.',
            ),
          },
        );
        const state = SkillTreeV2State(
          realm: SkillCategory.Mounted,
          skills: [skill],
          selectedSkillId: 'rider.mounted.seat_balance',
          selectedLevel: DifficultyState.Introductory,
        );

        for (final size in [const Size(390, 844), const Size(1200, 900)]) {
          tester.view.physicalSize = size;
          // Guest mode sees all highlights cleanly.
          knownRepo.resetForTest();
          await tester.pumpWidget(
            BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MaterialApp(
                theme: mainThemeDark,
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: SkillDetailV2Panel(
                      state: state,
                      skill: skill,
                      allResources: const [],
                      canSelfAssess: false,
                      selfAssessDisabledReason: null,
                      canVerify: false,
                      onSelectLevel: (_) {},
                      onSelfAssess: (_, _) {},
                      onVerifyLevel: (_, {required verified}) {},
                      onSelectRelatedSkill: (_) {},
                      onChangeResourceSort: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.widgetWithText(TextButton, 'independent seat'),
            findsWidgets,
          );
          expect(
            find.widgetWithText(TextButton, 'rein back'),
            findsOneWidget,
          );
          expect(
            find.widgetWithText(TextButton, 'learned helplessness'),
            findsOneWidget,
          );

          // Signed-in user marking independent-seat known hides it immediately.
          knownRepo.resetForTest(activeUserId: 'signed-in-rider');
          await knownRepo.markKnown('independent-seat');
          await tester.pumpAndSettle();

          expect(
            find.widgetWithText(TextButton, 'independent seat'),
            findsNothing,
          );
          expect(
            find.widgetWithText(TextButton, 'rein back'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  });

  group('Screenshots (CAPTURE_DICTIONARY_RELEASE_SCREENSHOTS=1)', () {
    Future<void> loadScreenshotFonts() => loadPortableTestFonts();

    ThemeData withReleaseFonts(ThemeData base) => base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: (base.appBarTheme.titleTextStyle ?? const TextStyle())
            .copyWith(fontFamily: 'Roboto'),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: (base.chipTheme.labelStyle ?? const TextStyle()).copyWith(
          fontFamily: 'Roboto',
        ),
      ),
    );

    Future<void> capturePng(
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

    testWidgets(
      'captures Dark and Light release review screenshots across Skill Tree V2 and polished Dictionary UI',
      (tester) async {
        if (Platform.environment['CAPTURE_DICTIONARY_RELEASE_SCREENSHOTS'] !=
            '1') {
          return;
        }

        final outDir = resolveVisualTestOutputDir(fallbackToTempDir: true)!;
        late List<DictionaryEntry> preloadedSeed;
        late SkillTreeV2Repository skillRepo;
        await tester.runAsync(() async {
          await loadScreenshotFonts();
          DictionaryRepository.invalidateCache();
          preloadedSeed = await DictionaryRepository.cachedEntries();
          final inMemoryStore = await const AssetCurriculumV2Loader()
              .loadInMemoryStore();
          skillRepo = SkillTreeV2Repository(store: inMemoryStore);
        });
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final knownRepo = KnownTermsRepository(preferences: prefs)
          ..resetForTest();
        addTearDown(knownRepo.resetForTest);

        final dictRepo = DictionaryRepository(
          store: InMemoryDictionaryStore(publishedEntries: preloadedSeed),
        );

        final settings = SettingsController(SettingsService());
        await settings.loadSettings();
        addTearDown(settings.dispose);

        final harness = await AppTestHarness.create();
        addTearDown(harness.close);

        Future<void> renderTree({
          required ThemeData theme,
          required Size size,
          required String fileName,
          String? skillId,
        }) async {
          tester.view.physicalSize = size;
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundaryKey,
              child: SettingsControllerScope(
                controller: settings,
                child: BlocProvider<AppCubit>.value(
                  value: harness.cubit,
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: withReleaseFonts(theme),
                    builder: (context, child) {
                      final gradients = Theme.of(
                        context,
                      ).extension<SurfaceGradients>();
                      return DecoratedBox(
                        decoration: BoxDecoration(gradient: gradients?.background),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                    home: SkillTreeV2View(
                      repository: skillRepo,
                      initialSkillId: skillId,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle(const Duration(milliseconds: 250));
          await capturePng(tester, boundaryKey, '$outDir/$fileName');
        }

        Future<void> renderDictPage({
          required ThemeData theme,
          required Size size,
          required String slug,
          required String fileName,
        }) async {
          tester.view.physicalSize = size;
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundaryKey,
              child: BlocProvider<AppCubit>.value(
                value: harness.cubit,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: withReleaseFonts(theme),
                  builder: (context, child) {
                    final gradients = Theme.of(
                      context,
                    ).extension<SurfaceGradients>();
                    return DecoratedBox(
                      decoration: BoxDecoration(gradient: gradients?.background),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                  home: DictionaryPage(
                    slug: slug,
                    repository: dictRepo,
                    knownTermsRepository: knownRepo,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await capturePng(tester, boundaryKey, '$outDir/$fileName');
        }

        Future<void> renderQuickDialog({
          required ThemeData theme,
          required DictionaryEntry entry,
          required bool signedIn,
          required String fileName,
        }) async {
          harness.cubit.emit(
            harness.cubit.state.copyWith(
              isGuest: !signedIn,
              user: signedIn
                  ? const User(
                      id: 'uid-preview',
                      email: 'rider@example.com',
                      name: 'Preview Rider',
                      isGuest: false,
                      emailVerified: true,
                    )
                  : User.empty,
            ),
          );
          knownRepo.resetForTest(
            activeUserId: signedIn ? 'uid-preview' : null,
          );

          tester.view.physicalSize = const Size(460, 700);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundaryKey,
              child: BlocProvider<AppCubit>.value(
                value: harness.cubit,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: withReleaseFonts(theme),
                  builder: (context, child) {
                    final gradients = Theme.of(
                      context,
                    ).extension<SurfaceGradients>();
                    return DecoratedBox(
                      decoration: BoxDecoration(gradient: gradients?.background),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                  home: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Builder(
                      builder: (context) => Align(
                        alignment: Alignment.topLeft,
                        child: Opacity(
                          opacity: 0.01,
                          child: TextButton(
                            onPressed: () => showDictionaryDefinitionDialog(
                              context,
                              entry,
                              knownTermsRepository: knownRepo,
                            ),
                            child: const Text('Define'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Define'));
          await tester.pumpAndSettle();
          await capturePng(tester, boundaryKey, '$outDir/$fileName');
        }

        // 1. Skill Tree V2 highlighting (Mobile Dark/Light + Desktop Dark/Light + Categories unchanged).
        await renderTree(
          theme: mainThemeDark,
          size: const Size(390, 844),
          skillId: 'rider.theory.training_pyramid',
          fileName: 'release_skill_tree_mobile_dark.png',
        );
        await renderTree(
          theme: mainThemeLight,
          size: const Size(390, 844),
          skillId: 'rider.theory.training_pyramid',
          fileName: 'release_skill_tree_mobile_light.png',
        );
        await renderTree(
          theme: mainThemeDark,
          size: const Size(1280, 860),
          skillId: 'rider.mounted.seat_balance',
          fileName: 'release_skill_tree_desktop_dark.png',
        );
        await renderTree(
          theme: mainThemeLight,
          size: const Size(1280, 860),
          skillId: 'rider.husbandry.health_monitoring',
          fileName: 'release_skill_tree_desktop_light.png',
        );
        await renderTree(
          theme: mainThemeDark,
          size: const Size(1280, 860),
          fileName: 'release_skill_tree_categories_dark.png',
        );

        // 2. Full Dictionary Page (Mobile + Desktop, Dark + Light).
        await renderDictPage(
          theme: mainThemeDark,
          size: const Size(430, 932),
          slug: 'laminitis',
          fileName: 'release_dictionary_full_mobile_dark.png',
        );
        await renderDictPage(
          theme: mainThemeLight,
          size: const Size(430, 932),
          slug: 'laminitis',
          fileName: 'release_dictionary_full_mobile_light.png',
        );
        await renderDictPage(
          theme: mainThemeDark,
          size: const Size(1280, 860),
          slug: 'rein-back',
          fileName: 'release_dictionary_full_desktop_dark.png',
        );
        await renderDictPage(
          theme: mainThemeLight,
          size: const Size(1280, 860),
          slug: 'rein-back',
          fileName: 'release_dictionary_full_desktop_light.png',
        );

        // 3. Compact Quick Definition Dialog (Signed-In Dark vs Guest Light).
        final independentSeat = DictionaryRepository.resolve(
          preloadedSeed,
          'independent-seat',
        )!;
        final colicEntry = DictionaryRepository.resolve(preloadedSeed, 'colic')!;
        await renderQuickDialog(
          theme: mainThemeDark,
          entry: independentSeat,
          signedIn: true,
          fileName: 'release_dictionary_quick_dialog_dark.png',
        );
        await renderQuickDialog(
          theme: mainThemeLight,
          entry: colicEntry,
          signedIn: false,
          fileName: 'release_dictionary_quick_dialog_light.png',
        );
      },
    );
  });
}
