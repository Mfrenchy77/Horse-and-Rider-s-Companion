import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const family = SkillFamily(
    id: 'rider.mounted.balance',
    subject: SkillSubject.rider,
    realm: SkillCategory.Mounted,
    name: 'Mounted Balance',
    description: 'Balance in the saddle.',
    sortOrder: 10,
  );

  CurriculumSkill buildSkill({
    CurriculumSkillStatus status = CurriculumSkillStatus.active,
    String summary = 'Maintains a neutral pelvis.',
    String proficient = 'Maintains alignment through transitions.',
    int standardVersion = 1,
    String? replacedBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? standardUpdatedAt,
  }) {
    return CurriculumSkill(
      id: 'rider.mounted.neutral_pelvis',
      status: status,
      subject: SkillSubject.rider,
      realm: SkillCategory.Mounted,
      familyId: family.id,
      name: 'Neutral Pelvis',
      aliases: const ['Balanced Seat'],
      summary: summary,
      purpose: 'Supports independent seat and leg aids.',
      safety: const ['Check girth before mounting.'],
      availableLevels: const [DifficultyState.Introductory],
      levels: {
        DifficultyState.Introductory: SkillLevelDefinition(
          overview: 'Overview.',
          learning: 'Learning.',
          proficient: proficient,
          standardVersion: standardVersion,
          standardUpdatedAt: standardUpdatedAt,
        ),
      },
      legacyIds: const ['legacy_seat_1'],
      sortOrder: 10,
      replacedBy: replacedBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  group('CurriculumDraftDiff', () {
    test(
      'ignores updatedAt, updatedBy, and standardUpdatedAt metadata changes',
      () {
        final pub = buildSkill(
          updatedAt: DateTime.utc(2026, 11),
          updatedBy: 'cli-publish',
          standardUpdatedAt: DateTime.utc(2026, 11),
        );
        final draft = buildSkill(
          updatedAt: DateTime.utc(2026, 11, 23),
          updatedBy: 'admin-ui',
          standardUpdatedAt: DateTime.utc(2026, 11, 23),
        );

        final diff = CurriculumDraftDiff.compute(
          publishedFamilies: const [family],
          publishedSkills: [pub],
          draftFamilies: const [family],
          draftSkills: [draft],
        );

        expect(diff.hasChanges, isFalse);
        expect(diff.modifiedSkills, isEmpty);
      },
    );

    test(
      'reports added, modified, retired, and removed entries with details',
      () {
        final pubSkill = buildSkill();
        final editedSkill = buildSkill(
          status: CurriculumSkillStatus.retired,
          replacedBy: 'rider.mounted.replacement',
          proficient: 'Updated proficient criteria.',
          standardVersion: 2,
        );
        const addedSkill = CurriculumSkill(
          id: 'rider.mounted.replacement',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          familyId: 'rider.mounted.balance',
          name: 'Replacement',
          summary: 'Summary.',
          purpose: 'Purpose.',
          availableLevels: [DifficultyState.Introductory],
          levels: {
            DifficultyState.Introductory: SkillLevelDefinition(
              overview: 'O',
              learning: 'L',
              proficient: 'P',
            ),
          },
        );
        const editedFamily = SkillFamily(
          id: 'rider.mounted.balance',
          subject: SkillSubject.rider,
          realm: SkillCategory.Mounted,
          name: 'Mounted Balance & Posture',
          description: 'Balance in the saddle.',
          sortOrder: 10,
        );

        final diff = CurriculumDraftDiff.compute(
          publishedFamilies: const [family],
          publishedSkills: [pubSkill],
          draftFamilies: const [editedFamily],
          draftSkills: [editedSkill, addedSkill],
        );

        expect(diff.hasChanges, isTrue);
        expect(diff.modifiedFamilies.single.changedFields, ['name']);
        expect(
          diff.addedSkills.map((s) => s.id),
          ['rider.mounted.replacement'],
        );
        expect(
          diff.retiredSkills.map((s) => s.id),
          ['rider.mounted.neutral_pelvis'],
        );
        expect(
          diff.modifiedSkills.single.changedFields,
          containsAll([
            'status',
            'replacedBy',
            'Introductory standard (v1 → v2)',
          ]),
        );
        expect(
          diff.modifiedSkills.single.standardVersionChanges.single.nextVersion,
          2,
        );
      },
    );

    test(
      'learningGuide edits do not trigger standardVersionChanges',
      () {
        final pubSkill = buildSkill();
        final guidedDraft = pubSkill.copyWith(
          learningGuide: const SkillLearningGuide(
            exercises: [
              SkillPracticeExercise(
                badge: 'Foundation Exercise',
                title: 'Walk Pause Feel',
                summary: 'Practice calm halts and instant softening.',
              ),
            ],
            trainerInsight: 'Soft timing precedes heavier aids.',
          ),
        );

        final diff = CurriculumDraftDiff.compute(
          publishedFamilies: [family],
          publishedSkills: [pubSkill],
          draftFamilies: [family],
          draftSkills: [guidedDraft],
        );
        expect(diff.hasChanges, isTrue);
        expect(diff.modifiedSkills, hasLength(1));
        expect(diff.modifiedSkills.single.changedFields, ['learningGuide']);
        expect(diff.modifiedSkills.single.standardVersionChanges, isEmpty);
      },
    );
  });
}
