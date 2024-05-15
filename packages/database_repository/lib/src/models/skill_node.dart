import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a node in the skill tree within a training path.
///
/// A skill node is a represntation of a skill located in a training path,
///  potentially with parents and children.
class SkillNode {
  /// Constructor for creating a new SkillNode instance.
  SkillNode({
    required this.id,
    required this.name,
    required this.skillId,
    required this.position,
    required this.parentId,
  });

  /// Unique identifier of the skillNode.
  final String id;

  /// The id of the Skill that the node is referencing.
  final String skillId;

  /// Name of the skill.
  final String name;

  /// Position of this skill within the training path.
  final int position;

  /// The id of the skill that is the parent, marking this node as a child.
  final String? parentId;

  /// Method to create a SkillNode object from Firestore data
  // ignore: sort_constructors_first
  factory SkillNode.fromMap(Map<String, dynamic> map) {
    return SkillNode(
      id: map['id'] as String,
      name: map['name'] as String,
      skillId: map['skillId'] as String,
      position: map['position'] as int,
      parentId: map['parentId'] as String,
    );
  }

  /// Method to create a SkillNode object from Firestore data
  /// (used by the Firestore package).
  // ignore: sort_constructors_first
  factory SkillNode.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return SkillNode(
      id: data!['id'] as String,
      name: data['name'] as String,
      position: data['position'] as int,
      skillId: data['skillId'] as String,
      parentId: data['parentId'] as String,
    );
  }

  /// Method to create a map of this SkillNode object.
  /// This is used when writing the object to Firestore.
  /// (used by the Firestore package).
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'skillId': skillId,
      'parentId': parentId,
      'position': position,
    };
  }

  /// Method to create a map of this SkillNode object.
  /// This is used when writing the object to Firestore.
  /// (used by the Firestore package).
  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'skillId': skillId,
      'parentId': parentId,
      'position': position,
    };
  }

  /// Creates a copy of this SkillNode but with the given
  ///  fields replaced with new values.
  SkillNode copyWith({
    String? id,
    String? name,
    int? position,
    String? skillId,
    String? parentId,
  }) {
    return SkillNode(
      id: id ?? this.id,
      name: name ?? this.name,
      skillId: skillId ?? this.skillId,
      parentId: parentId ?? this.parentId,
      position: position ?? this.position,
    );
  }
}
