// ignore: lines_longer_than_80_chars
// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

enum LevelState {
  NO_PROGRESS,
  LEARNING,
  COMPLETE,
  VERIFIED,
}

///Model of a Skill Level
class SkillLevel {
  SkillLevel({
    required this.levelId,
    this.verified = false,
    required this.lastEditBy,
    required this.lastEditDate,
    this.levelState = LevelState.NO_PROGRESS,
  });

  final bool? verified;
  final String? levelId;
  final String? lastEditBy;
  final DateTime? lastEditDate;
  final LevelState levelState;

  SkillLevel.fromJson(Map<String, Object?> json)
      : this(
          levelId: json['levelId']! as String,
          verified: json['verified'] as bool?,
          lastEditBy: json['lastEditBy']! as String,
          lastEditDate: (json['lastEditDate']! as Timestamp).toDate(),
          levelState: (json['levelState']! as String) == 'NO_PROGRESS'
              ? LevelState.NO_PROGRESS
              : (json['levelState']! as String) == 'LEARNING'
                  ? LevelState.LEARNING
                  : (json['levelState']! as String) == 'COMPLETE'
                      ? LevelState.COMPLETE
                      : (json['levelState']! as String) == 'VERIFIED'
                          ? LevelState.VERIFIED
                          : LevelState.NO_PROGRESS,
        );
  factory SkillLevel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return SkillLevel(
      levelId: data!['levelId'] as String?,
      verified: data['verified'] as bool?,
      lastEditBy: data['lastEditBy'] as String?,
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
      levelState: (data['levelState'] as String) == 'NO_PROGRESS'
          ? LevelState.NO_PROGRESS
          : (data['levelState'] as String) == 'LEARNING'
              ? LevelState.LEARNING
              : (data['levelState'] as String) == 'COMPLETE'
                  ? LevelState.COMPLETE
                  : (data['levelState'] as String) == 'VERIFIED'
                      ? LevelState.VERIFIED
                      : LevelState.NO_PROGRESS,
    );
  }
  Map<String, Object?> toFirestore() {
    return {
      if (levelId != null) 'levelId': levelId,
      if (verified != null) 'verified': verified,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (lastEditDate != null) 'lastEditDate': lastEditDate,
      'levelState': levelState == LevelState.NO_PROGRESS
          ? 'NO_PROGRESS'
          : levelState == LevelState.LEARNING
              ? 'LEARNING'
              : levelState == LevelState.COMPLETE
                  ? 'COMPLETE'
                  : levelState == LevelState.VERIFIED
                      ? 'VERIFIED'
                      : 'NO_PROGRESS',
    };
  }

  Map<String, Object?> toJson() {
    return {
      'levelId': levelId,
      'verified': verified,
      'lastEditBy': lastEditBy,
      'lastEditDate': lastEditDate,
      'levelState': levelState == LevelState.NO_PROGRESS
          ? 'NO_PROGRESS'
          : levelState == LevelState.LEARNING
              ? 'LEARNING'
              : levelState == LevelState.COMPLETE
                  ? 'COMPLETE'
                  : levelState == LevelState.VERIFIED
                      ? 'VERIFIED'
                      : 'NO_PROGRESS',
    };
  }
}
