// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names, lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart';

enum DifficultyState { introductory, intermediate, advanced, all }

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
    this.difficulty = DifficultyState.introductory,
  });

  final String id;
  int position = -1;
  final bool rider;
  final String? skillName;
  final String? lastEditBy;
  final String? description;
  final DateTime? lastEditDate;
  final DifficultyState difficulty;
  final String? learningDescription;
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
      skillName: data['skillName'] as String?,
      lastEditBy: data['lastEditBy'] as String?,
      description: data['description'] as String?,
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
      learningDescription: data['learningDescription'] as String?,
      proficientDescription: data['proficientDescription'] as String?,
      difficulty: (data['difficulty'] as String) == 'introductory'
          ? DifficultyState.introductory
          : (data['difficulty'] as String) == 'intermediate'
              ? DifficultyState.intermediate
              : (data['difficulty'] as String) == 'advanced'
                  ? DifficultyState.advanced
                  : DifficultyState.intermediate,
    );
  }

  void get subCategoryList {}

  Map<String, Object?> toFirestore() {
    return {
      'id': id,
      'rider': rider,
      'position': position,
      if (skillName != null) 'skillName': skillName,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (description != null) 'description': description,
      if (lastEditDate != null) 'lastEditDate': lastEditDate,
      'difficulty': difficulty == DifficultyState.introductory
          ? 'introductory'
          : difficulty == DifficultyState.intermediate
              ? 'intermediate'
              : difficulty == DifficultyState.advanced
                  ? 'advanced'
                  : 'introductory',
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
