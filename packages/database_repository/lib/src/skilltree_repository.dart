// ignore_for_file: constant_identifier_names, lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

/// Repository for Accessing Elements of the SkillTree
class SkillTreeRepository {
  /// Constructor for SkillTreeRepository
  SkillTreeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
/* ****
                  ****   TrainingPaths   ****

**** */

  /// Constant for Accessing the Training Paths in the Database
  static const String TRAINING_PATHS = 'TrainingPaths';

  CollectionReference<TrainingPath> _trainingPaths() =>
      _firestore.collection(TRAINING_PATHS).withConverter<TrainingPath>(
            fromFirestore: (snap, options) => TrainingPath.fromFirestore(snap),
            toFirestore: (tp, options) => tp.toFirestore(),
          );

  /// Create or update a TrainingPath
  Future<void> createOrEditTrainingPath({required TrainingPath trainingPath}) {
    return _trainingPaths().doc(trainingPath.id).set(trainingPath);
  }

  /// Retrieve a TrainingPath by its ID
  Stream<TrainingPath?> getTrainingPathById({required String id}) {
    return _trainingPaths().doc(id).snapshots().map((snap) => snap.data());
  }

  /// Retrieve all TrainingPaths
  Stream<List<TrainingPath>> getAllTrainingPaths() {
    return _trainingPaths()
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Delete a TrainingPath
  void deleteTrainingPath({required TrainingPath? trainingPath}) {
    _trainingPaths().doc(trainingPath?.id).delete();
  }

/* ****
                  ****   Skills   ****

**** */

  /// Constant for Accessing the Skills on the Skill Tree
  static const String SKILLS = 'Skills';

  CollectionReference<Skill> _skills() =>
      _firestore.collection(SKILLS).withConverter<Skill>(
            fromFirestore: Skill.fromFirestore,
            toFirestore: (Skill skill, options) => skill.toFirestore(),
          );

  /// create or update [skill]
  Future<void> createOrEditSkill({required Skill skill}) {
    return _skills().doc(skill.id).set(skill);
  }

  /// Retrieve Skills by a category string stored under 'category'.
  /// The expected values are 'Husbandry', 'In_Hand', 'Mounted', or 'Other'.
  Stream<List<Skill>> getSkillsFromCategory({required String id}) {
    return _skills()
        .where('category', isEqualTo: id)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Retreive all Skills
  Stream<List<Skill>> getSkills() {
    return _skills()
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///  Retreives all Skills for Rider SKill Tree
  Stream<List<Skill>> getSkillsForRiderSkillTree() {
    return _skills()
        .where('rider', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///  Retreives all Skills for Horse SKill Tree
  Stream<List<Skill>> getSkillsForHorseSkillTree() {
    return _skills()
        .where('rider', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// delete Skill
  void deleteSkill({required Skill? skill}) {
    _skills().doc(skill?.id).delete();
  }
}
