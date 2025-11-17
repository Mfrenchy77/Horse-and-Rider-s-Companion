import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/Utilities/skill_level_audit.dart';

Skill _skill(String id, {int position = 0}) {
  return Skill(
    id: id,
    rider: true,
    position: position,
    skillName: 'Skill $id',
    lastEditBy: 'tester',
    description: 'desc',
    lastEditDate: DateTime(2024),
    learningDescription: 'learn',
    proficientDescription: 'prof',
  );
}

SkillLevel _level(String id) {
  return SkillLevel(
    skillId: id,
    skillName: 'Skill $id',
    lastEditBy: 'tester',
    lastEditDate: DateTime(2024),
  );
}

void main() {
  group('SkillLevelAudit', () {
    test('marks catalog as not ready when no skills retrieved', () {
      final result = SkillLevelAudit.evaluate(
        profileSkillLevels: [_level('a')],
        allSkills: const [],
      );

      expect(result.isCatalogReady, isFalse);
      expect(result.validLevels, hasLength(1));
      expect(result.deprecatedLevels, isEmpty);
    });

    test('splits valid and deprecated skill levels once catalog is ready', () {
      final result = SkillLevelAudit.evaluate(
        profileSkillLevels: [_level('keep'), _level('remove')],
        allSkills: [_skill('keep')],
      );

      expect(result.isCatalogReady, isTrue);
      expect(result.validLevels.map((e) => e.skillId), ['keep']);
      expect(result.deprecatedLevels.map((e) => e.skillId), ['remove']);
    });
  });
}
