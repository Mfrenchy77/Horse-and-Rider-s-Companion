// ignore_for_file: constant_identifier_names, public_member_api_docs, sort_constructors_first, lines_longer_than_80_chars

import 'package:cloud_firestore/cloud_firestore.dart';

///  Possibe Level States
// enum LevelStates {
//   NO_PROGRESS,
//   LEARNING,
//   COMPLETE,
//   VERIFIED,
// }

/// Model representing a Level in the Skill Tree
class Level implements Comparable<Level> {
  Level({
    required this.id,
    required this.level,
    required this.rider,
    required this.skillId,
    required this.levelName,
    required this.position,
    required this.lastEditBy,
   // required this.levelState,
    required this.description,
    required this.lastEditDate,
    required this.learningDescription,
    required this.completeDescription,
  });

  final String? id;
  final int? level;
  final bool? rider;
  final int position;
  final String? skillId;
  final String? levelName;
  final String? lastEditBy;
  final String? description;
  final DateTime? lastEditDate;
  final String? learningDescription;
  final String? completeDescription;
  //LevelStates? levelState = LevelStates.NO_PROGRESS;

  factory Level.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Level(
      id: data!['id'] as String?,
      level: data['level'] as int?,
      rider: data['rider'] as bool?,
      position: data['position'] as int,
      skillId: data['skillId'] as String?,
      levelName: data['levelName'] as String?,
      lastEditBy: data['lastEditBy'] as String?,
      description: data['description'] as String?,
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
     // levelState: LevelStates.values[(data['levelState'] as int)],
      learningDescription: data['learningDescription'] as String?,
      completeDescription: data['completeDescription'] as String?,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'position': position,
      if (id != null) 'id': id,
      if (level != null) 'level': level,
      if (rider != null) 'rider': rider,
      if (skillId != null) 'skillId': skillId,
      if (learningDescription != null)
        'learningDescription': learningDescription,
      if (completeDescription != null)
        'completeDescription': completeDescription,
      if (levelName != null) 'levelName': levelName,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (description != null) 'description': description,
      if (lastEditDate != null) 'lastEditDate': lastEditDate,
     // if (levelState != null) 'levelState': levelState?.index,
    };
  }

  @override
  int compareTo(Level level) {
    if (position > level.position) {
      return 1;
    } else if (position < level.position) {
      return -1;
    } else {
      return 0;
    }
  }
}
