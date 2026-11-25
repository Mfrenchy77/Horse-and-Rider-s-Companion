// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:database_repository/src/models/curriculum_skill.dart';
import 'package:database_repository/src/models/skill_family.dart';

/// Records a single level standard version increment inside a revision.
class RevisedStandardSummary {
  const RevisedStandardSummary({
    required this.skillId,
    required this.level,
    required this.fromVersion,
    required this.toVersion,
  });

  factory RevisedStandardSummary.fromMap(Map<String, dynamic> data) {
    return RevisedStandardSummary(
      skillId: data['skillId'] as String? ?? '',
      level: data['level'] as String? ?? '',
      fromVersion: (data['fromVersion'] as num?)?.toInt() ?? 1,
      toVersion: (data['toVersion'] as num?)?.toInt() ?? 1,
    );
  }

  final String skillId;
  final String level;
  final int fromVersion;
  final int toVersion;

  Map<String, Object?> toMap() => {
    'skillId': skillId,
    'level': level,
    'fromVersion': fromVersion,
    'toVersion': toVersion,
  };
}

/// Immutable header metadata for a published Skill Tree curriculum revision.
class CurriculumRevisionSummary {
  const CurriculumRevisionSummary({
    required this.id,
    required this.revisionNumber,
    required this.kind,
    required this.status,
    required this.publishedByUid,
    required this.publishedByName,
    required this.checksum,
    required this.chunkCount,
    required this.snapshotByteLength,
    required this.familyCount,
    required this.skillCount,
    required this.totalLevels,
    this.previousRevisionId,
    this.rollbackOfRevisionId,
    this.createdAt,
    this.publishedAt,
    this.notes,
    this.addedFamilyIds = const [],
    this.modifiedFamilyIds = const [],
    this.addedSkillIds = const [],
    this.modifiedSkillIds = const [],
    this.retiredSkillIds = const [],
    this.revisedStandards = const [],
    this.immutable = true,
    this.errorMessage,
  });

  factory CurriculumRevisionSummary.fromMap(Map<String, dynamic> data) {
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : const <String, dynamic>{};
    List<String> strList(Object? raw) =>
        (raw as List<dynamic>? ?? const []).whereType<String>().toList();
    final rawRevised =
        summary['revisedStandards'] as List<dynamic>? ?? const [];

    return CurriculumRevisionSummary(
      id: data['id'] as String? ?? '',
      revisionNumber: (data['revisionNumber'] as num?)?.toInt() ?? 0,
      kind: data['kind'] as String? ?? 'publish',
      status: data['status'] as String? ?? 'completed',
      previousRevisionId: data['previousRevisionId'] as String?,
      rollbackOfRevisionId: data['rollbackOfRevisionId'] as String?,
      createdAt: parseFlexibleDateTime(data['createdAt']),
      publishedAt: parseFlexibleDateTime(data['publishedAt']),
      publishedByUid: data['publishedByUid'] as String? ?? '',
      publishedByName: data['publishedByName'] as String? ?? 'Administrator',
      notes: data['notes'] as String?,
      checksum: data['checksum'] as String? ?? '',
      chunkCount: (data['chunkCount'] as num?)?.toInt() ?? 0,
      snapshotByteLength: (data['snapshotByteLength'] as num?)?.toInt() ?? 0,
      familyCount: (data['familyCount'] as num?)?.toInt() ?? 0,
      skillCount: (data['skillCount'] as num?)?.toInt() ?? 0,
      totalLevels: (data['totalLevels'] as num?)?.toInt() ?? 0,
      addedFamilyIds: strList(summary['addedFamilyIds']),
      modifiedFamilyIds: strList(summary['modifiedFamilyIds']),
      addedSkillIds: strList(summary['addedSkillIds']),
      modifiedSkillIds: strList(summary['modifiedSkillIds']),
      retiredSkillIds: strList(summary['retiredSkillIds']),
      revisedStandards: rawRevised
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                RevisedStandardSummary.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
      immutable: data['immutable'] as bool? ?? true,
      errorMessage: data['errorMessage'] as String?,
    );
  }

  final String id;
  final int revisionNumber;
  final String kind;
  final String status;
  final String? previousRevisionId;
  final String? rollbackOfRevisionId;
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final String publishedByUid;
  final String publishedByName;
  final String? notes;
  final String checksum;
  final int chunkCount;
  final int snapshotByteLength;
  final int familyCount;
  final int skillCount;
  final int totalLevels;
  final List<String> addedFamilyIds;
  final List<String> modifiedFamilyIds;
  final List<String> addedSkillIds;
  final List<String> modifiedSkillIds;
  final List<String> retiredSkillIds;
  final List<RevisedStandardSummary> revisedStandards;
  final bool immutable;
  final String? errorMessage;

  bool get isCompleted => status == 'completed';
  bool get isRollback => kind == 'rollback';
}

/// Complete reconstructed curriculum snapshot for a historical revision.
class CurriculumRevisionSnapshot {
  const CurriculumRevisionSnapshot({
    required this.summary,
    required this.families,
    required this.skills,
  });

  final CurriculumRevisionSummary summary;
  final List<SkillFamily> families;
  final List<CurriculumSkill> skills;
}
