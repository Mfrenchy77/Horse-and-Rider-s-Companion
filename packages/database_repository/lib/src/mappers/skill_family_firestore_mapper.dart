// ignore_for_file: public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/skill_family.dart';

/// Firestore persistence mapper for [SkillFamily].
class SkillFamilyFirestoreMapper {
  const SkillFamilyFirestoreMapper._();

  static SkillFamily fromMap(Map<String, dynamic> data, {String? docId}) {
    final normalized = Map<String, dynamic>.from(data);
    if ((normalized['id'] as String?)?.isEmpty ?? true) {
      if (docId != null) normalized['id'] = docId;
    }
    return SkillFamily.fromMap(normalized);
  }

  static SkillFamily fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return fromMap(snapshot.data()!, docId: snapshot.id);
  }

  static Map<String, Object?> toFirestore(
    SkillFamily family, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return family.toMap();
  }
}
