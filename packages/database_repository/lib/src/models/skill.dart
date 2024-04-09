// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names, lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart';

enum DifficultyState {
  Introductory,
  Intermediate,
  Advanced,
  All,
}

enum SkillCategory {
  Other,
  In_Hand,
  Mounted,
  Husbandry,
}

/// Model of a Skill
class Skill implements Comparable<Skill> {
  Skill({
    required this.id,
    required this.rider,
    required this.position,
    required this.skillName,
    required this.lastEditBy,
    required this.description,
    required this.lastEditDate,
    required this.learningDescription,
    required this.proficientDescription,
    this.category = SkillCategory.Mounted,
    this.difficulty = DifficultyState.Introductory,
  });

  /// The unique identifier of the skill
  final String id;

  /// The position of the skill in the list
  int position = -1;

  /// Whether the skill is for a rider or a horse
  final bool rider;

  /// The name of the skill
  final String skillName;

  /// The user who last edited the skill
  final String? lastEditBy;

  /// The description of the skill
  final String? description;

  /// The date the skill was last edited
  final DateTime? lastEditDate;

  /// The difficulty of the skill
  final DifficultyState difficulty;

  /// The category of the skill
  final SkillCategory category;

  /// The description of the skill when learning

  final String? learningDescription;

  /// The description of the skill when proficient
  final String? proficientDescription;

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
    );
  }

  void get subCategoryList {}

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
          ? 'introductory'
          : difficulty == DifficultyState.Intermediate
              ? 'Intermediate'
              : difficulty == DifficultyState.Advanced
                  ? 'Advanced'
                  : 'Introductory',
      if (learningDescription != null)
        'learningDescription': learningDescription,
      if (proficientDescription != null)
        'proficientDescription': proficientDescription,
    };
  }

  int getPosition() {
    return position;
  }

  @override
  int compareTo(Skill skill) {
    if (getPosition() > skill.getPosition()) {
      return 1;
    } else if (getPosition() < skill.getPosition()) {
      return -1;
    } else {
      return 0;
    }
  }
}
