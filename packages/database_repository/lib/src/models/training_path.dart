import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

/// Represents a training path in the skill tree.
///
/// A training path is a collection of skills, defined by trainers
///  or instructors, that guide the learning process in a structured manner.
class TrainingPath {
  /// Constructor for creating a new TrainingPath instance.
  TrainingPath({
    required this.id,
    required this.name,
    required this.skills,
    required this.createdBy,
    required this.createdAt,
    required this.isForHorse,
    required this.skillNodes,
    required this.lastEditBy,
    required this.createdById,
    required this.description,
    required this.lastEditDate,
  });

  /// Unique identifier of the training path.
  final String id;

  /// Name of the training path.
  final String name;

  /// Description of the training path.
  final String description;

  /// User's name who created the training path.
  final String createdBy;


  /// Whether the training path is for horses or not.
  final bool isForHorse;

  /// User's email who created the training path.
  final String createdById;

  /// Creation date of the training path.
  final DateTime createdAt;

  /// User who last edited the training path.
  final String lastEditBy;

  /// List of all the Skill ids in the training path.
  final List<String?> skills;

  /// Date when the training path was last edited.
  final DateTime lastEditDate;

  /// List of skill nodes that make up the training path.
  final List<SkillNode?> skillNodes;

  /// Method to create a TrainingPath object from Firestore data

  // ignore: sort_constructors_first
  factory TrainingPath.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return TrainingPath(
      id: data!['id'] as String,
      name: data['name'] as String,
      isForHorse: data['isForHorse'] as bool,
      createdBy: data['createdBy'] as String,
      lastEditBy: data['lastEditBy'] as String,
      createdById: data['createdById'] as String,
      description: data['description'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
      skills: (data['skills'] as List).map((e) => e as String).toList(),
      skillNodes: (data['skillNodes'] as List<dynamic>)
          .map((e) => SkillNode.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Method to convert a TrainingPath object to Firestore data

  Map<String, Object?> toFirestore() {
    return {
      'id': id,
      'name': name,
      'skills': skills,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'isForHorse': isForHorse,
      'lastEditBy': lastEditBy,
      'createdById': createdById,
      'description': description,
      'lastEditDate': lastEditDate,
      'skillNodes': skillNodes.map((e) => e?.toMap()).toList(),
    };
  }

  /// Creates a copy of this TrainingPath but with the given
  ///  fields replaced with new values.
  TrainingPath copyWith({
    String? id,
    String? name,
    String? createdBy,
    String? lastEditBy,
    String? createdById,
    DateTime? createdAt,
    String? description,
    List<String>? skills,
    DateTime? lastEditDate,
    List<SkillNode>? skillNodes,
  }) {
    return TrainingPath(
      id: id ?? this.id,
      isForHorse: isForHorse,
      name: name ?? this.name,
      skills: skills ?? this.skills,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      skillNodes: skillNodes ?? this.skillNodes,
      lastEditBy: lastEditBy ?? this.lastEditBy,
      createdById: createdById ?? this.createdById,
      description: description ?? this.description,
      lastEditDate: lastEditDate ?? this.lastEditDate,
    );
  }
}
