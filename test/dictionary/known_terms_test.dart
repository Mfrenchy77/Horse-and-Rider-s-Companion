// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_page.dart';
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
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

class _TrackingDictionaryRepository extends DictionaryRepository {
  _TrackingDictionaryRepository(List<DictionaryEntry> entries)
    : _entries = entries,
      super(store: InMemoryDictionaryStore(publishedEntries: entries));

  final List<DictionaryEntry> _entries;
  int loadCalls = 0;

  @override
  bool get usesDefaultBackend => false;

  @override
  Future<List<DictionaryEntry>> load({bool forceRefresh = false}) async {
    loadCalls++;
    return _entries;
  }

  @override
  Future<Map<String, String>> skillLabels() async => const {
    'rider.mounted.posting_trot': 'Posting Trot',
  };
}

class _AuthSessionHarness {
  _AuthSessionHarness._({
    required this.harness,
    required this.userController,
    required this.cubit,
  });

  final AppTestHarness harness;
  final StreamController<User?> userController;
  final AppCubit cubit;

  static Future<_AuthSessionHarness> create({
    required KnownTermsRepository knownTermsRepository,
    User initialUser = User.empty,
  }) async {
    final harness = await AppTestHarness.create();
    final userController = StreamController<User?>.broadcast();
    when(() => harness.auth.currentUser).thenReturn(initialUser);
    when(() => harness.auth.user).thenAnswer((_) => userController.stream);
    when(harness.auth.logOut).thenAnswer((_) async {
      userController.add(User.empty);
    });
    when(
      () => harness.riders.getRiderProfile(email: any(named: 'email')),
    ).thenAnswer((invocation) {
      final email = invocation.namedArguments[#email] as String? ?? '';
      if (email.isEmpty) return Stream.value(null);
      return Stream.value(
        RiderProfile(id: email, name: email.split('@').first, email: email),
      );
    });
    when(
      () =>
          harness.messages.getConversations(userEmail: any(named: 'userEmail')),
    ).thenAnswer((_) => const Stream.empty());

    final cubit = AppCubit(
      authenticationRepository: harness.auth,
      skillTreeRepository: harness.skills,
      resourcesRepository: harness.resources,
      riderProfileRepository: harness.riders,
      horseProfileRepository: harness.horses,
      messagesRepository: harness.messages,
      accountDeletionRepository: harness.accountDeletion,
      knownTermsRepository: knownTermsRepository,
    );
    await Future<void>.microtask(() {});
    if (initialUser.isNotEmpty) {
      userController.add(initialUser);
      await Future<void>.microtask(() {});
    }
    return _AuthSessionHarness._(
      harness: harness,
      userController: userController,
      cubit: cubit,
    );
  }

  Future<void> emitUser(User user) async {
    userController.add(user);
    await Future<void>.microtask(() {});
    await Future<void>.microtask(() {});
  }

  Future<void> close() async {
    await cubit.close();
    await userController.close();
    await harness.close();
  }
}

User _verifiedUser(String uid, {String name = 'Alex Rider'}) => User(
  id: uid,
  name: name,
  email: '$uid@example.com',
  isGuest: false,
  emailVerified: true,
);

DictionaryEntry _entry({
  required String id,
  required String term,
  required String definition,
  String explanation = '',
  List<String> synonyms = const [],
  List<String> categories = const ['Training'],
  List<String> relatedTerms = const [],
  List<String> skillIds = const [],
  bool published = true,
  bool contextual = true,
}) => DictionaryEntry({
  'id': id,
  'slug': id,
  'term': term,
  'definition': definition,
  'explanation': explanation,
  'synonyms': synonyms,
  'categories': categories,
  'relatedTerms': relatedTerms,
  'skillIds': skillIds,
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
  chipTheme: base.chipTheme.copyWith(
    labelStyle: (base.chipTheme.labelStyle ?? const TextStyle()).copyWith(
      fontFamily: 'Roboto',
    ),
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
  AppCubit? cubit,
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
  if (cubit != null) {
    app = BlocProvider<AppCubit>.value(value: cubit, child: app);
  }
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
      explanation:
          'Balanced canter transitions rely on rhythm and a preparatory half-halt without gripping with the knee.',
      synonyms: ['lope', 'cantering', 'loping'],
      categories: ['Gaits'],
      relatedTerms: ['half-halt', 'counter-canter'],
      skillIds: ['rider.mounted.posting_trot'],
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
  });

  tearDown(KnownTermsRepository.instance.resetForTest);

  group('KnownTermsRepository guest lockout & UID isolation unit tests', () {
    test(
      'guests cannot mark or clear known terms and write zero local keys',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final repo = KnownTermsRepository(preferences: prefs);
        await repo.load();

        expect(repo.isEnabled, isFalse);
        expect(repo.activeUserId, isNull);
        expect(repo.currentStorageKey, isNull);
        expect(repo.isLoaded, isTrue);

        var notifications = 0;
        repo.addListener(() => notifications++);

        await repo.markKnown('canter');
        await repo.toggleKnown('half-halt');
        await repo.clearKnownTerms();

        expect(repo.count, 0);
        expect(repo.getKnownTerms(), isEmpty);
        expect(repo.isKnown('canter'), isFalse);
        expect(notifications, 0);
        expect(
          prefs.getKeys().where(
            (k) => k.startsWith(KnownTermsRepository.storageKeyPrefix),
          ),
          isEmpty,
        );
      },
    );

    test(
      'persists per UID, isolates accounts on the same browser, and restores on restart',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final repo = KnownTermsRepository(
          preferences: prefs,
          initialUserId: 'uid-alice',
        );
        await repo.load();

        expect(repo.isEnabled, isTrue);
        expect(repo.isLoaded, isTrue);
        expect(
          repo.currentStorageKey,
          KnownTermsRepository.storageKeyForUser('uid-alice'),
        );

        await repo.markKnown('canter');
        await repo.markKnown(' canter ');
        await repo.markKnown('half-halt');
        expect(repo.getKnownTerms(), {'canter', 'half-halt'});

        // Switch to Bob: Alice's in-memory terms clear immediately and are NOT leaked.
        await repo.setActiveUserId('uid-bob');
        expect(repo.getKnownTerms(), isEmpty);
        expect(repo.isKnown('canter'), isFalse);

        await repo.markKnown('collection');
        expect(repo.getKnownTerms(), {'collection'});

        // Both UID keys exist independently in SharedPreferences.
        expect(
          prefs.getString(KnownTermsRepository.storageKeyForUser('uid-alice')),
          jsonEncode(['canter', 'half-halt']),
        );
        expect(
          prefs.getString(KnownTermsRepository.storageKeyForUser('uid-bob')),
          jsonEncode(['collection']),
        );

        // Switching to guest clears active memory without deleting either account.
        await repo.setActiveUserId(null);
        expect(repo.isEnabled, isFalse);
        expect(repo.count, 0);
        expect(
          prefs.getString(KnownTermsRepository.storageKeyForUser('uid-alice')),
          jsonEncode(['canter', 'half-halt']),
        );
        expect(
          prefs.getString(KnownTermsRepository.storageKeyForUser('uid-bob')),
          jsonEncode(['collection']),
        );

        // Simulated restart directly into Alice's account restores only Alice's terms.
        final restartedAlice = KnownTermsRepository(
          preferences: prefs,
          initialUserId: 'uid-alice',
        );
        await restartedAlice.load();
        expect(restartedAlice.getKnownTerms(), {'canter', 'half-halt'});

        // Clear for Alice removes only Alice's storage key, leaving Bob's untouched.
        await restartedAlice.clearKnownTerms();
        expect(
          prefs.getString(KnownTermsRepository.storageKeyForUser('uid-alice')),
          isNull,
        );
        expect(
          prefs.getString(KnownTermsRepository.storageKeyForUser('uid-bob')),
          jsonEncode(['collection']),
        );
      },
    );

    test(
      'ignores un-namespaced legacy keys and handles malformed per-UID values safely',
      () async {
        final keyAlice = KnownTermsRepository.storageKeyForUser('uid-alice');
        SharedPreferences.setMockInitialValues({
          'dictionary_known_terms_v1': jsonEncode(['poll']),
          keyAlice: jsonEncode(['canter', 123, null, '   ', 'deleted-id']),
        });
        final prefs = await SharedPreferences.getInstance();

        // New user does not inherit un-namespaced legacy guest key.
        final guestRepo = KnownTermsRepository(preferences: prefs);
        await guestRepo.load();
        expect(guestRepo.getKnownTerms(), isEmpty);

        await guestRepo.setActiveUserId('uid-fresh');
        expect(guestRepo.getKnownTerms(), isEmpty);

        // Malformed array elements are filtered cleanly for Alice.
        await guestRepo.setActiveUserId('uid-alice');
        expect(guestRepo.getKnownTerms(), {'canter', 'deleted-id'});

        // Corrupt JSON string fails gracefully.
        SharedPreferences.setMockInitialValues({keyAlice: '{not valid json'});
        final prefsCorrupt = await SharedPreferences.getInstance();
        final corruptRepo = KnownTermsRepository(
          preferences: prefsCorrupt,
          initialUserId: 'uid-alice',
        );
        await corruptRepo.load();
        expect(corruptRepo.getKnownTerms(), isEmpty);
      },
    );
  });

  group('AppCubit auth lifecycle & KnownTermsRepository integration', () {
    test(
      'handles login, account switch, logout, and guest-to-auth without extra Firebase calls or leaks',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final repo = KnownTermsRepository(preferences: prefs);

        // Start as unauthenticated / guest visitor.
        final session = await _AuthSessionHarness.create(
          knownTermsRepository: repo,
        );
        addTearDown(session.close);

        expect(session.cubit.state.isSignedInUser, isFalse);
        expect(repo.isEnabled, isFalse);
        await repo.markKnown('poll'); // Rejected in guest mode.
        expect(repo.getKnownTerms(), isEmpty);

        // Explicit guest User remains blocked.
        await session.emitUser(
          const User(id: 'anon', name: 'Guest', email: ''),
        );
        expect(session.cubit.state.isSignedInUser, isFalse);
        expect(repo.isEnabled, isFalse);

        // Sign in as Alice -> guest terms were never transferred.
        await session.emitUser(_verifiedUser('uid-alice', name: 'Alice'));
        expect(session.cubit.state.isSignedInUser, isTrue);
        expect(repo.activeUserId, 'uid-alice');
        expect(repo.getKnownTerms(), isEmpty);

        await repo.markKnown('canter');
        expect(repo.getKnownTerms(), {'canter'});

        // Switch directly to Bob -> Alice's known terms disappear immediately.
        await session.emitUser(_verifiedUser('uid-bob', name: 'Bob'));
        expect(repo.activeUserId, 'uid-bob');
        expect(repo.getKnownTerms(), isEmpty);
        await repo.markKnown('half-halt');

        // Logout -> guest mode restored immediately while account storage stays intact.
        await session.cubit.logOutRequested();
        await Future<void>.delayed(Duration.zero);
        expect(session.cubit.state.isSignedInUser, isFalse);
        expect(repo.isEnabled, isFalse);
        expect(repo.getKnownTerms(), isEmpty);
        expect(
          prefs.getString(KnownTermsRepository.storageKeyForUser('uid-alice')),
          jsonEncode(['canter']),
        );
        expect(
          prefs.getString(KnownTermsRepository.storageKeyForUser('uid-bob')),
          jsonEncode(['half-halt']),
        );

        // Signing back in as Alice restores Alice's own preference without Bob's.
        await session.emitUser(_verifiedUser('uid-alice', name: 'Alice'));
        expect(repo.getKnownTerms(), {'canter'});
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
        expect(filtered.map((m) => m.entry.id).toList(), ['half-halt', 'poll']);

        final manual = lookupSelectedDictionaryTerm('canter', sampleEntries);
        expect(manual.exactMatch?.id, 'canter');
      },
    );

    test(
      'handles overlapping terminology without leaking sub-terms or suppressing super-terms',
      () {
        const text =
            'Practice a clean counter-canter before transitioning to canter.';
        final hideSuperTerm = matchDictionaryTerms(
          text,
          sampleEntries,
          knownTermIds: {'counter-canter'},
        );
        expect(hideSuperTerm.length, 1);
        expect(hideSuperTerm.single.entry.id, 'canter');
        expect(hideSuperTerm.single.start, greaterThan(text.indexOf('to')));

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

  group(
    'Guest vs Signed-In Dialog, Full DictionaryPage, and Settings synchronization',
    () {
      testWidgets(
        'guest sees highlighting and definition dialog without checkbox or Settings section',
        (tester) async {
          final prefs = await SharedPreferences.getInstance();
          final repo = KnownTermsRepository(preferences: prefs);
          final session = await _AuthSessionHarness.create(
            knownTermsRepository: repo,
          );
          addTearDown(session.close);

          await tester.pumpWidget(
            _wrapWithTheme(
              theme: mainThemeDark,
              cubit: session.cubit,
              child: Scaffold(
                body: DictionaryText(
                  text: 'Ask for a balanced canter plus a half-halt.',
                  entries: sampleEntries,
                  knownTermsRepository: repo,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.widgetWithText(TextButton, 'canter'), findsOneWidget);
          expect(find.widgetWithText(TextButton, 'half-halt'), findsOneWidget);

          await tester.tap(find.text('canter'));
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('dictionaryDefinitionDialog')),
            findsOneWidget,
          );
          expect(
            find.text('A three-beat gait with a moment of suspension.'),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('dictionaryKnownTermCheckbox')),
            findsNothing,
          );
          expect(find.textContaining('I know this term'), findsNothing);

          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();

          // Guest full DictionaryPage: definition + sections visible, checkbox hidden.
          final trackingRepo = _TrackingDictionaryRepository(sampleEntries);
          await tester.pumpWidget(
            _wrapWithTheme(
              theme: mainThemeDark,
              cubit: session.cubit,
              child: DictionaryPage(
                slug: 'canter',
                repository: trackingRepo,
                knownTermsRepository: repo,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text('A three-beat gait with a moment of suspension.'),
            findsOneWidget,
          );
          expect(find.text('Also called'), findsOneWidget);
          expect(find.text('Detailed explanation'), findsOneWidget);
          expect(
            find.byKey(const Key('dictionaryKnownTermCheckbox')),
            findsNothing,
          );
          expect(find.textContaining('I know this term'), findsNothing);
          expect(trackingRepo.loadCalls, 1);

          // Guest SettingsView: Dictionary Known Terms section is hidden.
          final settings = SettingsController(SettingsService());
          await settings.loadSettings();
          addTearDown(settings.dispose);

          await tester.pumpWidget(
            _wrapWithTheme(
              theme: mainThemeLight,
              cubit: session.cubit,
              child: SettingsView(controller: settings),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('knownTermsSettingsCard')), findsNothing);
          expect(find.text('Known Dictionary Terms'), findsNothing);
        },
      );

      testWidgets(
        'checking in quick dialog updates live highlighting, syncs to full DictionaryPage & Settings, and unchecking on full page or logging out restores highlighting',
        (tester) async {
          final prefs = await SharedPreferences.getInstance();
          final repo = KnownTermsRepository(preferences: prefs);
          final session = await _AuthSessionHarness.create(
            knownTermsRepository: repo,
            initialUser: _verifiedUser('uid-alice'),
          );
          addTearDown(session.close);

          var unrelatedRebuildCount = 0;

          await tester.pumpWidget(
            _wrapWithTheme(
              theme: mainThemeDark,
              cubit: session.cubit,
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

          final initialUnrelatedBuilds = unrelatedRebuildCount;

          // Open quick definition dialog for Canter.
          await tester.tap(find.text('canter'));
          await tester.pumpAndSettle();

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

          // Toggle checkbox -> stays open, persists under UID, updates highlight live.
          await tester.tap(checkboxFinder);
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('dictionaryDefinitionDialog')),
            findsOneWidget,
          );
          expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
          expect(repo.isKnown('canter'), isTrue);
          expect(
            prefs.getString(
              KnownTermsRepository.storageKeyForUser('uid-alice'),
            ),
            jsonEncode(['canter']),
          );

          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();

          expect(find.widgetWithText(TextButton, 'canter'), findsNothing);
          expect(find.widgetWithText(TextButton, 'half-halt'), findsOneWidget);
          expect(find.widgetWithText(TextButton, 'poll'), findsOneWidget);
          expect(unrelatedRebuildCount, initialUnrelatedBuilds);

          // Open full DictionaryPage for 'canter': toggle appears after primary
          // definition / synonyms, shows checked, and preserves existing sections.
          final dictRepo = _TrackingDictionaryRepository(sampleEntries);
          await tester.pumpWidget(
            _wrapWithTheme(
              theme: mainThemeLight,
              cubit: session.cubit,
              child: DictionaryPage(
                slug: 'canter',
                repository: dictRepo,
                knownTermsRepository: repo,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(checkboxFinder, findsOneWidget);
          expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
          expect(find.text('Detailed explanation'), findsOneWidget);
          expect(find.text('Related terminology'), findsOneWidget);
          expect(find.text('Related skills'), findsOneWidget);
          expect(find.text('Suggest an improvement'), findsOneWidget);
          expect(find.text('Contribute images'), findsOneWidget);
          expect(find.text('Share term'), findsOneWidget);
          // Existing educational content on full page keeps other terms highlighted.
          expect(find.widgetWithText(TextButton, 'half-halt'), findsOneWidget);

          final pageDefRect = tester.getRect(
            find.text('A three-beat gait with a moment of suspension.'),
          );
          final pageCheckboxRect = tester.getRect(checkboxFinder);
          final detailedExplanationRect = tester.getRect(
            find.text('Detailed explanation'),
          );
          expect(pageCheckboxRect.top, greaterThan(pageDefRect.bottom));
          expect(pageCheckboxRect.bottom, lessThan(detailedExplanationRect.top));

          // Verify KnownDictionaryTermsSection shows Canter in sync.
          await tester.pumpWidget(
            _wrapWithTheme(
              theme: mainThemeDark,
              cubit: session.cubit,
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
          expect(find.text('1 term'), findsOneWidget);
          expect(find.text('Canter'), findsOneWidget);

          // Uncheck on full DictionaryPage -> reflects in reopened quick dialog.
          await tester.pumpWidget(
            _wrapWithTheme(
              theme: mainThemeDark,
              cubit: session.cubit,
              child: DictionaryPage(
                slug: 'canter',
                repository: dictRepo,
                knownTermsRepository: repo,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);

          await tester.tap(checkboxFinder);
          await tester.pumpAndSettle();
          expect(tester.widget<Checkbox>(checkboxFinder).value, isFalse);
          expect(repo.isKnown('canter'), isFalse);

          // Check again on full DictionaryPage -> verify quick dialog & Settings sync.
          await tester.tap(checkboxFinder);
          await tester.pumpAndSettle();
          expect(repo.isKnown('canter'), isTrue);

          await tester.pumpWidget(
            _wrapWithTheme(
              theme: mainThemeDark,
              cubit: session.cubit,
              child: Scaffold(
                body: DictionaryText(
                  text: 'Ask for a balanced canter plus a half-halt.',
                  entries: sampleEntries,
                  knownTermsRepository: repo,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // Known canter is suppressed while half-halt stays highlighted.
          expect(find.widgetWithText(TextButton, 'canter'), findsNothing);
          expect(find.widgetWithText(TextButton, 'half-halt'), findsOneWidget);

          // Quick dialog opened via selection reflects checked state from full page.
          final reopenFuture = showSelectedTermDefinition(
            tester.element(find.byType(Scaffold)),
            selectedText: 'canter',
            entries: sampleEntries,
            knownTermsRepository: repo,
          );
          await tester.pumpAndSettle();
          expect(tester.widget<Checkbox>(checkboxFinder).value, isTrue);
          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();
          await reopenFuture;

          // Logging out restores guest highlighting immediately & hides signed-in UI.
          await session.cubit.logOutRequested();
          await tester.pumpAndSettle();
          expect(find.widgetWithText(TextButton, 'canter'), findsOneWidget);
          expect(find.widgetWithText(TextButton, 'half-halt'), findsOneWidget);
          expect(
            prefs.getString(
              KnownTermsRepository.storageKeyForUser('uid-alice'),
            ),
            jsonEncode(['canter']),
          );
        },
      );

      testWidgets(
        'works in SkillDetailV2Panel for signed-in users while keeping all terms highlighted for guests',
        (tester) async {
          DictionaryRepository.entriesNotifier.value = sampleEntries;
          final prefs = await SharedPreferences.getInstance();
          final repo = KnownTermsRepository(preferences: prefs);
          final session = await _AuthSessionHarness.create(
            knownTermsRepository: repo,
            initialUser: _verifiedUser('uid-alice'),
          );
          addTearDown(session.close);
          await KnownTermsRepository.instance.setActiveUserId('uid-alice');
          await KnownTermsRepository.instance.markKnown('canter');
          addTearDown(KnownTermsRepository.instance.resetForTest);

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

          String? tappedRelatedId;
          await tester.pumpWidget(
            _wrapWithTheme(
              theme: mainThemeDark,
              cubit: session.cubit,
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
          );
          await tester.pumpAndSettle();

          expect(find.widgetWithText(TextButton, 'canter'), findsNothing);
          expect(find.widgetWithText(TextButton, 'half-halt'), findsWidgets);
          await tester.tap(find.widgetWithText(ActionChip, 'Posting Trot'));
          await tester.pumpAndSettle();
          expect(tappedRelatedId, 'rider.mounted.posting_trot');

          // Sign out to guest -> 'canter' highlighting immediately returns in Skill Tree.
          await KnownTermsRepository.instance.setActiveUserId(null);
          await session.cubit.logOutRequested();
          await tester.pumpAndSettle();
          expect(find.widgetWithText(TextButton, 'canter'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    },
  );

  group('KnownDictionaryTermsSection & Settings management', () {
    testWidgets(
      'displays empty state, missing-ID fallback, individual Remove, clear-all confirmation, and Dark/Light responsive layouts for signed-in users',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();
        final repo = KnownTermsRepository(
          preferences: prefs,
          initialUserId: 'uid-alice',
        );
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

        await pumpSection(const Size(390, 844), mainThemeDark);
        expect(find.byKey(const Key('knownTermsEmptyState')), findsOneWidget);
        expect(find.text('0 terms'), findsOneWidget);
        expect(find.byKey(const Key('clearAllKnownTermsButton')), findsNothing);

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

        await tester.enterText(
          find.byKey(const Key('knownTermsSearchField')),
          'half',
        );
        await tester.pumpAndSettle();
        expect(find.text('Half-Halt'), findsOneWidget);
        expect(find.text('Canter'), findsNothing);

        await tester.enterText(
          find.byKey(const Key('knownTermsSearchField')),
          '',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('removeKnownTerm_half-halt')));
        await tester.pumpAndSettle();
        expect(repo.isKnown('half-halt'), isFalse);
        expect(find.text('4 terms'), findsOneWidget);

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

        await repo.markKnown('canter');
        await repo.markKnown('collection');
        await pumpSection(const Size(1180, 820), mainThemeLight);
        expect(find.text('2 terms'), findsOneWidget);
        expect(find.text('Canter'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SettingsView shows KnownDictionaryTermsSection when signed in on Mobile & Desktop and hides it on logout',
      (tester) async {
        final session = await _AuthSessionHarness.create(
          knownTermsRepository: KnownTermsRepository.instance,
          initialUser: _verifiedUser('uid-alice'),
        );
        addTearDown(session.close);
        final prefs = await SharedPreferences.getInstance();
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
          _wrapWithTheme(
            theme: _withScreenshotFonts(mainThemeLight),
            cubit: session.cubit,
            child: SettingsView(controller: settings),
          ),
        );
        await tester.pumpAndSettle();

        final card = find.byKey(const Key('knownTermsSettingsCard'));
        expect(card, findsOneWidget);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(find.text('Collection'), findsOneWidget);

        // Desktop check: no overflow.
        tester.view.physicalSize = const Size(1180, 820);
        await tester.pumpAndSettle();
        expect(find.text('Collection'), findsOneWidget);

        // Logout hides the Settings section cleanly while keeping Alice's stored key.
        await session.cubit.logOutRequested();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('knownTermsSettingsCard')), findsNothing);
        expect(find.text('Known Dictionary Terms'), findsNothing);
        expect(
          prefs.getString(KnownTermsRepository.storageKeyForUser('uid-alice')),
          jsonEncode(['collection']),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Screenshots (CAPTURE_KNOWN_TERMS_SCREENSHOTS=1)', () {
    testWidgets(
      'captures Dark and Light screenshots for Guest & Signed-In dialogs, full DictionaryPage, and Settings',
      (tester) async {
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
        final session = await _AuthSessionHarness.create(
          knownTermsRepository: repo,
        );
        addTearDown(session.close);
        final dictRepo = _TrackingDictionaryRepository(sampleEntries);

        Future<void> snapDialog({
          required ThemeData theme,
          required bool signedIn,
          required bool checked,
          required String fileName,
        }) async {
          if (signedIn) {
            await session.emitUser(_verifiedUser('uid-alice'));
            if (checked) {
              await repo.markKnown('canter');
            } else {
              await repo.markUnknown('canter');
            }
          } else {
            await session.emitUser(User.empty);
          }

          tester.view.physicalSize = const Size(480, 680);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            _wrapWithTheme(
              theme: _withScreenshotFonts(theme),
              cubit: session.cubit,
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

        Future<void> snapFullPage({
          required ThemeData theme,
          required bool signedIn,
          required String fileName,
        }) async {
          if (signedIn) {
            await session.emitUser(_verifiedUser('uid-alice'));
            await repo.markKnown('canter');
          } else {
            await session.emitUser(User.empty);
          }

          tester.view.physicalSize = const Size(460, 960);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            _wrapWithTheme(
              theme: _withScreenshotFonts(theme),
              cubit: session.cubit,
              boundaryKey: boundaryKey,
              child: DictionaryPage(
                slug: 'canter',
                repository: dictRepo,
                knownTermsRepository: repo,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await _capturePng(tester, boundaryKey, '$outDir/$fileName');
        }

        // 1. Guest quick definition — no checkbox (Dark & Light).
        await snapDialog(
          theme: mainThemeDark,
          signedIn: false,
          checked: false,
          fileName: 'known_terms_guest_dialog_dark.png',
        );
        await snapDialog(
          theme: mainThemeLight,
          signedIn: false,
          checked: false,
          fileName: 'known_terms_guest_dialog_light.png',
        );

        // 2. Signed-in quick definition — checkbox (Dark & Light).
        await snapDialog(
          theme: mainThemeDark,
          signedIn: true,
          checked: true,
          fileName: 'known_terms_signed_in_dialog_dark.png',
        );
        await snapDialog(
          theme: mainThemeLight,
          signedIn: true,
          checked: false,
          fileName: 'known_terms_signed_in_dialog_light.png',
        );

        // 3. Signed-in full Dictionary page — checkbox (Dark & Light).
        await snapFullPage(
          theme: mainThemeDark,
          signedIn: true,
          fileName: 'known_terms_signed_in_full_page_dark.png',
        );
        await snapFullPage(
          theme: mainThemeLight,
          signedIn: true,
          fileName: 'known_terms_signed_in_full_page_light.png',
        );

        // 4. Guest full Dictionary page — no checkbox (Dark & Light).
        await snapFullPage(
          theme: mainThemeDark,
          signedIn: false,
          fileName: 'known_terms_guest_full_page_dark.png',
        );
        await snapFullPage(
          theme: mainThemeLight,
          signedIn: false,
          fileName: 'known_terms_guest_full_page_light.png',
        );

        // 5. Refresh signed-in Settings Known Terms card (Dark & Light).
        await session.emitUser(_verifiedUser('uid-alice'));
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
              cubit: session.cubit,
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
      },
    );
  });
}
