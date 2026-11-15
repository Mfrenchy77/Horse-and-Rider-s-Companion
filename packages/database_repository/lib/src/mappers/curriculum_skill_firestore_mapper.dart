// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/curriculum_skill.dart';

/// Firestore persistence mapper for [CurriculumSkill].
class CurriculumSkillFirestoreMapper {
  const CurriculumSkillFirestoreMapper._();

  static CurriculumSkill fromMap(Map<String, dynamic> data, {String? docId}) {
    final normalized = normalizeFirestoreTimestamps(data);
    if ((normalized['id'] as String?)?.isEmpty ?? true) {
      if (docId != null) normalized['id'] = docId;
    }
    return CurriculumSkill.fromMap(normalized);
  }

  static CurriculumSkill fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return fromMap(snapshot.data()!, docId: snapshot.id);
  }

  static Map<String, Object?> toFirestore(
    CurriculumSkill skill, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return skill.toMap(preserveDateTime: true);
  }
}

/// Recursively converts any [Timestamp] values in a Firestore map to [DateTime].
Map<String, dynamic> normalizeFirestoreTimestamps(Map<String, dynamic> input) {
  final result = <String, dynamic>{};
  for (final entry in input.entries) {
    result[entry.key] = _convertValue(entry.value);
  }
  return result;
}

Object? _convertValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is Map) {
    return normalizeFirestoreTimestamps(Map<String, dynamic>.from(value));
  }
  if (value is List) {
    return value.map(_convertValue).toList();
  }
  return value;
}
