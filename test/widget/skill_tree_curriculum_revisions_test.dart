import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/curriculum_revision_dialogs.dart';

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
  });
}
