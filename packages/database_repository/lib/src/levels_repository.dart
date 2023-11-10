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
  Stream<DocumentSnapshot> getLevel({required String id}) {
    return _levelsDatabaseReference.doc(id).snapshots();
  }

  ///   Retrieve all Levels
  Stream<QuerySnapshot> getLevelsForRiderSkillTree() {
    return _levelsDatabaseReference.where('rider', isEqualTo: true).snapshots();
  }

  ///   Retrieve all Levels
  Stream<QuerySnapshot> getLevelsForHorseSkillTree() {
    return _levelsDatabaseReference
        .where('rider', isEqualTo: false)
        .snapshots();
  }

  /// Delete a Level
  void deleteLevel({required Level? level}) {
    _levelsDatabaseReference.doc(level?.id).delete();
  }
}
