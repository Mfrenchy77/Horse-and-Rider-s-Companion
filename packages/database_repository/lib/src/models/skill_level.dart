// ignore: lines_longer_than_80_chars
// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names

enum LevelState {
  NO_PROGRESS,
  LEARNING,
  PROFICIENT,
  VERIFIED,
}

/// Model of a Skill Level
class SkillLevel {
  SkillLevel({
    required this.skillId,
    this.verified = false,
    required this.skillName,
    required this.lastEditBy,
    required this.lastEditDate,
    this.levelState = LevelState.NO_PROGRESS,
  });

  bool verified;
  String skillId;
  String skillName;
  String? lastEditBy;
  DateTime? lastEditDate;
  LevelState levelState;

  factory SkillLevel.fromMap(Map<String, Object?> data) {
    return SkillLevel(
      skillId: data['skillId']! as String,
      skillName: data['skillName']! as String,
      verified: (data['verified'] as bool?) ?? false,
      lastEditBy: data['lastEditBy'] as String?,
      lastEditDate: _parseDateTime(data['lastEditDate']),
      levelState: _parseLevelState(data['levelState'] as String?),
    );
  }

  SkillLevel.fromJson(Map<String, Object?> json)
    : this(
        skillId: json['skillId']! as String,
        skillName: json['skillName']! as String,
        verified: (json['verified'] as bool?) ?? false,
        lastEditBy: json['lastEditBy'] as String?,
        lastEditDate: _parseDateTime(json['lastEditDate']),
        levelState: _parseLevelState(json['levelState'] as String?),
      );

  Map<String, Object?> toMap() {
    return {
      'skillId': skillId,
      'verified': verified,
      'skillName': skillName,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (lastEditDate != null)
        'lastEditDate': lastEditDate!.toIso8601String(),
      'levelState': levelStateName(levelState),
    };
  }

  Map<String, Object?> toJson() {
    return {
      'skillId': skillId,
      'verified': verified,
      'skillName': skillName,
      'lastEditBy': lastEditBy,
      'lastEditDate': lastEditDate?.toIso8601String(),
      'levelState': levelStateName(levelState),
    };
  }

  static LevelState _parseLevelState(String? value) {
    return switch (value) {
      'LEARNING' => LevelState.LEARNING,
      'PROFICIENT' => LevelState.PROFICIENT,
      'VERIFIED' => LevelState.VERIFIED,
      _ => LevelState.NO_PROGRESS,
    };
  }

  static String levelStateName(LevelState state) {
    return switch (state) {
      LevelState.NO_PROGRESS => 'NO_PROGRESS',
      LevelState.LEARNING => 'LEARNING',
      LevelState.PROFICIENT => 'PROFICIENT',
      LevelState.VERIFIED => 'VERIFIED',
    };
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
