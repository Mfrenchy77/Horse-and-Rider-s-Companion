import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/level.dart';

/// Firestore persistence mapper for [Level].
class LevelFirestoreMapper {
  const LevelFirestoreMapper._();

  /// Converts a Firestore [DocumentSnapshot] into a [Level].
  static Level fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
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

    return Level.fromMap({
      ...data,
      'lastEditDate': lastEditDate,
    });
  }

  /// Converts a [Level] into a Firestore-compatible document map.
  static Map<String, Object?> toFirestore(
    Level level, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return {
      'position': level.position,
      if (level.id != null) 'id': level.id,
      if (level.level != null) 'level': level.level,
      if (level.rider != null) 'rider': level.rider,
      if (level.skillId != null) 'skillId': level.skillId,
      if (level.learningDescription != null)
        'learningDescription': level.learningDescription,
      if (level.completeDescription != null)
        'completeDescription': level.completeDescription,
      if (level.levelName != null) 'levelName': level.levelName,
      if (level.lastEditBy != null) 'lastEditBy': level.lastEditBy,
      if (level.description != null) 'description': level.description,
      if (level.lastEditDate != null) 'lastEditDate': level.lastEditDate,
    };
  }
}
