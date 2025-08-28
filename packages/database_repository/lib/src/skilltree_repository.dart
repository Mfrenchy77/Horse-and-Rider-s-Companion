// ignore_for_file: constant_identifier_names, lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

/// Repository for Accessing Elements of the SkillTree
class SkillTreeRepository {
/* ****
                  ****   TrainingPaths   ****

**** */

  /// Constant for Accessing the Training Paths in the Database
  static const String TRAINING_PATHS = 'TrainingPaths';

  final _trainingPathDatabaseReference = FirebaseFirestore.instance
      .collection(TRAINING_PATHS)
      .withConverter<TrainingPath>(
        fromFirestore: (snap, options) => TrainingPath.fromFirestore(snap),
        toFirestore: (tp, options) => tp.toFirestore(),
      );

  /// Create or update a TrainingPath
  Future<void> createOrEditTrainingPath({required TrainingPath trainingPath}) {
    return _trainingPathDatabaseReference
        .doc(trainingPath.id)
        .set(trainingPath);
  }

  /// Retrieve a TrainingPath by its ID
  Stream<TrainingPath?> getTrainingPathById({required String id}) {
    return _trainingPathDatabaseReference
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Retrieve all TrainingPaths
  Stream<List<TrainingPath>> getAllTrainingPaths() {
    return _trainingPathDatabaseReference
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Delete a TrainingPath
  void deleteTrainingPath({required TrainingPath? trainingPath}) {
    _trainingPathDatabaseReference.doc(trainingPath?.id).delete();
  }

/* ****
                  ****   Skills   ****

**** */

  /// Constant for Accessing the Skills on the Skill Tree
  static const String SKILLS = 'Skills';

  final _skillDatabaseReference =
      FirebaseFirestore.instance.collection(SKILLS).withConverter<Skill>(
            fromFirestore: Skill.fromFirestore,
            toFirestore: (Skill skill, options) => skill.toFirestore(),
          );

  /// create or update [skill]
  Future<void> createOrEditSkill({required Skill skill}) {
    return _skillDatabaseReference.doc(skill.id).set(skill);
  }

  /// Retreive Skill from Category [id]
  Stream<List<Skill>> getSkillsFromCategory({required String id}) {
    return _skillDatabaseReference
        .where('categoryId', isEqualTo: id)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Retreive all Skills
  Stream<List<Skill>> getSkills() {
    return _skillDatabaseReference
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///  Retreives all Skills for Rider SKill Tree
  Stream<List<Skill>> getSkillsForRiderSkillTree() {
    return _skillDatabaseReference
        .where('rider', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///  Retreives all Skills for Horse SKill Tree
  Stream<List<Skill>> getSkillsForHorseSkillTree() {
    return _skillDatabaseReference
        .where('rider', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// delete Skill
  void deleteSkill({required Skill? skill}) {
    _skillDatabaseReference.doc(skill?.id).delete();
  }
}
