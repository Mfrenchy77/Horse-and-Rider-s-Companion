import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/skill.dart';

/// Firestore persistence mapper for [Skill].
class SkillFirestoreMapper {
  const SkillFirestoreMapper._();

  /// Converts a Firestore map (which may contain [Timestamp]s) into a [Skill].
  static Skill fromMap(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    final rawDate = normalized['lastEditDate'];
    if (rawDate is Timestamp) {
      normalized['lastEditDate'] = rawDate.toDate();
    }
    return Skill.fromMap(normalized);
  }

  /// Converts a Firestore [DocumentSnapshot] into a [Skill].
  static Skill fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return fromMap(snapshot.data()!);
  }

  /// Converts a [Skill] into a Firestore-compatible map, preserving
  /// `DateTime` for `lastEditDate` and omitting null optional fields and
  /// empty `prerequisites` (matching legacy `Skill.toFirestore`).
  static Map<String, Object?> toFirestore(
    Skill skill, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    final map = skill.toMap();
    if (skill.lastEditDate != null) {
      map['lastEditDate'] = skill.lastEditDate;
    }
    return map;
  }
}
