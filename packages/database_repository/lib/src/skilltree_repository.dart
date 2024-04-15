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
        fromFirestore: TrainingPath.fromFirestore,
        toFirestore: (TrainingPath trainingPath, options) =>
            trainingPath.toFirestore(),
      );

  /// Create or update a TrainingPath
  Future<void> createOrEditTrainingPath({required TrainingPath trainingPath}) {
    return _trainingPathDatabaseReference
        .doc(trainingPath.id)
        .set(trainingPath);
  }

  /// Retrieve a TrainingPath by its ID
  Stream<DocumentSnapshot> getTrainingPathById({required String id}) {
    return _trainingPathDatabaseReference.doc(id).snapshots();
  }

  /// Retrieve all TrainingPaths
  Stream<QuerySnapshot> getAllTrainingPaths() {
    return _trainingPathDatabaseReference.snapshots();
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
  Stream<QuerySnapshot> getSkillsFromCategory({required String id}) {
    return _skillDatabaseReference
        .where('categoryId', isEqualTo: id)
        .snapshots();
  }

  /// Retreive all Skills
  Stream<QuerySnapshot> getSkills() {
    return _skillDatabaseReference.snapshots();
  }

  ///  Retreives all Skills for Rider SKill Tree
  Stream<QuerySnapshot> getSkillsForRiderSkillTree() {
    return _skillDatabaseReference.where('rider', isEqualTo: true).snapshots();
  }

  ///  Retreives all Skills for Horse SKill Tree
  Stream<QuerySnapshot> getSkillsForHorseSkillTree() {
    return _skillDatabaseReference.where('rider', isEqualTo: false).snapshots();
  }

  /// delete Skill
  void deleteSkill({required Skill? skill}) {
    _skillDatabaseReference.doc(skill?.id).delete();
  }
}
