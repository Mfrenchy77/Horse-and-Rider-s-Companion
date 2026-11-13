import 'package:database_repository/src/models/models.dart';

/// Backend-neutral interface for skills and training path persistence.
abstract interface class SkillTreeStore {
  /// Creates or updates [trainingPath].
  Future<void> createOrEditTrainingPath({required TrainingPath trainingPath});

  /// Streams a single training path by [id].
  Stream<TrainingPath?> getTrainingPathById({required String id});

  /// Streams all training paths.
  Stream<List<TrainingPath>> getAllTrainingPaths();

  /// Deletes [trainingPath].
  void deleteTrainingPath({required TrainingPath? trainingPath});

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
