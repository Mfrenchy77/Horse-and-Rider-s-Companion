import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/skill_node.dart';

/// Firestore persistence mapper for [SkillNode].
class SkillNodeFirestoreMapper {
  const SkillNodeFirestoreMapper._();

  /// Converts a Firestore [DocumentSnapshot] into a [SkillNode].
  static SkillNode fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return SkillNode.fromMap({
      ...data,
      'id': (data['id'] as String?) ?? snapshot.id,
    });
  }

  /// Converts a [SkillNode] into a Firestore-compatible document map.
  static Map<String, dynamic> toFirestore(
    SkillNode skillNode, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return skillNode.toMap();
  }
}
