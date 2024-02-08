import 'package:database_repository/database_repository.dart';

/// This will provide and example skill and skill level for guests.
/// it has a method that returs 2 skills. and a method that returns 2
/// skill levels relevatnt to those skills,
class ExampleSkill {
  /// This method returns a list of 2 skills.
  List<Skill> getSkills() {
    final skill1 = Skill(
      id: 'skill1',
      skillName: 'Example Skill 1',
      description: 'Skill 1 Description',
      lastEditBy: 'Example User',
      lastEditDate: DateTime.now(),
      learningDescription: 'Skill 1 Learning Description',
      proficientDescription: 'Skill 1 Proficient Description',
      position: 1,
      rider: true,
    );
    final skill2 = Skill(
      id: 'skill2',
      skillName: 'Example Skill 2',
      position: 2,
      description: 'Skill 2 Description',
      lastEditBy: 'Example User',
      lastEditDate: DateTime.now(),
      learningDescription: 'Skill 2 Learning Description',
      proficientDescription: 'Skill 2 Proficient Description',
      rider: true,
    );

    return [skill1, skill2];
  }

  /// This method returns a list of 2 skill levels.
  List<SkillLevel> getSkillLevels() {
    final skillLevel1 = SkillLevel(
      skillName: 'Example Skill 1',
      skillId: 'skill1',
      lastEditBy: 'Example User',
      lastEditDate: DateTime.now(),
      levelState: LevelState.PROFICIENT,
    );
    final skillLevel2 = SkillLevel(
      skillName: 'Example Skill 2',
      skillId: 'skill2',
      verified: true,
      lastEditBy: 'Example User',
      lastEditDate: DateTime.now(),
      levelState: LevelState.LEARNING,
    );
    return [skillLevel1, skillLevel2];
  }
}
