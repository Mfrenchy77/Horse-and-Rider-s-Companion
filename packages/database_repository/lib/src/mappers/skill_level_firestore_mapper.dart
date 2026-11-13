import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/skill_level.dart';

/// Firestore persistence mapper for [SkillLevel].
class SkillLevelFirestoreMapper {
  const SkillLevelFirestoreMapper._();

  /// Converts a Firestore map (which may contain [Timestamp]s) into a
  /// [SkillLevel].
  static SkillLevel fromMap(Map<String, dynamic> data) {
    final rawDate = data['lastEditDate'];
    final DateTime? lastEditDate;
    if (rawDate is Timestamp) {
      lastEditDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      lastEditDate = rawDate;
    } else if (rawDate is String) {
      lastEditDate = DateTime.tryParse(rawDate);
    } else if (rawDate is int) {
      lastEditDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    } else {
      lastEditDate = null;
    }

    return SkillLevel.fromMap({
      ...data,
      'lastEditDate': lastEditDate,
    });
  }

  /// Converts a Firestore [DocumentSnapshot] into a [SkillLevel].
  static SkillLevel fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return fromMap(snapshot.data()!);
  }

  /// Converts a [SkillLevel] into a Firestore-compatible map (omitting nulls
  /// for optional metadata, matching legacy `SkillLevel.toFirestore`).
  static Map<String, Object?> toFirestore(
    SkillLevel skillLevel, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return {
      'skillId': skillLevel.skillId,
      'verified': skillLevel.verified,
      'skillName': skillLevel.skillName,
      if (skillLevel.lastEditBy != null) 'lastEditBy': skillLevel.lastEditBy,
      if (skillLevel.lastEditDate != null)
        'lastEditDate': skillLevel.lastEditDate,
      'levelState': SkillLevel.levelStateName(skillLevel.levelState),
    };
  }

  /// Converts a [SkillLevel] into a Firestore-compatible map preserving null
  /// keys (matching legacy `SkillLevel.toJson` used by `RiderProfile`).
  static Map<String, Object?> toJson(SkillLevel skillLevel) {
    return {
      'skillId': skillLevel.skillId,
      'verified': skillLevel.verified,
      'skillName': skillLevel.skillName,
      'lastEditBy': skillLevel.lastEditBy,
      'lastEditDate': skillLevel.lastEditDate,
      'levelState': SkillLevel.levelStateName(skillLevel.levelState),
    };
  }
}
