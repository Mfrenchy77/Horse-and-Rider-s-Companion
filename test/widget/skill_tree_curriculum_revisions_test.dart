import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Administration/administration_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_revision_dialogs.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppCubit extends MockCubit<AppState> implements AppCubit {}

void main() {
  const family = SkillFamily(
    id: 'rider.mounted.balance',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    name: 'Mounted Balance',
    description: 'Core rider balance.',
    sortOrder: 10,
  );

  const skillV1 = CurriculumSkill(
    id: 'rider.mounted.neutral_pelvis',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    familyId: 'rider.mounted.balance',
    name: 'Neutral Pelvis',
    summary: 'Original summary.',
    purpose: 'Purpose.',
    availableLevels: [DifficultyState.Introductory],
    levels: {
      DifficultyState.Introductory: SkillLevelDefinition(
        overview: 'Overview',
        learning: 'Learning',
        proficient: 'Proficient v1',
      ),
    },
    sortOrder: 10,
  );

  const skillV2 = CurriculumSkill(
    id: 'rider.mounted.neutral_pelvis',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    familyId: 'rider.mounted.balance',
    name: 'Neutral Pelvis',
    summary: 'Updated summary.',
    purpose: 'Purpose.',
    availableLevels: [DifficultyState.Introductory],
    levels: {
      DifficultyState.Introductory: SkillLevelDefinition(
        overview: 'Overview',
        learning: 'Learning',
        proficient: 'Proficient v2',
        standardVersion: 2,
      ),
    },
    sortOrder: 10,
  );

  group('Phase 2B Curriculum Publishing & Revision History Dialogs', () {
    testWidgets(
      'CurriculumPublishDialog stays disabled when publishingEnabled is false '
      'and publishes with notes when enabled',
      (tester) async {
        String? capturedNotes;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurriculumPublishDialog(
                publishedFamilies: const [family],
                publishedSkills: const [skillV1],
                draftFamilies: const [family],
                draftSkills: const [skillV2],
                onPublish: (notes) async {
                  capturedNotes = notes;
                  return const CurriculumRevisionSummary(
                    id: 'rev_000001',
                    revisionNumber: 1,
                    kind: 'publish',
                    status: 'completed',
                    publishedByUid: 'admin-1',
                    publishedByName: 'Admin',
                    checksum: 'abc',
                    chunkCount: 1,
                    snapshotByteLength: 100,
                    familyCount: 1,
                    skillCount: 1,
                    totalLevels: 1,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('publishDisabledNotice')), findsOneWidget);
        final disabledBtn = tester.widget<FilledButton>(
          find.byKey(const Key('confirmPublishCurriculumButton')),
        );
        expect(disabledBtn.onPressed, isNull);
        expect(capturedNotes, isNull);

        // Now render with publishingEnabled: true.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurriculumPublishDialog(
                publishedFamilies: const [family],
                publishedSkills: const [skillV1],
                draftFamilies: const [family],
                draftSkills: const [skillV2],
                publishingEnabled: true,
                onPublish: (notes) async {
                  capturedNotes = notes;
                  return const CurriculumRevisionSummary(
                    id: 'rev_000001',
                    revisionNumber: 1,
                    kind: 'publish',
                    status: 'completed',
                    publishedByUid: 'admin-1',
                    publishedByName: 'Admin',
                    checksum: 'abc',
                    chunkCount: 1,
                    snapshotByteLength: 100,
                    familyCount: 1,
                    skillCount: 1,
                    totalLevels: 1,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('publishNotesField')),
          'Updated neutral pelvis standard',
        );
        await tester.tap(
          find.byKey(const Key('confirmPublishCurriculumButton')),
        );
        await tester.pumpAndSettle();

        expect(capturedNotes, 'Updated neutral pelvis standard');
      },
    );

    testWidgets(
      'CurriculumRevisionHistoryDialog compares revisions and restores as '
      'a new forward revision when enabled',
      (tester) async {
        final rev1 = CurriculumRevisionSnapshot(
          summary: CurriculumRevisionSummary(
            id: 'rev_000001',
            revisionNumber: 1,
            kind: 'publish',
            status: 'completed',
            publishedByUid: 'admin-1',
            publishedByName: 'Admin One',
            notes: 'Baseline release',
            checksum: 'chk-1',
            chunkCount: 1,
            snapshotByteLength: 500,
            familyCount: 1,
            skillCount: 1,
            totalLevels: 1,
            publishedAt: DateTime.utc(2026, 11, 20),
          ),
          families: const [family],
          skills: const [skillV1],
        );

        final store = InMemorySkillTreeDraftStore(
          initialRevisions: [rev1],
          publishingEnabled: true,
        );
        final repo = SkillTreeDraftRepository(store: store);
        CurriculumRevisionSummary? restoredSummary;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurriculumRevisionHistoryDialog(
                draftRepository: repo,
                currentFamilies: const [family],
                currentSkills: const [skillV2],
                publishingEnabled: true,
                onRestored: (rev) => restoredSummary = rev,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('revisionCard_rev_000001')),
          findsOneWidget,
        );

        // Compare Revision #1 vs Current Live.
        await tester.tap(find.byKey(const Key('compareRevisionsButton')));
        await tester.pumpAndSettle();
        expect(find.textContaining('Updated Neutral Pelvis'), findsOneWidget);

        // Restore Revision #1 as a new forward revision (#2).
        final restoreBtn = find.byKey(
          const Key('restoreRevisionButton_rev_000001'),
        );
        await tester.ensureVisible(restoreBtn);
        await tester.tap(restoreBtn);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('restoreNotesField')),
          'Restoring v1 wording',
        );
        await tester.tap(
          find.byKey(const Key('confirmRestoreRevisionButton')),
        );
        await tester.pumpAndSettle();

        expect(restoredSummary, isNotNull);
        expect(restoredSummary!.revisionNumber, 2);
        expect(restoredSummary!.isRollback, isTrue);
        expect(restoredSummary!.rollbackOfRevisionId, 'rev_000001');
        expect(
          find.byKey(const Key('revisionCard_rev_000002')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CurriculumPublicationRecoveryBanner shows Discard only for unpublished '
      'interruptions and hides it when already active (mobile & desktop)',
      (tester) async {
        var resumed = false;
        var discarded = false;

        // 1. Mobile viewport (390x844), interrupted during staging.
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final stagingFailed = CurriculumPublicationStatus(
          publicationState: 'failed',
          activePublicationId: 'rev_000002',
          currentRevisionId: 'rev_000001',
          currentRevisionNumber: 1,
          failedStage: 'staging',
          lockOwnerName: 'Admin One',
          lastError: 'Temporary network interruption',
          updatedAt: DateTime.utc(2026, 11, 24, 18),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurriculumPublicationRecoveryBanner(
                status: stagingFailed,
                publishingEnabled: true,
                onResume: () => resumed = true,
                onDiscard: () => discarded = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Publication needs attention'), findsOneWidget);
        expect(
          find.byKey(const Key('recoveryResumePublicationButton')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('recoveryDiscardPublicationButton')),
          findsOneWidget,
        );

        // View Details dialog opens cleanly with rider-friendly copy.
        await tester.tap(find.byKey(const Key('recoveryViewDetailsButton')));
        await tester.pumpAndSettle();
        expect(find.text('Publication Recovery Details'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('recoveryResumePublicationButton')),
        );
        await tester.tap(
          find.byKey(const Key('recoveryDiscardPublicationButton')),
        );
        expect(resumed, isTrue);
        expect(discarded, isTrue);

        // 2. Desktop viewport (1280x900), syncing_legacy (already active).
        tester.view.physicalSize = const Size(1280, 900);
        const legacySyncFailed = CurriculumPublicationStatus(
          publicationState: 'failed',
          activePublicationId: 'rev_000002',
          currentRevisionId: 'rev_000002',
          currentRevisionNumber: 2,
          failedStage: 'syncing_legacy',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurriculumPublicationRecoveryBanner(
                status: legacySyncFailed,
                publishingEnabled: true,
                onResume: () {},
                onDiscard: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('recoveryResumePublicationButton')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('recoveryDiscardPublicationButton')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AdministrationPage passes live curriculum to Revision History and '
      'displays recovery banner when publication needs attention',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockAppCubit = _MockAppCubit();
        final adminState = const AppState.authenticated(
          User(
            id: 'admin-1',
            email: 'admin@example.com',
            name: 'Admin One',
            isGuest: false,
            emailVerified: true,
            isAdmin: true,
          ),
        ).copyWith(isGuest: false);
        when(() => mockAppCubit.state).thenReturn(adminState);
        whenListen(mockAppCubit, Stream<AppState>.value(adminState));

        final rev1 = CurriculumRevisionSnapshot(
          summary: CurriculumRevisionSummary(
            id: 'rev_000001',
            revisionNumber: 1,
            kind: 'publish',
            status: 'completed',
            publishedByUid: 'admin-1',
            publishedByName: 'Admin One',
            checksum: 'chk-1',
            chunkCount: 1,
            snapshotByteLength: 500,
            familyCount: 1,
            skillCount: 1,
            totalLevels: 1,
            publishedAt: DateTime.utc(2026, 11, 20),
          ),
          families: const [family],
          skills: const [skillV1],
        );

        final draftRepo = SkillTreeDraftRepository(
          store: InMemorySkillTreeDraftStore(
            initialRevisions: [rev1],
            initialPublicationStatus: const CurriculumPublicationStatus(
              publicationState: 'failed',
              activePublicationId: 'rev_000002',
              currentRevisionId: 'rev_000001',
              currentRevisionNumber: 1,
              failedStage: 'staging',
            ),
            publishingEnabled: true,
          ),
        );
        final liveSkillTreeRepo = SkillTreeV2Repository(
          store: InMemorySkillTreeV2Store(
            families: const [family],
            skills: const [skillV2],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AppCubit>.value(
              value: mockAppCubit,
              child: AdministrationPage(
                repository: SkillTreeSuggestionsRepository(
                  store: InMemorySkillTreeSuggestionsStore(),
                ),
                draftRepository: draftRepo,
                skillTreeRepository: liveSkillTreeRepo,
                enableCurriculumPublishing: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Recovery banner appears directly on AdministrationPage.
        expect(
          find.byKey(const Key('curriculumPublicationRecoveryBanner')),
          findsOneWidget,
        );

        // Open Revision History from AdministrationPage and compare live.
        await tester.tap(find.byKey(const Key('adminRevisionHistoryButton')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('compareRevisionsButton')));
        await tester.pumpAndSettle();

        // Proves live curriculum (skillV2) was passed instead of empty lists!
        expect(find.textContaining('Updated Neutral Pelvis'), findsOneWidget);
      },
    );
  });
}
