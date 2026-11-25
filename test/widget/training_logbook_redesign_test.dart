// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/log_view_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

class _MockConnectionRepository extends Mock implements ConnectionRepository {}

CurriculumSkill _riderSkill({
  String id = 'rider_balanced_halt',
  String name = 'Balanced Halt',
}) => CurriculumSkill(
  id: id,
  familyId: 'fam_rider_mounted',
  subject: SkillSubject.rider,
  realm: SkillCategory.Mounted,
  name: name,
  summary: 'Balanced, square halt from walk and trot.',
  purpose: 'Clear deceleration without pulling.',
  sortOrder: 1,
  availableLevels: const [
    DifficultyState.Introductory,
    DifficultyState.Intermediate,
  ],
  levels: const {
    DifficultyState.Introductory: SkillLevelDefinition(
      overview: 'Intro halt',
      learning: 'Learning halt',
      proficient: 'Proficient halt',
    ),
    DifficultyState.Intermediate: SkillLevelDefinition(
      overview: 'Intermediate halt',
      learning: 'Learning intermediate halt',
      proficient: 'Proficient intermediate halt',
    ),
  },
);

CurriculumSkill _horseSkill({
  String id = 'horse_calm_standing',
  String name = 'Calm Standing & Patience',
}) => CurriculumSkill(
  id: id,
  familyId: 'fam_horse_in_hand',
  subject: SkillSubject.horse,
  realm: SkillCategory.In_Hand,
  name: name,
  summary: 'Stands quietly on a loose lead.',
  purpose: 'Relaxed stillness.',
  sortOrder: 2,
  availableLevels: const [DifficultyState.Introductory],
  levels: const {
    DifficultyState.Introductory: SkillLevelDefinition(
      overview: 'Intro standing',
      learning: 'Learning standing',
      proficient: 'Proficient standing',
    ),
  },
);

SkillFamily _riderFamily() => const SkillFamily(
  id: 'fam_rider_mounted',
  subject: SkillSubject.rider,
  realm: SkillCategory.Mounted,
  name: 'Transitions & Halts',
  description: 'Mounted transitions.',
  sortOrder: 1,
);

SkillFamily _horseFamily() => const SkillFamily(
  id: 'fam_horse_in_hand',
  subject: SkillSubject.horse,
  realm: SkillCategory.In_Hand,
  name: 'Ground Manners',
  description: 'In-hand groundwork.',
  sortOrder: 1,
);

void main() {
  setUpAll(() => registerFallbackValue(BaseListItem()));

  group('RiderLogDetails model serialization & backwards compatibility', () {
    test('round-trips structured fields, feel, practicedSkills, and authorOnly', () {
      const details = RiderLogDetails(
        type: RiderLogType.training,
        title: 'Trail & Obstacles',
        horse: 'Atlas',
        horseId: 'atlas',
        authorOnly: true,
        feel: SessionFeel.breakthrough,
        highlights: 'Stepped calmly onto the bridge',
        focus: 'Keep shoulders square before halt',
        nextSteps: 'Add gate opening in-hand',
        videoUrl: 'https://vimeo.com/123456',
        practicedSkills: [
          PracticedSkillTag(
            skillId: 'rider_balanced_halt',
            skillName: 'Balanced Halt',
            level: 'introductory',
          ),
        ],
      );

      final parsed = RiderLogDetails.fromMap(details.toMap());
      expect(parsed, isNotNull);
      expect(parsed!.type, RiderLogType.training);
      expect(parsed.authorOnly, isTrue);
      expect(parsed.feel, SessionFeel.breakthrough);
      expect(parsed.highlights, 'Stepped calmly onto the bridge');
      expect(parsed.focus, 'Keep shoulders square before halt');
      expect(parsed.nextSteps, 'Add gate opening in-hand');
      expect(parsed.videoUrl, 'https://vimeo.com/123456');
      expect(parsed.practicedSkills, hasLength(1));
      expect(parsed.practicedSkills.single.skillId, 'rider_balanced_halt');
      expect(parsed.practicedSkills.single.levelLabel, 'Introductory');
    });

    test('legacy map without new fields parses cleanly with safe defaults', () {
      final legacy = RiderLogDetails.fromMap({
        'type': 'lesson',
        'horse': 'Valero',
        'focus': 'Rhythm',
      });
      expect(legacy, isNotNull);
      expect(legacy!.authorOnly, isFalse);
      expect(legacy.feel, isNull);
      expect(legacy.highlights, isNull);
      expect(legacy.videoUrl, isNull);
      expect(legacy.practicedSkills, isEmpty);
    });
  });

  testWidgets(
    'Private Reflections default to author-only even when a horse is selected, '
    'and only share when explicitly opted in',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 960);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      const email = 'rider@example.com';
      final horse = HorseProfile(
        id: 'atlas',
        name: 'Atlas',
        currentOwnerId: email,
      );
      final rider = RiderProfile(
        id: 'rider',
        email: email,
        name: 'Morgan',
        ownedHorses: [BaseListItem(id: 'atlas', name: 'Atlas')],
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          usersProfile: rider,
          horseProfile: horse,
          user: const User(
            id: 'rider',
            email: email,
            name: 'Morgan',
            isGuest: false,
          ),
        ),
      );

      final savedLocalEntries = <BaseListItem>[];
      when(
        () => harness.riders.saveRiderLogEntry(
          email: email,
          entry: any(named: 'entry'),
          isEdit: any(named: 'isEdit'),
        ),
      ).thenAnswer((invocation) async {
        final entry = invocation.namedArguments[#entry] as BaseListItem;
        savedLocalEntries.add(entry);
        final current = harness.cubit.state.usersProfile!;
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            usersProfile: current.copyWith(notes: [...?current.notes, entry]),
          ),
        );
      });

      final connRepo = _MockConnectionRepository();
      final sharedPayloads = <Map<String, Object?>>[];
      when(
        () => connRepo.watchJournal('rider'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => connRepo.history(any()),
      ).thenAnswer((_) async => const <BaseListItem>[]);
      when(() => connRepo.submit(any())).thenAnswer((invocation) async {
        sharedPayloads.add(
          invocation.positionalArguments.single as Map<String, Object?>,
        );
        return {'status': 'saved'};
      });

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RiderProfileRepository>.value(
              value: harness.riders,
            ),
            RepositoryProvider<HorseProfileRepository>.value(
              value: harness.horses,
            ),
            RepositoryProvider<ConnectionRepository>.value(value: connRepo),
          ],
          child: BlocProvider.value(
            value: harness.cubit,
            child: const MaterialApp(home: RiderLogbookPage(email: email)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Create a Reflection with horse Atlas selected WITHOUT toggling share switch
      await tester.tap(find.text('Add entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('logType-reflection')));
      await tester.pumpAndSettle();

      final horseDropdown = find.byKey(const ValueKey('logEntryHorse-self'));
      await tester.tap(horseDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atlas').last);
      await tester.pumpAndSettle();

      // Switch is visible and OFF by default
      final shareSwitch = tester.widget<SwitchListTile>(
        find.byKey(const Key('shareReflectionSwitch')),
      );
      expect(shareSwitch.value, isFalse);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notes'),
        'Personal mindset reflection after riding Atlas.',
      );
      await tester.tap(find.text('Save entry'));
      await tester.pumpAndSettle();

      // Saved locally as authorOnly, NOT sent to SharedRidingEntries
      expect(savedLocalEntries, hasLength(1));
      expect(savedLocalEntries.single.riderLog?.authorOnly, isTrue);
      expect(savedLocalEntries.single.riderLog?.horseId, 'atlas');
      expect(sharedPayloads, isEmpty);

      // Verify author-only reflection is visible in RiderLogbookPage...
      expect(
        find.text('Personal mindset reflection after riding Atlas.'),
        findsOneWidget,
      );

      // ...but NEVER leaks onto Horse Logbook (LogViewDialog)!
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ConnectionRepository>.value(value: connRepo),
          ],
          child: BlocProvider.value(
            value: harness.cubit,
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => LogViewDialog(
                  name: 'Atlas',
                  horseId: 'atlas',
                  horseProfile: horse,
                  notes: horse.notes,
                  isRider: false,
                  appContext: ctx,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Personal mindset reflection after riding Atlas.'),
        findsNothing,
      );

      // 2. Now create a Reflection WITH explicit opt-in sharing enabled
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RiderProfileRepository>.value(
              value: harness.riders,
            ),
            RepositoryProvider<HorseProfileRepository>.value(
              value: harness.horses,
            ),
            RepositoryProvider<ConnectionRepository>.value(value: connRepo),
          ],
          child: BlocProvider.value(
            value: harness.cubit,
            child: const MaterialApp(home: RiderLogbookPage(email: email)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add entry'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('logType-reflection')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('logEntryHorse-self')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atlas').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shareReflectionSwitch')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Notes'),
        'Shared reflection for team.',
      );
      await tester.tap(find.text('Save entry'));
      await tester.pumpAndSettle();

      expect(sharedPayloads, hasLength(1));
      expect(sharedPayloads.single['action'], 'saveJournal');
      expect(sharedPayloads.single['horseId'], 'atlas');
      expect(sharedPayloads.single['authorOnly'], isNull);
    },
  );

  testWidgets(
    'Composer surfaces previous session nextSteps for selected horse and '
    'persists structured takeaways, feel, and validated video URL',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(920, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      const email = 'rider@example.com';
      final rider = RiderProfile(
        id: 'rider',
        email: email,
        name: 'Morgan',
        ownedHorses: [
          BaseListItem(id: 'atlas', name: 'Atlas'),
          BaseListItem(id: 'sage', name: 'Sage'),
        ],
        notes: [
          BaseListItem(
            id: 'prev-atlas',
            name: 'Good bend to the left.',
            date: DateTime(2026, 11, 20),
            parentId: email,
            riderLog: const RiderLogDetails(
              type: RiderLogType.training,
              horseId: 'atlas',
              horse: 'Atlas',
              nextSteps: 'Start next ride with walk-halt transitions on loose rein',
            ),
          ),
          BaseListItem(
            id: 'prev-sage',
            name: 'Trail walk.',
            date: DateTime(2026, 10, 12),
            parentId: email,
            riderLog: const RiderLogDetails(
              type: RiderLogType.training,
              horseId: 'sage',
              horse: 'Sage',
            ),
          ),
        ],
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          usersProfile: rider,
          user: const User(
            id: 'rider',
            email: email,
            name: 'Morgan',
            isGuest: false,
          ),
        ),
      );

      final connRepo = _MockConnectionRepository();
      Map<String, Object?>? savedJournal;
      when(
        () => connRepo.watchJournal('rider'),
      ).thenAnswer((_) => Stream.value(const []));
      when(
        () => connRepo.history(any()),
      ).thenAnswer((_) async => const <BaseListItem>[]);
      when(() => connRepo.submit(any())).thenAnswer((inv) async {
        savedJournal = inv.positionalArguments.single as Map<String, Object?>;
        return {'status': 'saved'};
      });

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RiderProfileRepository>.value(
              value: harness.riders,
            ),
            RepositoryProvider<HorseProfileRepository>.value(
              value: harness.horses,
            ),
            RepositoryProvider<ConnectionRepository>.value(value: connRepo),
          ],
          child: BlocProvider.value(
            value: harness.cubit,
            child: const MaterialApp(home: RiderLogbookPage(email: email)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Up Next card, Month headers, and Horse filter bar render on RiderLogbookPage
      expect(find.byKey(const Key('logbookUpNextCard')), findsOneWidget);
      expect(
        find.text('Start next ride with walk-halt transitions on loose rein'),
        findsOneWidget,
      );
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(
        find.byKey(const Key('riderLogbookHorseFilterBar')),
        findsOneWidget,
      );

      // Filter by Sage hides Atlas's entry
      await tester.tap(find.byKey(const Key('horseFilter_id:sage')));
      await tester.pumpAndSettle();
      expect(find.text('Good bend to the left.'), findsNothing);
      expect(find.text('Trail walk.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('horseFilter_all')));
      await tester.pumpAndSettle();

      // Open composer and select Atlas -> previous session nextSteps banner appears!
      await tester.tap(find.text('Add entry'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('previousSessionNextStepsBanner')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('logEntryHorse-self')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atlas').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('previousSessionNextStepsBanner')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('previousSessionNextStepsBanner')),
          matching: find.text(
            'Start next ride with walk-halt transitions on loose rein',
          ),
        ),
        findsOneWidget,
      );

      // Select SessionFeel and expand structured takeaways (leaving Notes blank!)
      final feelChip = find.byKey(const Key('sessionFeel_steady'));
      await tester.ensureVisible(feelChip);
      await tester.tap(feelChip);
      await tester.pumpAndSettle();
      final toggleTakeaways = find.byKey(const Key('toggleTakeawaysSection'));
      await tester.ensureVisible(toggleTakeaways);
      await tester.tap(toggleTakeaways);
      await tester.pumpAndSettle();

      final highlightsField = find.byKey(const Key('logEntryHighlights'));
      await tester.ensureVisible(highlightsField);
      await tester.enterText(
        highlightsField,
        'Prompt downward transitions from seat cue',
      );
      final focusField = find.byKey(const Key('logEntryFocus'));
      await tester.ensureVisible(focusField);
      await tester.enterText(
        focusField,
        'Keep poll steady during halt',
      );
      final nextStepsField = find.byKey(const Key('logEntryNextSteps'));
      await tester.ensureVisible(nextStepsField);
      await tester.enterText(
        nextStepsField,
        'Introduce backing 3 steps after halt',
      );
      final videoField = find.byKey(const Key('logEntryVideoUrl'));
      await tester.ensureVisible(videoField);
      await tester.enterText(
        videoField,
        'not-a-valid-url',
      );

      final saveBtn = find.text('Save entry');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a valid http:// or https:// video link.'),
        findsOneWidget,
      );

      await tester.ensureVisible(videoField);
      await tester.enterText(
        videoField,
        'https://youtu.be/demo999',
      );
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(savedJournal, isNotNull);
      expect(savedJournal!['feel'], 'steady');
      expect(
        savedJournal!['highlights'],
        'Prompt downward transitions from seat cue',
      );
      expect(savedJournal!['focus'], 'Keep poll steady during halt');
      expect(
        savedJournal!['nextSteps'],
        'Introduce backing 3 steps after halt',
      );
      expect(savedJournal!['videoUrl'], 'https://youtu.be/demo999');
    },
  );

  testWidgets(
    'Log Practice from SkillDetailV2Panel pre-tags skill and respects '
    'explicit opt-in Mark as Learning without ever granting Proficient/Verified',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 960);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      const email = 'rider@example.com';
      final rider = RiderProfile(id: 'rider', email: email, name: 'Morgan');
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          isForRider: true,
          usersProfile: rider,
          user: const User(
            id: 'uid-morgan',
            email: email,
            name: 'Morgan',
            isGuest: false,
            emailVerified: true,
          ),
        ),
      );

      final store = InMemorySkillTreeV2Store(
        families: [_riderFamily(), _horseFamily()],
        skills: [_riderSkill(), _horseSkill()],
      );
      // Pre-mark Intermediate as Proficient so we also prove Proficient is NEVER downgraded!
      await store.setLevelProgress(
        subject: SkillSubject.rider,
        profileDocId: email,
        skillId: 'rider_balanced_halt',
        level: DifficultyState.Intermediate,
        state: LevelState.PROFICIENT,
        actorUid: 'uid-morgan',
        actorName: 'Morgan',
      );
      final skillRepo = SkillTreeV2Repository(store: store);

      when(
        () => harness.riders.saveRiderLogEntry(
          email: email,
          entry: any(named: 'entry'),
          isEdit: any(named: 'isEdit'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<RiderProfileRepository>.value(
              value: harness.riders,
            ),
            RepositoryProvider<SkillTreeV2Repository>.value(value: skillRepo),
          ],
          child: BlocProvider.value(
            value: harness.cubit,
            child: const MaterialApp(
              home: SkillTreeV2View(
                initialSkillId: 'rider_balanced_halt',
                initialLevel: DifficultyState.Introductory,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Tap Log Practice on Introductory (currently Not Started) -> WITHOUT checking Mark as Learning
      final logPracticeBtn = find.byKey(
        const Key('skillDetailV2LogPracticeButton'),
      );
      expect(logPracticeBtn, findsOneWidget);
      await tester.ensureVisible(logPracticeBtn);
      await tester.tap(logPracticeBtn);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('taggedSkillChip_rider_balanced_halt')),
        findsOneWidget,
      );
      final checkboxFinder = find.byKey(
        const Key('markPracticedAsLearningCheckbox'),
      );
      expect(checkboxFinder, findsOneWidget);
      expect(find.text('Mark this skill as Learning?'), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(checkboxFinder).value, isFalse);

      // Save WITHOUT checking the box -> progress remains Not Started!
      await tester.tap(find.text('Save entry'));
      await tester.pumpAndSettle();

      var progress = await skillRepo.fetchProgress(
        subject: SkillSubject.rider,
        profileDocId: email,
      );
      expect(
        progress['rider_balanced_halt']?.levels[DifficultyState.Introductory],
        isNull,
      );

      // 2. Tap Log Practice again and EXPLICITLY check Mark as Learning -> updates Introductory to Learning!
      await tester.ensureVisible(logPracticeBtn);
      await tester.tap(logPracticeBtn);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save entry'));
      await tester.pumpAndSettle();

      progress = await skillRepo.fetchProgress(
        subject: SkillSubject.rider,
        profileDocId: email,
      );
      expect(
        progress['rider_balanced_halt']
            ?.levels[DifficultyState.Introductory]
            ?.state,
        LevelState.LEARNING,
      );
      // Intermediate remains Proficient, and Verifications remain untouched!
      expect(
        progress['rider_balanced_halt']
            ?.levels[DifficultyState.Intermediate]
            ?.state,
        LevelState.PROFICIENT,
      );
      final verifications = await skillRepo.fetchVerifications(
        subject: SkillSubject.rider,
        profileDocId: email,
      );
      expect(verifications, isEmpty);

      // 3. Switch to Intermediate (already Proficient) and tap Log Practice -> checkbox does NOT offer to downgrade Proficient!
      await tester.tap(
        find.byKey(const Key('levelTab_rider_balanced_halt_Intermediate')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(logPracticeBtn);
      await tester.tap(logPracticeBtn);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('markPracticedAsLearningCheckbox')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Horse Logbook (LogViewDialog) displays structured takeaways, practiced '
    'skills, feel, and allows connected horse trainer to add entries',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(920, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      const trainerEmail = 'trainer@example.com';
      const ownerEmail = 'owner@example.com';

      final trainer = RiderProfile(
        id: 'trainer',
        email: trainerEmail,
        name: 'Coach Sam',
        isTrainer: true,
      );
      final horse = HorseProfile(
        id: 'atlas',
        name: 'Atlas',
        currentOwnerId: ownerEmail,
        ownershipVersion: 'v1',
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          usersProfile: trainer,
          horseProfile: horse,
          user: const User(
            id: 'trainer',
            email: trainerEmail,
            name: 'Coach Sam',
            isGuest: false,
          ),
        ),
      );

      final connRepo = _MockConnectionRepository();
      final connStream = StreamController<List<CoachingConnection>>.broadcast();
      addTearDown(connStream.close);
      when(() => connRepo.watch('trainer')).thenAnswer((_) => connStream.stream);
      when(
        () => connRepo.history({'action': 'horseHistory', 'horseId': 'atlas'}),
      ).thenAnswer(
        (_) async => [
          BaseListItem(
            id: 'shared-1',
            name: 'Calm ground manners around mounting block.',
            date: DateTime(2026, 11, 22),
            parentId: trainerEmail,
            message: 'Coach Sam',
            isSelected: true,
            riderLog: const RiderLogDetails(
              type: RiderLogType.training,
              title: 'Mounting Block Patience',
              authorRole: 'trainer',
              shared: true,
              feel: SessionFeel.breakthrough,
              highlights: 'Stood immobile for 30 seconds',
              focus: 'Weight evenly on all four feet',
              nextSteps: 'Step onto stirrup gently next session',
              practicedSkills: [
                PracticedSkillTag(
                  skillId: 'horse_calm_standing',
                  skillName: 'Calm Standing & Patience',
                  subject: 'horse',
                  level: 'introductory',
                ),
              ],
            ),
          ),
        ],
      );

      final connectionsCubit = ConnectionsCubit(connRepo, harness.cubit);
      addTearDown(connectionsCubit.close);

      await tester.pumpWidget(
        RepositoryProvider<ConnectionRepository>.value(
          value: connRepo,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: harness.cubit),
              BlocProvider.value(value: connectionsCubit),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (ctx) => LogViewDialog(
                  name: 'Atlas',
                  horseId: 'atlas',
                  horseProfile: horse,
                  notes: horse.notes,
                  isRider: false,
                  appContext: ctx,
                ),
              ),
            ),
          ),
        ),
      );
      connStream.add([
        CoachingConnection('horse-conn', {
          'kind': 'horse',
          'status': 'accepted',
          'version': 'v1',
          'ownershipVersion': 'v1',
          'horseId': 'atlas',
          'horseName': 'Atlas',
          'coach': trainerEmail,
          'coachName': 'Coach Sam',
          'learner': ownerEmail,
          'learnerName': 'Owner',
          'sender': ownerEmail,
          'recipient': trainerEmail,
        }),
      ]);
      await tester.pumpAndSettle();

      // Connected trainer sees Add entry button, Up Next card, and entry card
      expect(find.text('Add entry'), findsOneWidget);
      expect(find.byKey(const Key('logbookUpNextCard')), findsOneWidget);
      expect(
        find.text('Step onto stirrup gently next session'),
        findsOneWidget,
      );
      expect(find.text('Mounting Block Patience'), findsOneWidget);

      // Tap card -> unified detail dialog displays all structured fields + Edit/Delete for author
      await tester.tap(find.text('Mounting Block Patience'));
      await tester.pumpAndSettle();
      expect(find.text('Stood immobile for 30 seconds'), findsOneWidget);
      expect(find.text('Weight evenly on all four feet'), findsOneWidget);
      expect(find.text('Edit entry'), findsOneWidget);
      expect(find.text('Delete entry'), findsOneWidget);
    },
  );
}
