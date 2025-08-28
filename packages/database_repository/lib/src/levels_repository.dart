// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

///   Crud interface for FireBase and Levels
///
class LevelsRepository {
  ///constant to reuse
  static const String LEVELS = 'Levels';

  final _levelsDatabaseReference =
      FirebaseFirestore.instance.collection(LEVELS).withConverter<Level>(
            fromFirestore: Level.fromFirestore,
            toFirestore: (Level level, options) => level.toFirestore(),
          );

  ///   Create or update [level]
  Future<void> createOrUpdateLevel({required Level level}) {
    return _levelsDatabaseReference.doc(level.id).set(level);
  }

  ///   Retrieve a single Level
  Stream<Level?> getLevel({required String id}) {
    return _levelsDatabaseReference
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }

  ///   Retrieve all Levels
  Stream<List<Level>> getLevelsForRiderSkillTree() {
    return _levelsDatabaseReference
        .where('rider', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///   Retrieve all Levels
  Stream<List<Level>> getLevelsForHorseSkillTree() {
    return _levelsDatabaseReference
        .where('rider', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Delete a Level
  void deleteLevel({required Level? level}) {
    _levelsDatabaseReference.doc(level?.id).delete();
  }
}
