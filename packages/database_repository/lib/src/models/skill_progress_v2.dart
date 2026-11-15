// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:database_repository/src/models/curriculum_skill.dart';
import 'package:database_repository/src/models/skill.dart';
import 'package:database_repository/src/models/skill_family.dart';
import 'package:database_repository/src/models/skill_level.dart';

/// Ordered difficulty progression used for derived summary calculations.
const List<DifficultyState> kOrderedDifficultyLevels = [
  DifficultyState.Introductory,
  DifficultyState.Intermediate,
  DifficultyState.Advanced,
];

/// Self-assessed progress at one difficulty level of a [CurriculumSkill].
class LevelProgress {
  const LevelProgress({
    required this.state,
    this.updatedAt,
    this.updatedByUid,
    this.updatedByName,
  });

  factory LevelProgress.fromMap(Map<String, dynamic> data) {
    return LevelProgress(
      state: _parseSelfState(data['state'] as String?),
      updatedAt: parseFlexibleDateTime(data['updatedAt']),
      updatedByUid: data['updatedByUid'] as String?,
      updatedByName: data['updatedByName'] as String?,
    );
  }

  final LevelState state;
  final DateTime? updatedAt;
  final String? updatedByUid;
  final String? updatedByName;

  Map<String, Object?> toMap({bool preserveDateTime = false}) {
    return {
      'state': SkillLevel.levelStateName(state),
      if (updatedAt != null)
        'updatedAt': preserveDateTime
            ? updatedAt
            : updatedAt!.toIso8601String(),
      if (updatedByUid != null) 'updatedByUid': updatedByUid,
      if (updatedByName != null) 'updatedByName': updatedByName,
    };
  }

  static LevelState _parseSelfState(String? value) {
    return switch (value?.toUpperCase()) {
      'PROFICIENT' => LevelState.PROFICIENT,
      'LEARNING' || _ => LevelState.LEARNING,
    };
  }
}

/// Per-skill self-assessment document stored under a Rider or Horse profile.
class SkillProgressRecord {
  const SkillProgressRecord({
    required this.skillId,
    required this.subject,
    required this.levels,
    this.updatedAt,
    this.schemaVersion = 2,
  });

  factory SkillProgressRecord.fromMap(Map<String, dynamic> data) {
    final rawLevels = data['levels'] as Map<dynamic, dynamic>? ?? const {};
    final parsed = <DifficultyState, LevelProgress>{};
    for (final entry in rawLevels.entries) {
      final level = parseOptionalDifficulty(entry.key as String?);
      if (level != null && entry.value is Map) {
        parsed[level] = LevelProgress.fromMap(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }
    return SkillProgressRecord(
      skillId: data['skillId'] as String? ?? '',
      subject: SkillSubject.fromString(data['subject'] as String?),
      levels: parsed,
      updatedAt: parseFlexibleDateTime(data['updatedAt']),
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 2,
    );
  }

  final String skillId;
  final SkillSubject subject;
  final Map<DifficultyState, LevelProgress> levels;
  final DateTime? updatedAt;
  final int schemaVersion;

  /// Returns the highest [DifficultyState] self-assessed as `PROFICIENT`,
  /// or `null` if none is Proficient.
  DifficultyState? highestProficientLevel([
    List<DifficultyState> orderedLevels = kOrderedDifficultyLevels,
  ]) {
    DifficultyState? highest;
    for (final level in orderedLevels) {
      if (levels[level]?.state == LevelState.PROFICIENT) {
        highest = level;
      }
    }
    return highest;
  }

  Map<String, Object?> toMap({bool preserveDateTime = false}) {
    return {
      'skillId': skillId,
      'subject': subject.toWireString(),
      'levels': {
        for (final entry in levels.entries)
          difficultyToKey(entry.key):
              entry.value.toMap(preserveDateTime: preserveDateTime),
      },
      if (updatedAt != null)
        'updatedAt': preserveDateTime
            ? updatedAt
            : updatedAt!.toIso8601String(),
      'schemaVersion': schemaVersion,
    };
  }
}

/// Instructor verification at one difficulty level (server-written only).
class LevelVerification {
  const LevelVerification({
    this.verifiedState = LevelState.PROFICIENT,
    this.verifiedByUid,
    required this.verifiedByName,
    this.verifiedAt,
    this.connectionId,
    this.standardVersion = 1,
    this.eventId,
  });

  factory LevelVerification.fromMap(Map<String, dynamic> data) {
    return LevelVerification(
      verifiedState: data['verifiedState'] == 'LEARNING'
          ? LevelState.LEARNING
          : LevelState.PROFICIENT,
      verifiedByUid: data['verifiedByUid'] as String?,
      verifiedByName: data['verifiedByName'] as String? ?? '',
      verifiedAt: parseFlexibleDateTime(data['verifiedAt']),
      connectionId: data['connectionId'] as String?,
      standardVersion: (data['standardVersion'] as num?)?.toInt() ?? 1,
      eventId: data['eventId'] as String?,
    );
  }

  final LevelState verifiedState;
  final String? verifiedByUid;
  final String verifiedByName;
  final DateTime? verifiedAt;
  final String? connectionId;
  final int standardVersion;
  final String? eventId;

  Map<String, Object?> toMap({bool preserveDateTime = false}) {
    return {
      'verifiedState': SkillLevel.levelStateName(verifiedState),
      if (verifiedByUid != null) 'verifiedByUid': verifiedByUid,
      'verifiedByName': verifiedByName,
      if (verifiedAt != null)
        'verifiedAt': preserveDateTime
            ? verifiedAt
            : verifiedAt!.toIso8601String(),
      if (connectionId != null) 'connectionId': connectionId,
      'standardVersion': standardVersion,
      if (eventId != null) 'eventId': eventId,
    };
  }
}

/// Current instructor verifications for a skill (server-written only).
class SkillVerificationRecord {
  const SkillVerificationRecord({
    required this.skillId,
    required this.levels,
    this.updatedAt,
  });

  factory SkillVerificationRecord.fromMap(Map<String, dynamic> data) {
    final rawLevels = data['levels'] as Map<dynamic, dynamic>? ?? const {};
    final parsed = <DifficultyState, LevelVerification>{};
    for (final entry in rawLevels.entries) {
      final level = parseOptionalDifficulty(entry.key as String?);
      if (level != null && entry.value is Map) {
        parsed[level] = LevelVerification.fromMap(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }
    return SkillVerificationRecord(
      skillId: data['skillId'] as String? ?? '',
      levels: parsed,
      updatedAt: parseFlexibleDateTime(data['updatedAt']),
    );
  }

  final String skillId;
  final Map<DifficultyState, LevelVerification> levels;
  final DateTime? updatedAt;

  DifficultyState? highestVerifiedLevel([
    List<DifficultyState> orderedLevels = kOrderedDifficultyLevels,
  ]) {
    DifficultyState? highest;
    for (final level in orderedLevels) {
      if (levels.containsKey(level)) {
        highest = level;
      }
    }
    return highest;
  }

  Map<String, Object?> toMap({bool preserveDateTime = false}) {
    return {
      'skillId': skillId,
      'levels': {
        for (final entry in levels.entries)
          difficultyToKey(entry.key):
              entry.value.toMap(preserveDateTime: preserveDateTime),
      },
      if (updatedAt != null)
        'updatedAt': preserveDateTime
            ? updatedAt
            : updatedAt!.toIso8601String(),
    };
  }
}

enum VerificationEventType {
  verified,
  revoked;

  static VerificationEventType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'revoked' => VerificationEventType.revoked,
      'verified' || _ => VerificationEventType.verified,
    };
  }
}

/// Immutable audit record for an instructor verification or revocation.
class VerificationEvent {
  const VerificationEvent({
    required this.id,
    required this.type,
    required this.skillId,
    required this.skillName,
    required this.level,
    this.verifiedState = LevelState.PROFICIENT,
    required this.actorUid,
    required this.actorName,
    required this.connectionId,
    this.previousVerifiedByUid,
    this.previousVerifiedAt,
    this.reason,
    this.standardVersion = 1,
    this.at,
  });

  factory VerificationEvent.fromMap(Map<String, dynamic> data) {
    final prev = data['previousVerification'] as Map<dynamic, dynamic>?;
    return VerificationEvent(
      id: data['id'] as String? ?? '',
      type: VerificationEventType.fromString(data['type'] as String?),
      skillId: data['skillId'] as String? ?? '',
      skillName: data['skillName'] as String? ?? '',
      level: parseOptionalDifficulty(data['level'] as String?) ??
          DifficultyState.Introductory,
      verifiedState: data['verifiedState'] == 'LEARNING'
          ? LevelState.LEARNING
          : LevelState.PROFICIENT,
      actorUid: data['actorUid'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      connectionId: data['connectionId'] as String? ?? '',
      previousVerifiedByUid: prev?['verifiedByUid'] as String?,
      previousVerifiedAt: parseFlexibleDateTime(prev?['verifiedAt']),
      reason: data['reason'] as String?,
      standardVersion: (data['standardVersion'] as num?)?.toInt() ?? 1,
      at: parseFlexibleDateTime(data['at']),
    );
  }

  final String id;
  final VerificationEventType type;
  final String skillId;
  final String skillName;
  final DifficultyState level;
  final LevelState verifiedState;
  final String actorUid;
  final String actorName;
  final String connectionId;
  final String? previousVerifiedByUid;
  final DateTime? previousVerifiedAt;
  final String? reason;
  final int standardVersion;
  final DateTime? at;

  Map<String, Object?> toMap({bool preserveDateTime = false}) {
    return {
      'id': id,
      'type': type.name,
      'skillId': skillId,
      'skillName': skillName,
      'level': difficultyToKey(level),
      'verifiedState': SkillLevel.levelStateName(verifiedState),
      'actorUid': actorUid,
      'actorName': actorName,
      'connectionId': connectionId,
      if (previousVerifiedByUid != null || previousVerifiedAt != null)
        'previousVerification': {
          if (previousVerifiedByUid != null)
            'verifiedByUid': previousVerifiedByUid,
          if (previousVerifiedAt != null)
            'verifiedAt': preserveDateTime
                ? previousVerifiedAt
                : previousVerifiedAt!.toIso8601String(),
        },
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
      'standardVersion': standardVersion,
      if (at != null) 'at': preserveDateTime ? at : at!.toIso8601String(),
    };
  }
}
