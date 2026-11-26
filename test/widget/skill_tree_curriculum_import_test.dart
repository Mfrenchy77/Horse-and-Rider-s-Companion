// ignore_for_file: lines_longer_than_80_chars

import 'dart:convert';

import 'package:authentication_repository/authentication_repository.dart'
    show User;
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_export_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_import_dialog.dart';

import '../support/app_test_harness.dart';

void main() {
  late AppTestHarness harness;

  const baseFamily = SkillFamily(
    id: 'rider.mounted.balance',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    name: 'Mounted Balance',
    description: 'Core mounted rider balance.',
    sortOrder: 10,
  );

  const horseFamily = SkillFamily(
    id: 'horse.mounted.gaits',
    subject: SkillSubject.horse,
    realm: SkillCategory.Mounted,
    name: 'Mounted Gaits',
    description: 'Horse gait balance.',
    sortOrder: 10,
  );

  const horseTrot = CurriculumSkill(
    id: 'horse.mounted.trot',
    subject: SkillSubject.horse,
    realm: SkillCategory.Mounted,
    familyId: 'horse.mounted.gaits',
    name: 'Trot / Jog',
    summary: 'Two-beat diagonal gait.',
    purpose: 'Develops steady gait rhythm.',
    availableLevels: [DifficultyState.Introductory],
    levels: {
      DifficultyState.Introductory: SkillLevelDefinition(
        overview: 'Horse trot intro',
        learning: 'Horse trot learning',
        proficient: 'Horse trot proficient v1',
      ),
    },
    relatedSkills: [
      RelatedSkill(
        skillId: 'rider.mounted.trot',
        relation: SkillRelationType.counterpart,
      ),
    ],
    sortOrder: 10,
  );

  const riderTrotV1 = CurriculumSkill(
    id: 'rider.mounted.trot',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    familyId: 'rider.mounted.balance',
    name: 'Trot / Jog',
    summary: 'Rider balance in trot.',
    purpose: 'Follows diagonal footfalls safely.',
    availableLevels: [DifficultyState.Introductory],
    levels: {
      DifficultyState.Introductory: SkillLevelDefinition(
        overview: 'Rider trot intro',
        learning: 'Rider trot learning',
        proficient: 'Rider trot proficient v1',
      ),
    },
    relatedSkills: [
      RelatedSkill(
        skillId: 'horse.mounted.trot',
        relation: SkillRelationType.counterpart,
      ),
    ],
    legacyIds: ['legacy_rider_trot'],
    sortOrder: 10,
  );

  const riderCanterV1 = CurriculumSkill(
    id: 'rider.mounted.canter',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    familyId: 'rider.mounted.balance',
    name: 'Canter',
    summary: 'Three-beat canter.',
    purpose: 'Canter balance.',
    availableLevels: [DifficultyState.Introductory],
    levels: {
      DifficultyState.Introductory: SkillLevelDefinition(
        overview: 'Canter intro',
        learning: 'Canter learning',
        proficient: 'Canter proficient v1',
      ),
    },
    sortOrder: 20,
  );

  const adminUser = User(
    id: 'admin-1',
    name: 'Admin One',
    email: 'admin1@example.com',
    isGuest: false,
    emailVerified: true,
    isAdmin: true,
  );

  setUp(() async {
    SkillTreeV2View.resetPreviewStoreForTest();
    harness = await AppTestHarness.create();
  });

  tearDown(() => harness.close());

  Widget wrapSkillTree({
    required SkillTreeV2Repository v2Repo,
    required SkillTreeDraftRepository draftRepo,
    required SkillTreeSuggestionsRepository suggestionsRepo,
    bool enableCurriculumPublishing = false,
    CurriculumImportFilePicker? onPickCurriculumImportFile,
  }) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SkillTreeDraftRepository>.value(value: draftRepo),
        RepositoryProvider<SkillTreeSuggestionsRepository>.value(
          value: suggestionsRepo,
        ),
      ],
      child: BlocProvider<AppCubit>.value(
        value: harness.cubit,
        child: MaterialApp(
          home: SkillTreeV2View(
            repository: v2Repo,
            enableCurriculumPublishing: enableCurriculumPublishing,
            onPickCurriculumImportFile: onPickCurriculumImportFile,
          ),
        ),
      ),
    );
  }

  group('Skill Tree 2.0 Admin Curriculum JSON Import', () {
    testWidgets('non-admin users cannot access curriculum import controls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final v2Store = InMemorySkillTreeV2Store(
        families: const [baseFamily, horseFamily],
        skills: const [riderTrotV1, riderCanterV1, horseTrot],
      );
      final v2Repo = SkillTreeV2Repository(store: v2Store);
      final draftRepo = SkillTreeDraftRepository(
        store: InMemorySkillTreeDraftStore(actorIsAdmin: false),
      );
      final suggestionsRepo = SkillTreeSuggestionsRepository(
        store: InMemorySkillTreeSuggestionsStore(),
      );

      for (final isModerator in [true, false]) {
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: User(
              id: isModerator ? 'mod-1' : 'rider-1',
              name: isModerator ? 'Moderator' : 'Rider',
              email: isModerator ? 'mod@example.com' : 'rider@example.com',
              isGuest: false,
              emailVerified: true,
              isModerator: isModerator,
            ),
            isGuest: false,
            isForRider: true,
            usersProfile: RiderProfile(
              id: isModerator ? 'mod-1' : 'rider-1',
              name: isModerator ? 'Moderator' : 'Rider',
              email: isModerator ? 'mod@example.com' : 'rider@example.com',
            ),
          ),
        );

        await tester.pumpWidget(
          wrapSkillTree(
            v2Repo: v2Repo,
            draftRepo: draftRepo,
            suggestionsRepo: suggestionsRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('draftImportButton')), findsNothing);
      }
    });

    testWidgets(
      'admin validates malformed JSON, previews diff, can cancel cleanly, '
      'imports into draft, saves, publishes Revision 2, and supports rollback',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 960);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: adminUser,
            isGuest: false,
            isForRider: true,
            usersProfile: RiderProfile(
              id: 'admin-1',
              name: 'Admin One',
              email: 'admin1@example.com',
            ),
          ),
        );

        final rev1Snapshot = CurriculumRevisionSnapshot(
          summary: CurriculumRevisionSummary(
            id: 'rev_000001',
            revisionNumber: 1,
            kind: 'publish',
            status: 'completed',
            publishedByUid: 'admin-1',
            publishedByName: 'Admin One',
            notes: 'Baseline revision 1',
            checksum: 'rev1',
            chunkCount: 1,
            snapshotByteLength: 500,
            familyCount: 2,
            skillCount: 3,
            totalLevels: 3,
            publishedAt: DateTime.utc(2026, 11, 20),
          ),
          families: const [baseFamily, horseFamily],
          skills: const [riderTrotV1, riderCanterV1, horseTrot],
        );

        final v2Store = InMemorySkillTreeV2Store(
          families: const [baseFamily, horseFamily],
          skills: const [riderTrotV1, riderCanterV1, horseTrot],
        );
        final v2Repo = SkillTreeV2Repository(store: v2Store);
        final draftStore = InMemorySkillTreeDraftStore(
          actorName: 'Admin One',
          initialRevisions: [rev1Snapshot],
          publishingEnabled: true,
        );
        final draftRepo = SkillTreeDraftRepository(store: draftStore);
        final suggestionsRepo = SkillTreeSuggestionsRepository(
          store: InMemorySkillTreeSuggestionsStore(actorIsAdmin: true),
        );

        const importedFamily = SkillFamily(
          id: 'rider.mounted.balance',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          name: 'Mounted Balance',
          description: 'Updated mounted balance family description.',
          sortOrder: 10,
        );
        const newSkill = CurriculumSkill(
          id: 'rider.mounted.posting_diagonal',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          familyId: 'rider.mounted.balance',
          name: 'Posting Diagonal',
          summary: 'Recognizing and riding on the correct trot diagonal.',
          purpose: 'Balances hind leg engagement.',
          availableLevels: [DifficultyState.Introductory],
          levels: {
            DifficultyState.Introductory: SkillLevelDefinition(
              overview: 'Diagonal overview',
              learning: 'Diagonal learning',
              proficient: 'Diagonal proficient v1',
            ),
          },
          relatedSkills: [
            RelatedSkill(
              skillId: 'rider.mounted.trot',
              relation: SkillRelationType.foundation,
            ),
          ],
          sortOrder: 15,
        );
        const riderTrotV2 = CurriculumSkill(
          id: 'rider.mounted.trot',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          familyId: 'rider.mounted.balance',
          name: 'Trot / Jog',
          summary: 'Rider balance in two-beat diagonal trot or jog.',
          purpose: 'Follows diagonal footfalls safely.',
          availableLevels: [DifficultyState.Introductory],
          levels: {
            DifficultyState.Introductory: SkillLevelDefinition(
              overview: 'Rider trot intro',
              learning: 'Rider trot learning',
              proficient: 'Rider trot proficient v2',
              standardVersion: 2,
            ),
          },
          relatedSkills: [
            RelatedSkill(
              skillId: 'horse.mounted.trot',
              relation: SkillRelationType.counterpart,
            ),
          ],
          legacyIds: ['legacy_rider_trot'],
          sortOrder: 10,
        );
        const riderCanterRetired = CurriculumSkill(
          id: 'rider.mounted.canter',
          status: CurriculumSkillStatus.retired,
          replacedBy: 'rider.mounted.trot',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          familyId: 'rider.mounted.balance',
          name: 'Canter',
          summary: 'Three-beat canter.',
          purpose: 'Canter balance.',
          availableLevels: [DifficultyState.Introductory],
          levels: {
            DifficultyState.Introductory: SkillLevelDefinition(
              overview: 'Canter intro',
              learning: 'Canter learning',
              proficient: 'Canter proficient v1',
            ),
          },
          sortOrder: 20,
        );

        final canonicalImportJson = buildCanonicalCurriculumExportJson(
          families: [importedFamily, horseFamily],
          skills: const [riderTrotV2, newSkill, riderCanterRetired, horseTrot],
        );

        await tester.pumpWidget(
          wrapSkillTree(
            v2Repo: v2Repo,
            draftRepo: draftRepo,
            suggestionsRepo: suggestionsRepo,
            enableCurriculumPublishing: true,
            onPickCurriculumImportFile: () async => (
              name: 'skill_tree_v2_import.json',
              content: canonicalImportJson,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to the Mounted category and expand the fixture family.
        await tester.tap(find.text('Mounted'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mounted Balance'));
        await tester.pumpAndSettle();

        // Enter Admin Draft Mode.
        await tester.tap(
          find.byKey(const Key('skillTreeV2AppBarOverflowMenu')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('skillTreeV2MenuAdminEditDraft')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('draftImportButton')), findsOneWidget);

        // Open Import Curriculum dialog.
        await tester.tap(find.byKey(const Key('draftImportButton')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('curriculumImportDialog')), findsOneWidget);

        // 1. Malformed JSON shows validation errors and keeps Apply disabled.
        await tester.enterText(
          find.byKey(const Key('importCurriculumJsonField')),
          '{bad json',
        );
        await tester.tap(
          find.byKey(const Key('importCurriculumValidateButton')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('importCurriculumErrorsCard')),
          findsOneWidget,
        );
        expect(find.textContaining('Malformed JSON'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const Key('importCurriculumApplyButton')),
              )
              .onPressed,
          isNull,
        );

        // 2. Modified proficient standard without version increment fails validation.
        final badVersionMap =
            jsonDecode(canonicalImportJson) as Map<String, dynamic>;
        final badTrot =
            (badVersionMap['skills'] as List).firstWhere(
                  (s) => (s as Map)['id'] == 'rider.mounted.trot',
                )
                as Map<String, dynamic>;
        ((badTrot['levels'] as Map)['introductory'] as Map)['standardVersion'] =
            1;
        await tester.enterText(
          find.byKey(const Key('importCurriculumJsonField')),
          jsonEncode(badVersionMap),
        );
        await tester.tap(
          find.byKey(const Key('importCurriculumValidateButton')),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('increment standardVersion above v1'),
          findsOneWidget,
        );

        // 3. Upload valid canonical file -> previews added/modified/retired & families.
        await tester.tap(
          find.byKey(const Key('importCurriculumUploadFileButton')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('importSelectedFileChip')), findsOneWidget);
        expect(
          find.byKey(const Key('importCurriculumDiffPreview')),
          findsOneWidget,
        );
        expect(find.text('Added: 1'), findsOneWidget);
        expect(find.text('Modified: 2'), findsOneWidget);
        expect(find.text('Retired: 1'), findsOneWidget);
        expect(find.text('Family changes: 1'), findsOneWidget);
        expect(
          find.textContaining(
            'Posting Diagonal (rider.mounted.posting_diagonal)',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('v1 → v2'), findsOneWidget);

        // 4. Cancel leaves current draft untouched.
        await tester.tap(find.byKey(const Key('importCurriculumCancelButton')));
        await tester.pumpAndSettle();
        expect(find.text('Posting Diagonal'), findsNothing);
        expect(
          find.text('Admin Draft Mode · Previewing draft'),
          findsOneWidget,
        );

        // 5. Re-open, upload, and apply into draft (does not auto-publish).
        await tester.tap(find.byKey(const Key('draftImportButton')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('importCurriculumUploadFileButton')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('importCurriculumApplyButton')));
        await tester.pumpAndSettle();

        expect(find.text('Posting Diagonal'), findsWidgets);
        expect(
          find.text('Admin Draft Mode · Unsaved draft changes'),
          findsOneWidget,
        );
        expect(await draftRepo.fetchRevisions(), hasLength(1));

        // 6. Save Draft, Preview Changes, and Publish Revision 2.
        await tester.tap(find.byKey(const Key('draftSaveButton')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('draftPreviewButton')));
        await tester.pumpAndSettle();
        expect(find.text('Added Skills (1)'), findsOneWidget);
        expect(find.text('Modified Skills (2)'), findsOneWidget);
        expect(find.text('Retired Skills (1)'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, 'Close'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('draftPublishButton')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('publishNotesField')),
          'Revision 2: Trot, Posting Diagonal, and Canter refinement',
        );
        await tester.tap(
          find.byKey(const Key('confirmPublishCurriculumButton')),
        );
        await tester.pumpAndSettle();

        final revisionsAfterPublish = await draftRepo.fetchRevisions();
        expect(revisionsAfterPublish.map((r) => r.revisionNumber), [2, 1]);
        expect(revisionsAfterPublish.first.skillCount, 4);

        // 7. Existing Revision History rollback to Revision 1 remains compatible.
        await tester.tap(
          find.byKey(const Key('skillTreeV2AppBarOverflowMenu')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const Key('skillTreeV2MenuAdminEditDraft')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('draftRevisionHistoryButton')));
        await tester.pumpAndSettle();
        final restoreBtn = find.byKey(
          const Key('restoreRevisionButton_rev_000001'),
        );
        await tester.ensureVisible(restoreBtn);
        await tester.tap(restoreBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirmRestoreRevisionButton')));
        await tester.pumpAndSettle();

        final revisionsAfterRollback = await draftRepo.fetchRevisions();
        expect(revisionsAfterRollback.map((r) => r.revisionNumber), [3, 2, 1]);
        expect(revisionsAfterRollback.first.isRollback, isTrue);
        expect(revisionsAfterRollback.first.rollbackOfRevisionId, 'rev_000001');
      },
    );
  });
}
