import 'package:authentication_repository/authentication_repository.dart'
    show User;
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/ability_summary_v2_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_detail_v2_panel.dart';

import '../support/app_test_harness.dart';

void main() {
  const family = SkillFamily(
    id: 'rider.mounted.balance',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    name: 'Mounted Balance',
    description: 'Balance and position under saddle.',
    sortOrder: 10,
  );

  const activeReplacementSkill = CurriculumSkill(
    id: 'rider.mounted.balanced_seat',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    familyId: 'rider.mounted.balance',
    name: 'Balanced Seat',
    summary: 'Maintains balanced alignment across gaits.',
    purpose: 'Foundation for independent aids.',
    availableLevels: [DifficultyState.Introductory],
    levels: {
      DifficultyState.Introductory: SkillLevelDefinition(
        overview: 'Intro overview',
        learning: 'Intro learning',
        proficient: 'Revised proficient criteria',
        standardVersion: 2,
      ),
    },
    legacyIds: ['rider.mounted.legacy_pelvis'],
    sortOrder: 10,
  );

  const retiredSkill = CurriculumSkill(
    id: 'rider.mounted.legacy_pelvis',
    status: CurriculumSkillStatus.retired,
    replacedBy: 'rider.mounted.balanced_seat',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    familyId: 'rider.mounted.balance',
    name: 'Old Neutral Pelvis',
    summary: 'Legacy pelvis skill replaced by Balanced Seat.',
    purpose: 'Historical skill.',
    availableLevels: [DifficultyState.Introductory],
    levels: {
      DifficultyState.Introductory: SkillLevelDefinition(
        overview: 'Old intro overview',
        learning: 'Old intro learning',
        proficient: 'Old intro proficient',
      ),
    },
    sortOrder: 20,
  );

  group('Skill Tree 2.0 Progress & Retired Skill Preservation', () {
    test(
      'computeAbilitySummary and buildProfileSkillsDashboard preserve '
      'retired skill progress',
      () {
        const progress = {
          'rider.mounted.legacy_pelvis': SkillProgressRecord(
            skillId: 'rider.mounted.legacy_pelvis',
            subject: SkillSubject.rider,
            levels: {
              DifficultyState.Introductory: LevelProgress(
                state: LevelState.PROFICIENT,
              ),
            },
          ),
        };
        const verifications = {
          'rider.mounted.legacy_pelvis': SkillVerificationRecord(
            skillId: 'rider.mounted.legacy_pelvis',
            levels: {
              DifficultyState.Introductory: LevelVerification(
                verifiedByName: 'Coach Test',
              ),
            },
          ),
        };

        final summary = computeAbilitySummary(
          subject: SkillSubject.rider,
          skills: const [activeReplacementSkill, retiredSkill],
          progressBySkillId: progress,
          verificationsBySkillId: verifications,
        );

        // Active counts stay clean while earned achievements remain intact.
        expect(summary.totalSkills, 1);
        expect(summary.totalLevels, 1);
        expect(summary.proficientLevels, 1);
        expect(summary.verifiedLevels, 1);

        final dashboard = buildProfileSkillsDashboard(
          subject: SkillSubject.rider,
          allSkills: const [activeReplacementSkill, retiredSkill],
          progressBySkill: progress,
          verificationsBySkill: verifications,
        );
        expect(dashboard.proficientSkillCount, 1);
        expect(dashboard.verifiedSkillCount, 1);
        expect(
          dashboard.proficientEntries.single.skill.id,
          'rider.mounted.legacy_pelvis',
        );
      },
    );

    testWidgets(
      'retired skill is hidden from active browse, shown with Retired badge '
      'in My Skills, opens read-only with replacement link, and keeps version '
      'verification note',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SkillTreeV2View.resetPreviewStoreForTest();
        final harness = await AppTestHarness.create();
        addTearDown(harness.close);

        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: const User(
              id: 'rider-1',
              name: 'Rider One',
              email: 'rider1@example.com',
              isGuest: false,
              emailVerified: true,
            ),
            isGuest: false,
            isForRider: true,
            usersProfile: RiderProfile(
              id: 'rider-1',
              name: 'Rider One',
              email: 'rider1@example.com',
            ),
          ),
        );

        final v2Store = InMemorySkillTreeV2Store(
          families: const [family],
          skills: const [activeReplacementSkill, retiredSkill],
          initialProgress: {
            'rider:rider1@example.com': {
              'rider.mounted.legacy_pelvis': const SkillProgressRecord(
                skillId: 'rider.mounted.legacy_pelvis',
                subject: SkillSubject.rider,
                levels: {
                  DifficultyState.Introductory: LevelProgress(
                    state: LevelState.PROFICIENT,
                  ),
                },
              ),
            },
          },
          initialVerifications: {
            'rider:rider1@example.com': {
              'rider.mounted.legacy_pelvis': const SkillVerificationRecord(
                skillId: 'rider.mounted.legacy_pelvis',
                levels: {
                  DifficultyState.Introductory: LevelVerification(
                    verifiedByName: 'Coach Alex',
                  ),
                },
              ),
              'rider.mounted.balanced_seat': const SkillVerificationRecord(
                skillId: 'rider.mounted.balanced_seat',
                levels: {
                  DifficultyState.Introductory: LevelVerification(
                    verifiedByName: 'Coach Alex',
                  ),
                },
              ),
            },
          },
        );
        final v2Repo = SkillTreeV2Repository(store: v2Store);

        await tester.pumpWidget(
          BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(home: SkillTreeV2View(repository: v2Repo)),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Mounted category, where the test family lives.
        await tester.tap(find.text('Mounted'));
        await tester.pumpAndSettle();

        // Active browse shows Balanced Seat but hides Old Neutral Pelvis.
        await tester.tap(
          find.byKey(const Key('skillFamilyHeader_rider.mounted.balance')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Balanced Seat'), findsWidgets);
        expect(find.text('Old Neutral Pelvis'), findsNothing);

        // Balanced Seat verified at v1 with current v2 shows version note.
        expect(
          find.byKey(const Key('verificationEarlierStandardNote')),
          findsOneWidget,
        );

        // In My Skills, the retired skill appears with a Retired badge.
        await tester.tap(find.text('My Skills'));
        await tester.pumpAndSettle();
        expect(find.byType(AbilitySummaryV2View), findsOneWidget);
        expect(
          find.byKey(const Key('retiredBadge_rider.mounted.legacy_pelvis')),
          findsOneWidget,
        );

        // Tapping opens read-only SkillDetailV2Panel with replacement link.
        await tester.tap(
          find.byKey(const Key('mySkillCard_rider.mounted.legacy_pelvis')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SkillDetailV2Panel), findsOneWidget);
        expect(find.byKey(const Key('retiredSkillBanner')), findsOneWidget);

        final learningChip = tester.widget<ChoiceChip>(
          find.byKey(
            const Key(
              'assessLearning_rider.mounted.legacy_pelvis_Introductory',
            ),
          ),
        );
        expect(learningChip.onSelected, isNull);

        await tester.tap(
          find.byKey(const Key('retiredSkillReplacementButton')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('skillDetailV2_rider.mounted.balanced_seat')),
          findsOneWidget,
        );
      },
    );
  });
}
