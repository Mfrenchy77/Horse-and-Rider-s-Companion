// ignore_for_file: constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/skill.dart';

///Crud interface for Firebase and SKills

class SkillsRepository {
  static const String SKILLS = 'Skills';

  final _skillDatabaseReference =
      FirebaseFirestore.instance.collection(SKILLS).withConverter<Skill>(
            fromFirestore: Skill.fromFirestore,
            toFirestore: (Skill skill, options) => skill.toFirestore(),
          );

  /// create or update [skill]
  Future<void> createOrUpdateSkill({required Skill skill}) {
    return _skillDatabaseReference.doc(skill.id).set(skill);
  }

  /// Retreive Skill from Category [id]
  Stream<QuerySnapshot> getSkillsFromCategory({required String id}) {
    return _skillDatabaseReference
        .where('categoryId', isEqualTo: id)
        .snapshots();
  }

  ///  Retreives all Skills for

  Stream<QuerySnapshot> getSkillsForRiderSkillTree() {
    return _skillDatabaseReference.where('rider', isEqualTo: true).snapshots();
  }

  Stream<QuerySnapshot> getSkillsForHorseSkillTree() {
    return _skillDatabaseReference.where('rider', isEqualTo: false).snapshots();
  }

  /// delete Skill
  void deleteSkill({required Skill? skill}) {
    _skillDatabaseReference.doc(skill?.id).delete();
  }
}
