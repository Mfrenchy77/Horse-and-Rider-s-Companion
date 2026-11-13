import 'package:database_repository/src/models/models.dart';

/// Backend-neutral interface for skills persistence.
abstract interface class SkillTreeStore {
  /// Creates or updates [skill].
  Future<void> createOrEditSkill({required Skill skill});

  /// Streams skills matching category [id].
  Stream<List<Skill>> getSkillsFromCategory({required String id});

  /// Streams all skills.
  Stream<List<Skill>> getSkills();

  /// Streams skills for the rider skill tree.
  Stream<List<Skill>> getSkillsForRiderSkillTree();

  /// Streams skills for the horse skill tree.
  Stream<List<Skill>> getSkillsForHorseSkillTree();

  /// Deletes [skill].
  void deleteSkill({required Skill? skill});
}
