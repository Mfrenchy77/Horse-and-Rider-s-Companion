/// Represents a node in the skill tree within a training path.
///
/// A skill node is a representation of a skill located in a training path,
/// potentially with parents and children.
class SkillNode {
  /// Constructor for creating a new SkillNode instance.
  SkillNode({
    required this.id,
    required this.name,
    required this.skillId,
    required this.position,
    required this.parentId,
  });

  /// Creates a [SkillNode] from a backend-neutral map.
  // ignore: sort_constructors_first
  factory SkillNode.fromMap(Map<String, dynamic> map) {
    return SkillNode(
      id: map['id'] as String,
      name: map['name'] as String,
      skillId: map['skillId'] as String,
      position: map['position'] as int,
      parentId: map['parentId'] as String?,
    );
  }

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

  /// Converts this [SkillNode] to a backend-neutral map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'skillId': skillId,
      'parentId': parentId,
      'position': position,
    };
  }

  /// Creates a copy of this SkillNode but with the given
  /// fields replaced with new values.
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
