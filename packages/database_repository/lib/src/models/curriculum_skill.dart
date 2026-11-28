// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:database_repository/src/models/skill.dart';
import 'package:database_repository/src/models/skill_family.dart';
import 'package:flutter/foundation.dart';

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

/// Non-assessed practical exercise helping develop a [CurriculumSkill].
///
/// Exercises are purely educational and adaptable; they never affect
/// proficiency state, difficulty standards, or instructor verification.
@immutable
class SkillPracticeExercise {
  const SkillPracticeExercise({
    this.badge,
    required this.title,
    required this.summary,
    this.whatToNotice,
    this.focusLevel,
  });

  factory SkillPracticeExercise.fromMap(Map<String, dynamic> data) {
    final badgeRaw = (data['badge'] as String?)?.trim();
    final noticeRaw = (data['whatToNotice'] as String?)?.trim();
    return SkillPracticeExercise(
      badge: badgeRaw != null && badgeRaw.isNotEmpty ? badgeRaw : null,
      title: (data['title'] as String? ?? '').trim(),
      summary: (data['summary'] as String? ?? '').trim(),
      whatToNotice:
          noticeRaw != null && noticeRaw.isNotEmpty ? noticeRaw : null,
      focusLevel: parseOptionalDifficulty(data['focusLevel'] as String?),
    );
  }

  final String? badge;
  final String title;
  final String summary;
  final String? whatToNotice;
  final DifficultyState? focusLevel;

  Map<String, Object?> toMap() {
    final cleanBadge = badge?.trim();
    final cleanNotice = whatToNotice?.trim();
    return {
      if (cleanBadge != null && cleanBadge.isNotEmpty) 'badge': cleanBadge,
      'title': title.trim(),
      'summary': summary.trim(),
      if (cleanNotice != null && cleanNotice.isNotEmpty)
        'whatToNotice': cleanNotice,
      if (focusLevel != null) 'focusLevel': difficultyToKey(focusLevel!),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillPracticeExercise &&
        (badge ?? '').trim() == (other.badge ?? '').trim() &&
        title.trim() == other.title.trim() &&
        summary.trim() == other.summary.trim() &&
        (whatToNotice ?? '').trim() == (other.whatToNotice ?? '').trim() &&
        focusLevel == other.focusLevel;
  }

  @override
  int get hashCode => Object.hash(
    (badge ?? '').trim(),
    title.trim(),
    summary.trim(),
    (whatToNotice ?? '').trim(),
    focusLevel,
  );
}

/// Typical difficulty or misunderstanding with a calm, humane adjustment.
@immutable
class SkillCommonDifficulty {
  const SkillCommonDifficulty({
    required this.issue,
    required this.guidance,
  });

  factory SkillCommonDifficulty.fromMap(Map<String, dynamic> data) {
    return SkillCommonDifficulty(
      issue: (data['issue'] as String? ?? '').trim(),
      guidance: (data['guidance'] as String? ?? '').trim(),
    );
  }

  final String issue;
  final String guidance;

  Map<String, Object?> toMap() {
    return {
      'issue': issue.trim(),
      'guidance': guidance.trim(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SkillCommonDifficulty &&
        issue.trim() == other.issue.trim() &&
        guidance.trim() == other.guidance.trim();
  }

  @override
  int get hashCode => Object.hash(issue.trim(), guidance.trim());
}

/// Optional non-assessed "Develop This Skill" learning guidance attached to a
/// [CurriculumSkill].
@immutable
class SkillLearningGuide {
  const SkillLearningGuide({
    this.exercises = const [],
    this.commonDifficulties = const [],
    this.trainerInsight,
    this.welfareNote,
    this.relatedDictionaryTerms = const [],
    this.relatedSkillIds = const [],
  });

  static SkillLearningGuide? fromMapOrNull(Object? raw) {
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    final rawExercises = data['exercises'] as List<dynamic>? ?? const [];
    final exercises = rawExercises
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (e) => SkillPracticeExercise.fromMap(Map<String, dynamic>.from(e)),
        )
        .where((e) => e.title.isNotEmpty || e.summary.isNotEmpty)
        .toList();

    final rawDifficulties =
        data['commonDifficulties'] as List<dynamic>? ?? const [];
    final commonDifficulties = rawDifficulties
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (d) => SkillCommonDifficulty.fromMap(Map<String, dynamic>.from(d)),
        )
        .where((d) => d.issue.isNotEmpty || d.guidance.isNotEmpty)
        .toList();

    final insightRaw = (data['trainerInsight'] as String?)?.trim();
    final welfareRaw = (data['welfareNote'] as String?)?.trim();

    final dictionaryTerms =
        (data['relatedDictionaryTerms'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final relatedIds = (data['relatedSkillIds'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final guide = SkillLearningGuide(
      exercises: exercises,
      commonDifficulties: commonDifficulties,
      trainerInsight:
          insightRaw != null && insightRaw.isNotEmpty ? insightRaw : null,
      welfareNote:
          welfareRaw != null && welfareRaw.isNotEmpty ? welfareRaw : null,
      relatedDictionaryTerms: dictionaryTerms,
      relatedSkillIds: relatedIds,
    );
    return guide.hasContent ? guide : null;
  }

  final List<SkillPracticeExercise> exercises;
  final List<SkillCommonDifficulty> commonDifficulties;
  final String? trainerInsight;
  final String? welfareNote;
  final List<String> relatedDictionaryTerms;
  final List<String> relatedSkillIds;

  bool get hasExercises => exercises.isNotEmpty;
  bool get hasCommonDifficulties => commonDifficulties.isNotEmpty;
  bool get hasTrainerInsight =>
      trainerInsight != null && trainerInsight!.trim().isNotEmpty;
  bool get hasWelfareNote =>
      welfareNote != null && welfareNote!.trim().isNotEmpty;
  bool get hasRelatedDictionaryTerms => relatedDictionaryTerms.isNotEmpty;
  bool get hasRelatedSkillIds => relatedSkillIds.isNotEmpty;
  bool get hasContent =>
      hasExercises ||
      hasCommonDifficulties ||
      hasTrainerInsight ||
      hasWelfareNote ||
      hasRelatedDictionaryTerms ||
      hasRelatedSkillIds;
  bool get isEmpty => !hasContent;

  Map<String, Object?> toMap() {
    final cleanInsight = trainerInsight?.trim();
    final cleanWelfare = welfareNote?.trim();
    final cleanTerms = relatedDictionaryTerms
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final cleanSkills = relatedSkillIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return {
      if (exercises.isNotEmpty)
        'exercises': exercises.map((e) => e.toMap()).toList(),
      if (commonDifficulties.isNotEmpty)
        'commonDifficulties':
            commonDifficulties.map((d) => d.toMap()).toList(),
      if (cleanInsight != null && cleanInsight.isNotEmpty)
        'trainerInsight': cleanInsight,
      if (cleanWelfare != null && cleanWelfare.isNotEmpty)
        'welfareNote': cleanWelfare,
      if (cleanTerms.isNotEmpty) 'relatedDictionaryTerms': cleanTerms,
      if (cleanSkills.isNotEmpty) 'relatedSkillIds': cleanSkills,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SkillLearningGuide) return false;
    if (exercises.length != other.exercises.length) return false;
    for (var i = 0; i < exercises.length; i++) {
      if (exercises[i] != other.exercises[i]) return false;
    }
    if (commonDifficulties.length != other.commonDifficulties.length) {
      return false;
    }
    for (var i = 0; i < commonDifficulties.length; i++) {
      if (commonDifficulties[i] != other.commonDifficulties[i]) return false;
    }
    if ((trainerInsight ?? '').trim() !=
        (other.trainerInsight ?? '').trim()) {
      return false;
    }
    if ((welfareNote ?? '').trim() != (other.welfareNote ?? '').trim()) {
      return false;
    }
    if (!_stringListsEqual(
      relatedDictionaryTerms,
      other.relatedDictionaryTerms,
    )) {
      return false;
    }
    return _stringListsEqual(relatedSkillIds, other.relatedSkillIds);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(exercises),
    Object.hashAll(commonDifficulties),
    (trainerInsight ?? '').trim(),
    (welfareNote ?? '').trim(),
    Object.hashAll(
      relatedDictionaryTerms.map((e) => e.trim()).where((e) => e.isNotEmpty),
    ),
    Object.hashAll(
      relatedSkillIds.map((e) => e.trim()).where((e) => e.isNotEmpty),
    ),
  );
}

bool _stringListsEqual(List<String> a, List<String> b) {
  final ca = a.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final cb = b.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (ca.length != cb.length) return false;
  for (var i = 0; i < ca.length; i++) {
    if (ca[i] != cb[i]) return false;
  }
  return true;
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
    this.learningGuide,
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
      learningGuide: SkillLearningGuide.fromMapOrNull(data['learningGuide']),
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
  final SkillLearningGuide? learningGuide;

  bool hasLevel(DifficultyState level) =>
      availableLevels.contains(level) && levels.containsKey(level);

  SkillLevelDefinition? levelDefinition(DifficultyState level) => levels[level];

  /// All skill IDs (canonical + legacy) that Resource `skillTreeIds` may match.
  List<String> get allResourceLookupIds => <String>[id, ...legacyIds];

  CurriculumSkill copyWith({
    String? id,
    int? schemaVersion,
    CurriculumSkillStatus? status,
    SkillSubject? subject,
    SkillCategory? realm,
    String? familyId,
    String? name,
    List<String>? aliases,
    String? summary,
    String? purpose,
    List<String>? safety,
    List<DifficultyState>? availableLevels,
    Map<DifficultyState, SkillLevelDefinition>? levels,
    List<RelatedSkill>? relatedSkills,
    List<String>? legacyIds,
    int? sortOrder,
    String? replacedBy,
    DateTime? updatedAt,
    String? updatedBy,
    SkillLearningGuide? learningGuide,
    bool clearLearningGuide = false,
  }) {
    return CurriculumSkill(
      id: id ?? this.id,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      status: status ?? this.status,
      subject: subject ?? this.subject,
      realm: realm ?? this.realm,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      summary: summary ?? this.summary,
      purpose: purpose ?? this.purpose,
      safety: safety ?? this.safety,
      availableLevels: availableLevels ?? this.availableLevels,
      levels: levels ?? this.levels,
      relatedSkills: relatedSkills ?? this.relatedSkills,
      legacyIds: legacyIds ?? this.legacyIds,
      sortOrder: sortOrder ?? this.sortOrder,
      replacedBy: replacedBy ?? this.replacedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      learningGuide: clearLearningGuide
          ? null
          : (learningGuide ?? this.learningGuide),
    );
  }

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
      if (learningGuide != null && learningGuide!.hasContent)
        'learningGuide': learningGuide!.toMap(),
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
