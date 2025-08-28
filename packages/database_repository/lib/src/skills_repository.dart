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
  Stream<List<Skill>> getSkillsFromCategory({required String id}) {
    return _skillDatabaseReference
        .where('categoryId', isEqualTo: id)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///  Retreives all Skills for

  Stream<List<Skill>> getSkillsForRiderSkillTree() {
    return _skillDatabaseReference
        .where('rider', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

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
