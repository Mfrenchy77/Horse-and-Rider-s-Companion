// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';
import 'dart:ui' as ui;

import 'package:authentication_repository/authentication_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/adaptive_app_bar_actions.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_admin_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_suggestion_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/guest_profile.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/comment_page_header.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

import '../support/app_test_harness.dart';

const _scratchDir =
    '/home/matteo/.gemini/antigravity/brain/9959963d-cf2a-4c61-946a-61af8edc96d7/scratch';

Future<void> _captureView(WidgetTester tester, String filename) async {
  await tester.runAsync(() async {
    final boundaryFinder = find.byKey(const Key('dictionaryCaptureBoundary'));
    if (boundaryFinder.evaluate().isEmpty) return;
    final boundary =
        tester.renderObject(boundaryFinder) as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final dir = Directory(_scratchDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      await File('$_scratchDir/$filename').writeAsBytes(
        byteData.buffer.asUint8List(),
      );
    }
  });
}

class RecordingDictionary extends DictionaryRepository {
  RecordingDictionary(this.entries, {super.firestore});
  final List<DictionaryEntry> entries;
  Map<String, dynamic>? submitted;
  final List<(String, Map<String, dynamic>)> calls = [];
  @override
  Future<Map<String, String>> skillLabels() async => {
    'rider.mounted.canter': 'Rider · Canter / Lope',
  };
  @override
  Future<List<DictionaryEntry>> load() async => entries;
  @override
  Future<void> call(String function, Map<String, dynamic> data) async {
    submitted = data;
    calls.add((function, data));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<DictionaryEntry> entries;
  late AppTestHarness harness;
  setUp(() async {
    DictionaryRepository.invalidateCache();
    entries = await DictionaryRepository.cachedEntries();
    harness = await AppTestHarness.create();
  });
  tearDown(() => harness.close());

  Widget wrap(Widget child) => RepaintBoundary(
    key: const Key('dictionaryCaptureBoundary'),
    child: BlocProvider<AppCubit>.value(
      value: harness.cubit,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: mainThemeDark,
        home: child,
      ),
    ),
  );

  test(
    'starter meanings cover all 12 requested terms, Canter/Lope unity, synonyms, categories, and ambiguous words',
    () {
      expect(entries, hasLength(11));
      const starterTerms = [
        'Green',
        'Green Broke',
        'Canter',
        'Lope',
        'Ground Tie',
        'Groundwork',
        'Half Halt',
        'Collection',
        'Shoulder-In',
        'Counter-Canter',
        'Poll',
        'Withers',
      ];
      for (final term in starterTerms) {
        final resolved = DictionaryRepository.resolve(entries, term);
        expect(resolved, isNotNull, reason: 'Starter term "$term" must resolve');
      }
      // Canter and Lope resolve to the single canonical entry 'canter'
      final canter = DictionaryRepository.resolve(entries, 'Canter')!;
      final lope = DictionaryRepository.resolve(entries, 'Lope')!;
      expect(canter.id, 'canter');
      expect(lope.id, 'canter');
      expect(canter.text('usage'), contains('Western'));
      expect(canter.text('regionalUsage'), isNotEmpty);

      expect(
        DictionaryRepository.resolve(entries, 'ground work')?.slug,
        'groundwork',
      );
      expect(
        DictionaryRepository.resolve(entries, 'half-halt')?.slug,
        'half-halt',
      );
      expect(
        DictionaryRepository.search(entries, query: 'loping').single.slug,
        'canter',
      );
      expect(
        DictionaryRepository.search(entries, category: 'Anatomy'),
        hasLength(2),
      );
      expect(
        DictionaryRepository.search(entries, letter: 'W').single.slug,
        'withers',
      );
      expect(
        DictionaryRepository.search(entries, query: 'no-such-term'),
        isEmpty,
      );
      final matches = matchDictionaryTerms(
        'Green grass, collection boxes, polling. '
        'Counter-canter and canter; canter again, half-halt.',
        entries,
      );
      expect(matches.map((match) => match.entry.slug), [
        'counter-canter',
        'canter',
        'half-halt',
      ]);
      expect(
        matchDictionaryTerms('cantering', entries).single.entry.slug,
        'canter',
      );
    },
  );

  test('published manifest suppresses bundled fallback and drafts', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('DictionaryPublic').doc('catalogue').set({
      'initialized': true,
    });
    await db
        .collection('DictionaryEntries')
        .doc('canter')
        .set(entries.firstWhere((entry) => entry.slug == 'canter').data);
    await db.collection('DictionaryEntries').doc('private').set({
      ...entries.first.data,
      'status': 'draft',
    });
    final loaded = await DictionaryRepository(firestore: db).load();
    expect(loaded.single.slug, 'canter');
    await db.collection('DictionaryEntries').doc('canter').delete();
    expect(await DictionaryRepository(firestore: db).load(), isEmpty);
  });

  testWidgets('public browse supports search, filters, mobile and desktop layouts', (
    tester,
  ) async {
    // 1. Desktop guest browse
    tester.view.physicalSize = const Size(1180, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      wrap(DictionaryPage(repository: RecordingDictionary(entries))),
    );
    await tester.pumpAndSettle();
    await _captureView(tester, 'dictionary_guest_desktop.png');

    // 2. Mobile guest browse
    tester.view.physicalSize = const Size(390, 850);
    await tester.pumpAndSettle();
    await _captureView(tester, 'dictionary_guest_mobile.png');

    await tester.enterText(find.byType(TextField), 'loping');
    await tester.pumpAndSettle();
    expect(find.text('Canter'), findsOneWidget);
    expect(find.textContaining('Also called: loping'), findsOneWidget);
    expect(find.text('Withers'), findsNothing);
    await tester.enterText(find.byType(TextField), 'zzzzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('No matching terms.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unauthenticated detail deep links and synonym URLs open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/Dictionary/lope',
      routes: [
        GoRoute(
          path: '/Dictionary/:termSlug',
          builder: (_, state) => DictionaryPage(
            slug: state.pathParameters['termSlug'],
            repository: RecordingDictionary(entries),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('dictionaryCaptureBoundary'),
        child: BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: mainThemeDark,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Canter'), findsWidgets);
    expect(find.textContaining('Western riding'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(find.byTooltip('Share definition'), findsOneWidget);
    await _captureView(tester, 'dictionary_term_detail.png');
  });

  testWidgets('context definition opens in SkillDetailV2Panel and Resources without replacing reader', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const sampleSkill = CurriculumSkill(
      id: 'rider.mounted.half_halt',
      familyId: 'fam_mounted',
      subject: SkillSubject.rider,
      realm: SkillCategory.Mounted,
      name: 'Balancing Transitions',
      summary: 'Use a gentle half halt before asking for canter.',
      purpose: 'Prepare balanced transitions without pulling.',
      sortOrder: 1,
      availableLevels: [DifficultyState.Introductory],
      levels: {
        DifficultyState.Introductory: SkillLevelDefinition(
          overview: 'Coordinate seat and aids during groundwork and riding.',
          learning: 'Practises timely release.',
          proficient: 'Maintains soft balance.',
        ),
      },
    );
    const v2State = SkillTreeV2State(
      realm: SkillCategory.Mounted,
      skills: [sampleSkill],
      selectedSkillId: 'rider.mounted.half_halt',
      selectedLevel: DifficultyState.Introductory,
    );

    await tester.pumpWidget(
      wrap(
        Scaffold(
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
                    name: 'Lateral Suppleness Guide',
                    description: 'Introducing shoulder-in on a calm circle.',
                    skillTreeIds: const ['rider.mounted.shoulder_in'],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Recognized terms in SkillDetailV2Panel AND Resource detail header are interactive!
    expect(find.widgetWithText(TextButton, 'half halt'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'shoulder-in'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'half halt'));
    await tester.pumpAndSettle();
    expect(find.text('Full definition'), findsOneWidget);
    expect(find.textContaining('brief, coordinated request'), findsOneWidget);
    await _captureView(tester, 'dictionary_contextual_popover.png');

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('guest submission succeeds, encourages optional account creation, and signed-in submission confirms private follow-up', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Guest flow
    harness.cubit.emit(harness.cubit.state.copyWith(isGuest: true));
    final repo = RecordingDictionary(entries);
    await tester.pumpWidget(
      wrap(Scaffold(body: DictionarySuggestionDialog(repository: repo))),
    );
    await tester.pumpAndSettle();
    await _captureView(tester, 'dictionary_guest_suggestion.png');

    await tester.enterText(find.byType(TextFormField).at(0), 'Jog');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Explain Western usage of jog.',
    );
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    await tester.tap(find.text('Submit suggestion'));
    await tester.pumpAndSettle();
    expect(repo.submitted?['recognitionConsent'], isFalse);
    expect(repo.submitted?['publicName'], '');
    expect(find.textContaining('submitted for review'), findsOneWidget);
    expect(
      find.byKey(const Key('dictionaryCreateAccountButton')),
      findsOneWidget,
    );
    expect(find.text('Sign in'), findsNothing);

    // 2. Signed-in flow with opt-in attribution
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(
          id: 'member',
          email: 'rider@example.com',
          name: 'Alex Rider',
        ),
        user: const User(
          id: 'uid-alex',
          email: 'rider@example.com',
          name: 'Alex Rider',
          isGuest: false,
          emailVerified: true,
        ),
      ),
    );
    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: DictionarySuggestionDialog(
            key: const Key('signedInSuggestionDialog'),
            repository: repo,
            entry: entries.first,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Clarify arena vs trail examples.',
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), 'Alex R.');
    await _captureView(tester, 'dictionary_signed_in_suggestion.png');

    await tester.tap(find.text('Submit suggestion'));
    await tester.pumpAndSettle();
    expect(repo.submitted?['kind'], 'correction');
    expect(repo.submitted?['recognitionConsent'], isTrue);
    expect(repo.submitted?['publicName'], 'Alex R.');
    expect(
      find.textContaining('email address is never shown publicly'),
      findsOneWidget,
    );
  });

  testWidgets('Guest Welcome opens the public Dictionary from dedicated card', (
    tester,
  ) async {
    harness.cubit.emit(harness.cubit.state.copyWith(isGuest: true));
    final router = GoRouter(
      initialLocation: '/Profile',
      routes: [
        GoRoute(path: '/Profile', builder: (_, _) => const GuestProfile()),
        GoRoute(
          path: '/Dictionary',
          builder: (_, _) =>
              DictionaryPage(repository: RecordingDictionary(entries)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp.router(theme: mainThemeDark, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(const Key('guestExploreDictionary'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);
    expect(find.text('Equestrian words, explained'), findsOneWidget);
  });

  testWidgets(
    'ordinary users are blocked, while verified admins review suggestions, preview, check duplicates, view history, and publish',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Ordinary user blocked
      await tester.pumpWidget(wrap(const DictionaryAdminPage()));
      await tester.pumpAndSettle();
      expect(find.text('Administrator access required.'), findsOneWidget);
      expect(find.text('New definition'), findsNothing);

      // 2. Verified administrator moderation & publication workflow
      final db = FakeFirebaseFirestore();
      await db.collection('DictionarySuggestions').doc('sug-1').set({
        'term': 'Jog',
        'proposal': 'A relaxed two-beat Western trot.',
        'kind': 'missing_term',
        'status': 'approved',
        'recognitionConsent': true,
        'publicName': 'Taylor Trail',
        'contributorUid': 'uid-taylor',
        'createdAt': Timestamp.now(),
      });
      await db
          .collection('DictionarySuggestions')
          .doc('sug-1')
          .collection('AuditEvents')
          .add({
            'status': 'approved',
            'note': 'Accurate Western gait usage.',
            'at': Timestamp.now(),
          });
      await db
          .collection('DictionaryDrafts')
          .doc('canter')
          .collection('Revisions')
          .doc('1')
          .set({
            'revision': 1,
            'status': 'published',
            'definition': 'Three-beat gait.',
          });

      final repo = RecordingDictionary(entries, firestore: db);
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          usersProfile: RiderProfile(
            id: 'admin',
            email: 'admin@example.com',
            name: 'Admin',
          ),
          user: const User(
            id: 'uid-admin',
            email: 'admin@example.com',
            name: 'Admin',
            isGuest: false,
            emailVerified: true,
            isAdmin: true,
          ),
        ),
      );

      await tester.pumpWidget(
        wrap(DictionaryAdminPage(firestore: db, repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jog'), findsOneWidget);
      expect(
        find.textContaining('Opt-in recognition requested as: Taylor Trail'),
        findsOneWidget,
      );
      await _captureView(tester, 'dictionary_admin_moderation.png');

      // Inspect contribution audit history
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Accurate Western gait usage.'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Incorporate approved suggestion -> check duplicate warning if typing "Lope" -> revert to "Jog", preview, and publish
      await tester.tap(find.text('Incorporate wording'));
      await tester.pumpAndSettle();
      expect(find.text('New Dictionary definition'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('dictionaryField_term')),
        'Lope',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dictionaryDuplicateTermWarning')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('dictionaryField_term')),
        'Jog',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('dictionaryDuplicateTermWarning')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('dictionaryPreviewButton')));
      await tester.pumpAndSettle();
      expect(find.text('Preview · Jog'), findsOneWidget);
      await tester.tap(find.text('Close preview'));
      await tester.pumpAndSettle();

      final publishBtn = find.text('Publish reviewed definition');
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();
      expect(repo.calls.last.$1, 'editDictionary');
      expect(repo.calls.last.$2['action'], 'publish');
      expect(repo.calls.last.$2['id'], 'jog');
      expect(repo.calls.last.$2['suggestionId'], 'sug-1');
    },
  );

  testWidgets('adaptive actions move into overflow and restore callbacks', (
    tester,
  ) async {
    var count = 0;
    Widget actions(double width) => MediaQuery(
      data: MediaQueryData(size: Size(width, 800)),
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              AdaptiveAppBarActions(
                actions: [
                  for (var i = 0; i < 4; i++)
                    AdaptiveAppBarAction(
                      label: 'Action $i',
                      icon: Icons.add,
                      priority: i,
                      onPressed: () => count++,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(actions(320));
    expect(find.byTooltip('Action 3'), findsOneWidget);
    expect(find.byTooltip('Action 0'), findsNothing);
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Action 0'));
    await tester.pumpAndSettle();
    expect(count, 1);
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(actions(1200));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Action 0'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
