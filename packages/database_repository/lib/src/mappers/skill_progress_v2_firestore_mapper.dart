// ignore_for_file: public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/mappers/curriculum_skill_firestore_mapper.dart';
import 'package:database_repository/src/models/skill_progress_v2.dart';

/// Firestore persistence mappers for Skill Tree 2.0 progress, verifications,
/// and verification audit events.
class SkillProgressV2FirestoreMapper {
  const SkillProgressV2FirestoreMapper._();

  static SkillProgressRecord progressFromMap(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    final normalized = normalizeFirestoreTimestamps(data);
    if ((normalized['skillId'] as String?)?.isEmpty ?? true) {
      if (docId != null) normalized['skillId'] = docId;
    }
    return SkillProgressRecord.fromMap(normalized);
  }

  static SkillProgressRecord progressFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return progressFromMap(snapshot.data()!, docId: snapshot.id);
  }

  static Map<String, Object?> progressToFirestore(
    SkillProgressRecord record, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return record.toMap(preserveDateTime: true);
  }

  static SkillVerificationRecord verificationFromMap(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    final normalized = normalizeFirestoreTimestamps(data);
    if ((normalized['skillId'] as String?)?.isEmpty ?? true) {
      if (docId != null) normalized['skillId'] = docId;
    }
    return SkillVerificationRecord.fromMap(normalized);
  }

  static SkillVerificationRecord verificationFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return verificationFromMap(snapshot.data()!, docId: snapshot.id);
  }

  static VerificationEvent eventFromMap(
    Map<String, dynamic> data, {
    String? docId,
  }) {
    final normalized = normalizeFirestoreTimestamps(data);
    if ((normalized['id'] as String?)?.isEmpty ?? true) {
      if (docId != null) normalized['id'] = docId;
    }
    return VerificationEvent.fromMap(normalized);
  }

  static VerificationEvent eventFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return eventFromMap(snapshot.data()!, docId: snapshot.id);
  }
}
