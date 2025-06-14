// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

/// Difficulty state for skills
enum DifficultyState {
  /// Introductory level skill
  Introductory,

  /// Intermediate level skill
  Intermediate,

  /// Advanced level skill
  Advanced,

  /// Represents all difficulty levels
  All,
}

/// Category of a skill
enum SkillCategory {
  /// Categort for any skill that does not fit into other categories
  Other,

  /// Category for skills that are performed in-hand
  In_Hand,

  /// Category for skills that are performed while mounted
  Mounted,

  /// Category for skills related to horse care and management
  Husbandry,
}

/// Model of a Skill
class Skill implements Comparable<Skill> {
  /// Creates a new Skill object.
  Skill({
    required this.id,
    required this.rider,
    required this.position,
    required this.skillName,
    required this.lastEditBy,
    required this.description,
    required this.lastEditDate,
    this.prerequisites = const [],
    required this.learningDescription,
    required this.proficientDescription,
    this.category = SkillCategory.Mounted,
    this.difficulty = DifficultyState.Introductory,
  });

  /// Unique identifier for the skill
  final String id;

  /// Position of the skill in the skill tree
  int position = -1;

  /// Whether the skill is for the rider or not
  final bool rider;

  /// Name of the skill
  final String skillName;

  /// Last user who edited the skill
  final String? lastEditBy;

  /// Description of the skill
  final String? description;

  /// Date when the skill was last edited
  final DateTime? lastEditDate;

  /// Category of the skill
  final SkillCategory category;

  /// New field: list of prerequisite skill IDs
  final List<String> prerequisites;

  /// Difficulty level of the skill
  final DifficultyState difficulty;

  /// Description of the skill when learning
  final String? learningDescription;

  /// Description of the skill when proficient
  final String? proficientDescription;

  /// Creates a Skill object from Firestore data.
  // ignore: sort_constructors_first
  factory Skill.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Skill(
      id: data!['id'] as String,
      rider: data['rider'] as bool,
      position: data['position'] as int,
      skillName: data['skillName'] as String,
      lastEditBy: data['lastEditBy'] as String?,
      description: data['description'] as String?,
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
      learningDescription: data['learningDescription'] as String?,
      proficientDescription: data['proficientDescription'] as String?,
      category: (data['category'] as String?) == 'Husbandry'
          ? SkillCategory.Husbandry
          : (data['category'] as String?) == 'In_Hand'
              ? SkillCategory.In_Hand
              : (data['category'] as String?) == 'Mounted'
                  ? SkillCategory.Mounted
                  : SkillCategory.Other,
      difficulty: (data['difficulty'] as String?) == 'Introductory'
          ? DifficultyState.Introductory
          : (data['difficulty'] as String?) == 'Intermediate'
              ? DifficultyState.Intermediate
              : (data['difficulty'] as String?) == 'Advanced'
                  ? DifficultyState.Advanced
                  : DifficultyState.Introductory,

      // gracefully handle nulls and ensure it's a List<String>
      prerequisites: (data['prerequisites'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
    );
  }

  /// Converts the Skill object to a Firestore-compatible map.
  Map<String, Object?> toFirestore() {
    return {
      'id': id,
      'rider': rider,
      'position': position,
      'skillName': skillName,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (description != null) 'description': description,
      if (lastEditDate != null) 'lastEditDate': lastEditDate,
      'category': category == SkillCategory.Husbandry
          ? 'Husbandry'
          : category == SkillCategory.In_Hand
              ? 'In_Hand'
              : category == SkillCategory.Mounted
                  ? 'Mounted'
                  : 'Other',
      'difficulty': difficulty == DifficultyState.Introductory
          ? 'Introductory'
          : difficulty == DifficultyState.Intermediate
              ? 'Intermediate'
              : difficulty == DifficultyState.Advanced
                  ? 'Advanced'
                  : 'Introductory',
      if (learningDescription != null)
        'learningDescription': learningDescription,
      if (proficientDescription != null)
        'proficientDescription': proficientDescription,

      // only store if non-empty
      if (prerequisites.isNotEmpty) 'prerequisites': prerequisites,
    };
  }

  /// Gets the position of the skill in the skill tree.
  int getPosition() {
    return position;
  }

  @override
  int compareTo(Skill skill) {
    return position.compareTo(skill.position);
  }
}
