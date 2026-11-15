// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:database_repository/src/models/skill.dart';
import 'package:database_repository/src/models/skill_family.dart';

/// Lifecycle status of a [CurriculumSkill] document.
enum CurriculumSkillStatus {
  draft,
  active,
  retired;

  static CurriculumSkillStatus fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'draft' => CurriculumSkillStatus.draft,
      'retired' => CurriculumSkillStatus.retired,
      'active' || _ => CurriculumSkillStatus.active,
    };
  }
}

/// Non-blocking relationship between two [CurriculumSkill]s.
enum SkillRelationType {
  counterpart,
  foundation,
  next,
  theory;

  static SkillRelationType fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'counterpart' => SkillRelationType.counterpart,
      'foundation' => SkillRelationType.foundation,
      'next' => SkillRelationType.next,
      'theory' || _ => SkillRelationType.theory,
    };
  }
}

/// A directional or symmetric link to another skill.
class RelatedSkill {
  const RelatedSkill({
    required this.skillId,
    required this.relation,
    this.level,
  });

  factory RelatedSkill.fromMap(Map<String, dynamic> data) {
    return RelatedSkill(
      skillId: data['skillId'] as String? ?? '',
      relation: SkillRelationType.fromString(data['relation'] as String?),
      level: parseOptionalDifficulty(data['level'] as String?),
    );
  }

  final String skillId;
  final SkillRelationType relation;
  final DifficultyState? level;

  Map<String, Object?> toMap() {
    return {
      'skillId': skillId,
      'relation': relation.name,
      if (level != null) 'level': difficultyToKey(level!),
    };
  }
}

/// Educational sub-task or knowledge item within a difficulty level.
///
/// Components are never individually tracked for progress.
class SkillComponent {
  const SkillComponent({
    required this.title,
    required this.description,
  });

  factory SkillComponent.fromMap(Map<String, dynamic> data) {
    return SkillComponent(
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }

  final String title;
  final String description;

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'description': description,
    };
  }
}

/// Performance standard and educational guidance for one difficulty level.
class SkillLevelDefinition {
  const SkillLevelDefinition({
    required this.overview,
    this.components = const [],
    required this.learning,
    required this.proficient,
    this.standardVersion = 1,
    this.standardUpdatedAt,
  });

  factory SkillLevelDefinition.fromMap(Map<String, dynamic> data) {
    final rawComponents = data['components'] as List<dynamic>? ?? const [];
    return SkillLevelDefinition(
      overview: data['overview'] as String? ?? '',
      components: rawComponents
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => SkillComponent.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      learning: data['learning'] as String? ?? '',
      proficient: data['proficient'] as String? ?? '',
      standardVersion: (data['standardVersion'] as num?)?.toInt() ?? 1,
      standardUpdatedAt: parseFlexibleDateTime(data['standardUpdatedAt']),
    );
  }

  final String overview;
  final List<SkillComponent> components;
  final String learning;
  final String proficient;
  final int standardVersion;
  final DateTime? standardUpdatedAt;

  Map<String, Object?> toMap({bool preserveDateTime = false}) {
    return {
      'overview': overview,
      if (components.isNotEmpty)
        'components': components.map((c) => c.toMap()).toList(),
      'learning': learning,
      'proficient': proficient,
      'standardVersion': standardVersion,
      if (standardUpdatedAt != null)
        'standardUpdatedAt': preserveDateTime
            ? standardUpdatedAt
            : standardUpdatedAt!.toIso8601String(),
    };
  }
}

/// Skill Tree 2.0 canonical skill representing a meaningful ability with
/// 1 to 3 progressive [DifficultyState] standards.
class CurriculumSkill {
  const CurriculumSkill({
    required this.id,
    this.schemaVersion = 2,
    this.status = CurriculumSkillStatus.active,
    required this.subject,
    required this.realm,
    required this.familyId,
    required this.name,
    this.aliases = const [],
    required this.summary,
    required this.purpose,
    this.safety = const [],
    required this.availableLevels,
    required this.levels,
    this.relatedSkills = const [],
    this.legacyIds = const [],
    this.sortOrder = 0,
    this.replacedBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory CurriculumSkill.fromMap(Map<String, dynamic> data) {
    final rawAvailable = data['availableLevels'] as List<dynamic>? ?? const [];
    final available = rawAvailable
        .whereType<String>()
        .map(parseOptionalDifficulty)
        .whereType<DifficultyState>()
        .toList();

    final rawLevels = data['levels'] as Map<dynamic, dynamic>? ?? const {};
    final parsedLevels = <DifficultyState, SkillLevelDefinition>{};
    for (final entry in rawLevels.entries) {
      final level = parseOptionalDifficulty(entry.key as String?);
      if (level != null && entry.value is Map) {
        parsedLevels[level] = SkillLevelDefinition.fromMap(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    final rawRelated = data['relatedSkills'] as List<dynamic>? ?? const [];
    return CurriculumSkill(
      id: data['id'] as String? ?? '',
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 2,
      status: CurriculumSkillStatus.fromString(data['status'] as String?),
      subject: SkillSubject.fromString(data['subject'] as String?),
      realm: parseSkillRealm(data['realm'] as String?),
      familyId: data['familyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      aliases: (data['aliases'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      summary: data['summary'] as String? ?? '',
      purpose: data['purpose'] as String? ?? '',
      safety: (data['safety'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      availableLevels: available,
      levels: parsedLevels,
      relatedSkills: rawRelated
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => RelatedSkill.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      legacyIds: (data['legacyIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      replacedBy: data['replacedBy'] as String?,
      updatedAt: parseFlexibleDateTime(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  final String id;
  final int schemaVersion;
  final CurriculumSkillStatus status;
  final SkillSubject subject;
  final SkillCategory realm;
  final String familyId;
  final String name;
  final List<String> aliases;
  final String summary;
  final String purpose;
  final List<String> safety;
  final List<DifficultyState> availableLevels;
  final Map<DifficultyState, SkillLevelDefinition> levels;
  final List<RelatedSkill> relatedSkills;
  final List<String> legacyIds;
  final int sortOrder;
  final String? replacedBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  bool hasLevel(DifficultyState level) =>
      availableLevels.contains(level) && levels.containsKey(level);

  SkillLevelDefinition? levelDefinition(DifficultyState level) => levels[level];

  /// All skill IDs (canonical + legacy) that Resource `skillTreeIds` may match.
  List<String> get allResourceLookupIds => <String>[id, ...legacyIds];

  /// Accent- and case-insensitive match against name, aliases, and component titles.
  bool matchesQuery(String query) {
    final q = normalizeSearchText(query);
    if (q.isEmpty) return true;
    if (normalizeSearchText(name).contains(q)) return true;
    for (final alias in aliases) {
      if (normalizeSearchText(alias).contains(q)) return true;
    }
    for (final def in levels.values) {
      for (final c in def.components) {
        if (normalizeSearchText(c.title).contains(q)) return true;
      }
    }
    return false;
  }

  Map<String, Object?> toMap({bool preserveDateTime = false}) {
    return {
      'id': id,
      'schemaVersion': schemaVersion,
      'status': status.name,
      'subject': subject.toWireString(),
      'realm': Skill.categoryToString(realm),
      'familyId': familyId,
      'name': name,
      if (aliases.isNotEmpty) 'aliases': List<String>.from(aliases),
      'summary': summary,
      'purpose': purpose,
      if (safety.isNotEmpty) 'safety': List<String>.from(safety),
      'availableLevels': availableLevels.map(difficultyToKey).toList(),
      'levels': {
        for (final entry in levels.entries)
          difficultyToKey(entry.key):
              entry.value.toMap(preserveDateTime: preserveDateTime),
      },
      if (relatedSkills.isNotEmpty)
        'relatedSkills': relatedSkills.map((r) => r.toMap()).toList(),
      if (legacyIds.isNotEmpty) 'legacyIds': List<String>.from(legacyIds),
      'sortOrder': sortOrder,
      if (replacedBy != null) 'replacedBy': replacedBy,
      if (updatedAt != null)
        'updatedAt': preserveDateTime
            ? updatedAt
            : updatedAt!.toIso8601String(),
      if (updatedBy != null) 'updatedBy': updatedBy,
    };
  }
}

/// Wire key for a difficulty level (`introductory`, `intermediate`, `advanced`).
String difficultyToKey(DifficultyState level) {
  return switch (level) {
    DifficultyState.Introductory => 'introductory',
    DifficultyState.Intermediate => 'intermediate',
    DifficultyState.Advanced => 'advanced',
    DifficultyState.All => 'introductory',
  };
}

/// Parses a difficulty level string (case-insensitive). Returns null for unknown/all.
DifficultyState? parseOptionalDifficulty(String? value) {
  return switch (value?.toLowerCase()) {
    'introductory' => DifficultyState.Introductory,
    'intermediate' => DifficultyState.Intermediate,
    'advanced' => DifficultyState.Advanced,
    _ => null,
  };
}

/// Parses DateTime from ISO string, epoch ms, or DateTime (Firestore Timestamps
/// are converted in the mapper layer before calling `fromMap`).
DateTime? parseFlexibleDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

/// Lowercase + basic diacritic folding for accent-insensitive search.
String normalizeSearchText(String input) {
  const replacements = {
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  final lower = input.toLowerCase().trim();
  final buf = StringBuffer();
  for (var i = 0; i < lower.length; i++) {
    final ch = lower[i];
    buf.write(replacements[ch] ?? ch);
  }
  return buf.toString();
}
