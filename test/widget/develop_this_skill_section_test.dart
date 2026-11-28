// ignore_for_file: lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/develop_this_skill_section.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAppCubit extends MockCubit<AppState> implements AppCubit {}

class _CountingSkillTreeV2Store implements SkillTreeV2Store {
  _CountingSkillTreeV2Store(this._inner);

  final SkillTreeV2Store _inner;
  int fetchFamiliesCalls = 0;
  int fetchSkillsCalls = 0;
  int fetchProgressCalls = 0;
  int fetchVerificationsCalls = 0;

  @override
  Future<List<SkillFamily>> fetchFamilies() {
    fetchFamiliesCalls += 1;
    return _inner.fetchFamilies();
  }

  @override
  Future<List<CurriculumSkill>> fetchSkills() {
    fetchSkillsCalls += 1;
    return _inner.fetchSkills();
  }

  @override
  Future<Map<String, SkillProgressRecord>> fetchProgress({
    required SkillSubject subject,
    required String profileDocId,
  }) {
    fetchProgressCalls += 1;
    return _inner.fetchProgress(subject: subject, profileDocId: profileDocId);
  }

  @override
  Future<Map<String, SkillVerificationRecord>> fetchVerifications({
    required SkillSubject subject,
    required String profileDocId,
  }) {
    fetchVerificationsCalls += 1;
    return _inner.fetchVerifications(
      subject: subject,
      profileDocId: profileDocId,
    );
  }

  @override
  Future<List<VerificationEvent>> fetchVerificationEvents({
    required SkillSubject subject,
    required String profileDocId,
  }) => _inner.fetchVerificationEvents(
    subject: subject,
    profileDocId: profileDocId,
  );

  @override
  Future<void> setLevelProgress({
    required SkillSubject subject,
    required String profileDocId,
    required String skillId,
    required DifficultyState level,
    required LevelState? state,
    required String actorUid,
    String? actorName,
  }) => _inner.setLevelProgress(
    subject: subject,
    profileDocId: profileDocId,
    skillId: skillId,
    level: level,
    state: state,
    actorUid: actorUid,
    actorName: actorName,
  );
}

class _CountingDictionaryStore implements DictionaryStore {
  _CountingDictionaryStore(this._inner);

  final DictionaryStore _inner;
  int loadPublishedCalls = 0;

  @override
  Future<List<DictionaryEntry>> loadPublishedEntries() {
    loadPublishedCalls += 1;
    return _inner.loadPublishedEntries();
  }

  @override
  Future<Map<String, String>> loadSkillLabels() => _inner.loadSkillLabels();

  @override
  Future<void> executeAction(String actionName, Map<String, dynamic> data) =>
      _inner.executeAction(actionName, data);

  @override
  Future<List<Map<String, dynamic>>> loadSuggestions({int limit = 100}) =>
      _inner.loadSuggestions(limit: limit);

  @override
  Future<List<Map<String, dynamic>>> loadMySuggestions(
    String contributorUid, {
    int limit = 50,
  }) => _inner.loadMySuggestions(contributorUid, limit: limit);

  @override
  Future<List<DictionaryEntry>> loadDrafts() => _inner.loadDrafts();

  @override
  Future<DictionaryEntry?> loadDraft(String entryId) =>
      _inner.loadDraft(entryId);

  @override
  Future<List<Map<String, dynamic>>> loadSuggestionHistory(
    String suggestionId, {
    int limit = 30,
  }) => _inner.loadSuggestionHistory(suggestionId, limit: limit);

  @override
  Future<List<Map<String, dynamic>>> loadEntryRevisions(String entryId) =>
      _inner.loadEntryRevisions(entryId);

  @override
  Future<Map<String, Map<String, dynamic>>> resolveContributorIdentities(
    List<String> uids,
  ) => _inner.resolveContributorIdentities(uids);

  @override
  Future<Map<String, Map<String, dynamic>>> loadContributorModerationStatuses(
    List<String> uids,
  ) => _inner.loadContributorModerationStatuses(uids);

  @override
  Future<List<Map<String, dynamic>>> loadContributorModerationHistory(
    String uid, {
    int limit = 30,
  }) => _inner.loadContributorModerationHistory(uid, limit: limit);
}

DictionaryEntry _dictEntry({
  required String id,
  required String slug,
  required String term,
  required String definition,
}) {
  return DictionaryEntry({
    'id': id,
    'slug': slug,
    'term': term,
    'definition': definition,
    'explanation': 'Detailed explanation for $term.',
    'status': 'published',
    'contextual': true,
    'categories': ['Riding & Aids'],
    'synonyms': const <String>[],
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsController settings;
  late InMemorySkillTreeV2Store baseStore;
  late List<DictionaryEntry> sampleEntries;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    settings = SettingsController(SettingsService());
    await settings.loadSettings();
    baseStore = await const AssetCurriculumV2Loader().loadInMemoryStore();
    sampleEntries = [
      _dictEntry(
        id: 'dict-half-halt',
        slug: 'half-halt',
        term: 'Half Halt',
        definition: 'A brief rebalancing cue before asking for the next step.',
      ),
      _dictEntry(
        id: 'dict-rein-contact',
        slug: 'rein-contact',
        term: 'Rein Contact',
        definition: 'Elastic, steady connection without pulling or hanging.',
      ),
      _dictEntry(
        id: 'dict-rein-back',
        slug: 'rein-back',
        term: 'Rein Back',
        definition: 'Stepping backward calmly in diagonal pairs.',
      ),
      _dictEntry(
        id: 'dict-neg-reinf',
        slug: 'negative-reinforcement',
        term: 'Release (Negative Reinforcement)',
        definition: 'Removing light pressure the moment the horse tries.',
      ),
    ];
  });

  tearDown(() {
    DictionaryRepository.defaultStore = null;
    DictionaryRepository.invalidateCache();
    settings.dispose();
  });

  Widget wrapIsolated({
    required Widget child,
    required ThemeData theme,
    Size surfaceSize = const Size(1280, 860),
  }) {
    return MediaQuery(
      data: MediaQueryData(size: surfaceSize),
      child: MaterialApp(
        theme: theme,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: surfaceSize.width),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppState authenticatedState() {
    final rider = RiderProfile(
      id: 'alex@example.com',
      name: 'Alex Rider',
      email: 'alex@example.com',
      picUrl: '',
    );
    final horse = HorseProfile(
      id: 'horse-1',
      name: 'Star',
      currentOwnerId: 'alex@example.com',
      currentOwnerName: 'Alex Rider',
    );
    return const AppState.authenticated(
      User(
        id: 'uid-alex',
        name: 'Alex Rider',
        email: 'alex@example.com',
        isGuest: false,
        emailVerified: true,
      ),
    ).copyWith(
      isGuest: false,
      usersProfile: rider,
      horseProfile: horse,
      hasResourceCatalogue: true,
      resources: const <Resource>[],
    );
  }

  testWidgets('hides cleanly when learningGuide is null or partial fields omit empty headings', (
    tester,
  ) async {
    final skills = await baseStore.fetchSkills();
    final reinBack = skills.firstWhere((s) => s.id == 'rider.mounted.rein_back');
    final withoutGuide = reinBack.copyWith(clearLearningGuide: true);

    await tester.pumpWidget(
      wrapIsolated(
        theme: HorseAndRidersTheme().getDarkTheme(),
        child: DevelopThisSkillSection(
          skill: withoutGuide,
          allSkills: skills,
          dictionaryEntriesOverride: sampleEntries,
        ),
      ),
    );
    expect(find.byKey(const Key('developThisSkillSection')), findsNothing);

    final partialSkill = reinBack.copyWith(
      learningGuide: const SkillLearningGuide(
        trainerInsight: 'Notice timing before adding aid pressure.',
      ),
    );
    await tester.pumpWidget(
      wrapIsolated(
        theme: HorseAndRidersTheme().getDarkTheme(),
        child: DevelopThisSkillSection(
          skill: partialSkill,
          allSkills: skills,
          dictionaryEntriesOverride: sampleEntries,
        ),
      ),
    );
    expect(find.byKey(const Key('developThisSkillSection')), findsOneWidget);
    expect(
      find.byKey(const Key('developSkillTrainerInsightCard')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('developSkillWelfareCard')), findsNothing);
    expect(
      find.byKey(const Key('developSkillFeaturedExerciseCard')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('developSkillCommonDifficultiesToggle')),
      findsNothing,
    );
    expect(find.text('What to notice'), findsNothing);
    expect(find.text('Related:'), findsNothing);
    expect(find.byKey(const Key('developSkillEducationalBadge')), findsOneWidget);
  });

  testWidgets(
    'supports responsive Dark & Light layouts, progressive disclosure, Dictionary modal, and related skill navigation',
    (tester) async {
      final skills = await baseStore.fetchSkills();
      final reinBack = skills.firstWhere(
        (s) => s.id == 'rider.mounted.rein_back',
      );
      String? selectedSkillId;

      Future<void> pumpSection({
        required Size size,
        required ThemeData theme,
        DifficultyState? selectedLevel,
      }) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          wrapIsolated(
            surfaceSize: size,
            theme: theme,
            child: DevelopThisSkillSection(
              skill: reinBack,
              selectedLevel: selectedLevel,
              allSkills: skills,
              dictionaryEntriesOverride: sampleEntries,
              onSelectRelatedSkill: (id) => selectedSkillId = id,
            ),
          ),
        );
        await tester.pump();
      }

      // Desktop Dark: side-by-side Trainer's Insight & Horse Welfare cards
      await pumpSection(
        size: const Size(1280, 860),
        theme: HorseAndRidersTheme().getDarkTheme(),
        selectedLevel: DifficultyState.Introductory,
      );
      expect(find.text('Develop This Skill'), findsOneWidget);
      expect(
        find.text('Practical guidance for Rider · Rein Back'),
        findsOneWidget,
      );
      expect(find.text('One Calm Step at a Time'), findsOneWidget);

      final desktopInsightTop = tester
          .getTopLeft(find.byKey(const Key('developSkillTrainerInsightCard')))
          .dy;
      final desktopWelfareTop = tester
          .getTopLeft(find.byKey(const Key('developSkillWelfareCard')))
          .dy;
      expect(
        (desktopInsightTop - desktopWelfareTop).abs(),
        lessThan(2.0),
        reason: 'Desktop layout places Trainer Insight & Horse Welfare side-by-side',
      );

      // Expand progressive disclosure toggles
      expect(find.text('Straight Line, Quiet Reset Forward'), findsNothing);
      await tester.tap(
        find.byKey(const Key('developSkillMoreExercisesToggle')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Straight Line, Quiet Reset Forward'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('developSkillCommonDifficultiesToggle')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Maintaining rein tension'),
        findsOneWidget,
      );

      // Tap Dictionary footer link -> opens quick definition dialog
      await tester.ensureVisible(
        find.byKey(const Key('developSkillDictTerm_half-halt')),
      );
      await tester.tap(find.byKey(const Key('developSkillDictTerm_half-halt')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dictionaryDefinitionDialog')), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap Related Skill footer link -> triggers navigation callback
      await tester.tap(
        find.byKey(
          const Key('developSkillRelatedSkill_horse.mounted.rein_back'),
        ),
      );
      expect(selectedSkillId, 'horse.mounted.rein_back');

      // Tablet Dark
      await pumpSection(
        size: const Size(768, 1024),
        theme: HorseAndRidersTheme().getDarkTheme(),
        selectedLevel: DifficultyState.Intermediate,
      );
      expect(find.text('Straight Line, Quiet Reset Forward'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Mobile Light: stacked 1-column cards without overflow
      await pumpSection(
        size: const Size(390, 844),
        theme: HorseAndRidersTheme().getLightTheme(),
      );
      final mobileInsightBottom = tester
          .getBottomLeft(find.byKey(const Key('developSkillTrainerInsightCard')))
          .dy;
      final mobileWelfareTop = tester
          .getTopLeft(find.byKey(const Key('developSkillWelfareCard')))
          .dy;
      expect(
        mobileWelfareTop,
        greaterThan(mobileInsightBottom),
        reason: 'Mobile layout stacks Horse Welfare below Trainer Insight',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders all six refined Phase 1 learning guides cleanly', (
    tester,
  ) async {
    final skills = await baseStore.fetchSkills();
    const expectedIds = [
      'rider.in_hand.leading',
      'rider.mounted.seat_balance',
      'rider.mounted.rein_back',
      'horse.in_hand.leading',
      'horse.in_hand.longeing',
      'horse.mounted.rein_back',
    ];
    for (final id in expectedIds) {
      final skill = skills.firstWhere((s) => s.id == id);
      expect(skill.learningGuide?.hasContent, isTrue, reason: '$id guide');
      await tester.pumpWidget(
        wrapIsolated(
          theme: HorseAndRidersTheme().getDarkTheme(),
          child: DevelopThisSkillSection(
            skill: skill,
            selectedLevel: skill.availableLevels.first,
            allSkills: skills,
            dictionaryEntriesOverride: sampleEntries,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('developThisSkillSection')), findsOneWidget);
      expect(
        find.textContaining('Practical guidance for '),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'SkillTreeV2View keeps assessment & verification unchanged and incurs zero extra per-card backend reads',
    (tester) async {
      final countingStore = _CountingSkillTreeV2Store(baseStore);
      final countingRepo = SkillTreeV2Repository(store: countingStore);
      final countingDictStore = _CountingDictionaryStore(
        InMemoryDictionaryStore(publishedEntries: sampleEntries),
      );
      DictionaryRepository.invalidateCache();
      DictionaryRepository.defaultStore = countingDictStore;

      final mockAppCubit = _MockAppCubit();
      final appState = authenticatedState();
      when(() => mockAppCubit.state).thenReturn(appState);

      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        SettingsControllerScope(
          controller: settings,
          child: BlocProvider<AppCubit>.value(
            value: mockAppCubit,
            child: MaterialApp(
              theme: HorseAndRidersTheme().getDarkTheme(),
              home: SkillTreeV2View(
                repository: countingRepo,
                initialSkillId: 'rider.mounted.rein_back',
                enableLocalInstructorPreview: true,
              ),
            ),
          ),
        ),
      );

      for (var i = 0; i < 20; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find
            .byKey(const Key('developThisSkillSection'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      // Existing Skill Detail & assessment/verification controls remain intact.
      expect(find.byKey(const Key('developThisSkillSection')), findsOneWidget);
      expect(find.text('One Calm Step at a Time'), findsOneWidget);
      expect(find.text('Learning'), findsWidgets);
      expect(find.text('Proficient'), findsWidgets);
      expect(find.textContaining('Instructor'), findsWidgets);

      final initialFamiliesReads = countingStore.fetchFamiliesCalls;
      final initialSkillsReads = countingStore.fetchSkillsCalls;
      final initialDictReads = countingDictStore.loadPublishedCalls;
      expect(initialFamiliesReads, 1);
      expect(initialSkillsReads, 1);
      expect(initialDictReads, lessThanOrEqualTo(1));

      // Navigate across multiple skills via footer links and toggle expansions.
      await tester.ensureVisible(
        find.byKey(const Key('developSkillMoreExercisesToggle')),
      );
      await tester.tap(
        find.byKey(const Key('developSkillMoreExercisesToggle')),
      );
      await tester.pump();

      await tester.ensureVisible(
        find.byKey(const Key('developSkillDictTerm_half-halt')),
      );
      await tester.tap(find.byKey(const Key('developSkillDictTerm_half-halt')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dictionaryDefinitionDialog')), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(
          const Key('developSkillRelatedSkill_horse.mounted.rein_back'),
        ),
      );
      await tester.tap(
        find.byKey(
          const Key('developSkillRelatedSkill_horse.mounted.rein_back'),
        ),
      );
      await tester.pump();
      expect(
        find.text('Practical guidance for Horse · Rein Back (Under Saddle)'),
        findsOneWidget,
      );

      // Assert ZERO extra backend reads during card interactions & skill switches.
      expect(countingStore.fetchFamiliesCalls, initialFamiliesReads);
      expect(countingStore.fetchSkillsCalls, initialSkillsReads);
      expect(countingDictStore.loadPublishedCalls, initialDictReads);
    },
  );

  testWidgets(
    'changing selectedLevel collapses expanded additional practice and promotes matching exercise',
    (tester) async {
      final allSkills = await baseStore.fetchSkills();
      final reinBack = allSkills.firstWhere(
        (s) => s.id == 'rider.mounted.rein_back',
      );
      final theme = HorseAndRidersTheme().getDarkTheme();

      await tester.pumpWidget(
        wrapIsolated(
          theme: theme,
          child: DevelopThisSkillSection(
            skill: reinBack,
            allSkills: allSkills,
            selectedLevel: DifficultyState.Introductory,
            dictionaryEntriesOverride: sampleEntries,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('developSkillMoreExercisesToggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('developSkillSecondaryExercise_0')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        wrapIsolated(
          theme: theme,
          child: DevelopThisSkillSection(
            skill: reinBack,
            allSkills: allSkills,
            selectedLevel: DifficultyState.Intermediate,
            dictionaryEntriesOverride: sampleEntries,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('developSkillSecondaryExercise_0')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('developSkillFeaturedExerciseCard')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Theory & Knowledge skills use observational badges and disclosure subtitles',
    (tester) async {
      final allSkills = await baseStore.fetchSkills();
      final theorySkill = allSkills.firstWhere(
        (s) => s.id == 'rider.theory.training_pyramid',
      );

      await tester.pumpWidget(
        wrapIsolated(
          theme: HorseAndRidersTheme().getDarkTheme(),
          child: DevelopThisSkillSection(
            skill: theorySkill,
            allSkills: allSkills,
            selectedLevel: DifficultyState.Introductory,
            dictionaryEntriesOverride: sampleEntries,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          'Practical guidance for Rider · Training Principles & the Training Pyramid',
        ),
        findsOneWidget,
      );
      expect(find.text('OBSERVATION EXERCISE'), findsOneWidget);
      expect(find.text('Additional explorations (2)'), findsOneWidget);
      expect(
        find.text('Optional ways to observe and apply'),
        findsOneWidget,
      );
      expect(
        find.text('2 common misconceptions & perspectives'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'handles unknown links gracefully and smoke-renders all 84 active skills without errors',
    (tester) async {
      final allSkills = await baseStore.fetchSkills();
      expect(allSkills.length, 84);

      final sampleSkill = allSkills.first;
      final baseGuide = sampleSkill.learningGuide!;
      final badLinksSkill = sampleSkill.copyWith(
        learningGuide: SkillLearningGuide(
          exercises: baseGuide.exercises,
          commonDifficulties: baseGuide.commonDifficulties,
          trainerInsight: baseGuide.trainerInsight,
          welfareNote: baseGuide.welfareNote,
          relatedDictionaryTerms: const ['nonexistent-term-slug'],
          relatedSkillIds: const ['nonexistent.skill.id'],
        ),
      );

      await tester.pumpWidget(
        wrapIsolated(
          theme: HorseAndRidersTheme().getLightTheme(),
          child: DevelopThisSkillSection(
            skill: badLinksSkill,
            allSkills: allSkills,
            selectedLevel: badLinksSkill.availableLevels.first,
            dictionaryEntriesOverride: sampleEntries,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('developThisSkillSection')), findsOneWidget);

      final darkTheme = HorseAndRidersTheme().getDarkTheme();
      final lightTheme = HorseAndRidersTheme().getLightTheme();
      for (var i = 0; i < allSkills.length; i++) {
        final skill = allSkills[i];
        await tester.pumpWidget(
          wrapIsolated(
            theme: i.isEven ? darkTheme : lightTheme,
            child: DevelopThisSkillSection(
              skill: skill,
              allSkills: allSkills,
              selectedLevel: skill.availableLevels.first,
              dictionaryEntriesOverride: sampleEntries,
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Unexpected exception rendering ${skill.id}',
        );
        expect(
          find.byKey(const Key('developThisSkillSection')),
          findsOneWidget,
          reason: 'Missing section for ${skill.id}',
        );
      }
    },
  );
}
