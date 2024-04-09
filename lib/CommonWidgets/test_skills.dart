// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';

class TestSkills {
  // Helper method to generate a list of skills for a given difficulty
  static List<Skill> _generateSkillsForDifficulty(
    DifficultyState difficulty,
    int count,
  ) {
    return List.generate(count, (index) {
      return Skill(
        id: 'skill_${difficulty.name}_$index',
        learningDescription:
            'Learning description for skill ${index + 1} (${difficulty.name})',
        proficientDescription:
            'Proficient description for skill ${index + 1} (${difficulty.name})',
        rider: index.isEven, // Just as an example, alternating true/false
        position: index,
        skillName: 'Skill ${index + 1} (${difficulty.name})',
        lastEditBy: 'editor_$index',
        description: 'Description for skill ${index + 1} (${difficulty.name})',
        lastEditDate: DateTime.now().subtract(Duration(days: index)),
        difficulty: difficulty,
      );
    });
  }

  /// Generates a list of skills for testing purposes
  static List<Skill> generateTestSkills() {
    final introductorySkills =
        _generateSkillsForDifficulty(DifficultyState.Introductory, 15);
    final intermediateSkills =
        _generateSkillsForDifficulty(DifficultyState.Intermediate, 15);
    final advancedSkills =
        _generateSkillsForDifficulty(DifficultyState.Advanced, 15);

    // Combine all the generated skills into one list
    return [...introductorySkills, ...intermediateSkills, ...advancedSkills];
  }
}
