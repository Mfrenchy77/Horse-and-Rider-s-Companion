import 'dart:convert';

import 'package:database_repository/src/models/curriculum_skill.dart';
import 'package:database_repository/src/models/skill.dart';
import 'package:database_repository/src/models/skill_family.dart';

const int _maxFamilies = 100;
const int _maxSkills = 250;
const int _warnDraftDocBytes = 700 * 1024;
const int _maxDraftDocBytes = 900 * 1024;

final RegExp _docIdRegex = RegExp(r'^[A-Za-z0-9._-]{1,120}$');
final RegExp _dictionarySlugRegex = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

const Set<String> _validSubjects = {'rider', 'horse'};
const Set<String> _validRealms = {'Husbandry', 'In_Hand', 'Mounted', 'Other'};
const Map<String, Set<String>> _validRealmsBySubject = {
  'rider': {'Husbandry', 'In_Hand', 'Mounted', 'Other'},
  'horse': {'In_Hand', 'Mounted'},
};
const List<String> _levelOrder = ['introductory', 'intermediate', 'advanced'];
const Set<String> _validRelations = {
  'counterpart',
  'foundation',
  'next',
  'theory',
};
const Set<String> _validStatuses = {'draft', 'active', 'retired'};

/// Result of parsing and validating a canonical curriculum JSON import.
class CurriculumImportResult {
  /// Creates a [CurriculumImportResult].
  const CurriculumImportResult({
    this.families,
    this.skills,
    this.errors = const [],
    this.warnings = const [],
    this.totalLevels = 0,
    this.sizeBytes = 0,
  });

  /// Validated imported skill families, or `null` when validation failed.
  final List<SkillFamily>? families;

  /// Validated imported curriculum skills, or `null` when validation failed.
  final List<CurriculumSkill>? skills;

  /// Actionable validation errors preventing import.
  final List<String> errors;

  /// Non-blocking validation warnings (for example approaching size limit).
  final List<String> warnings;

  /// Count of difficulty-level standards across all imported skills.
  final int totalLevels;

  /// UTF-8 byte length of the serialized canonical curriculum payload.
  final int sizeBytes;

  /// Whether the import parsed cleanly with zero validation errors.
  bool get isValid => errors.isEmpty && families != null && skills != null;
}

/// Parses and validates canonical Skill Tree 2.0 import JSON matching the
/// backend `curriculum_validator.js` contract and export schema.
CurriculumImportResult parseAndValidateCurriculumImportJson(
  String rawJson, {
  List<SkillFamily> publishedFamilies = const [],
  List<CurriculumSkill> publishedSkills = const [],
  bool enforceSizeLimit = true,
}) {
  final trimmed = rawJson.trim();
  if (trimmed.isEmpty) {
    return const CurriculumImportResult(
      errors: ['Curriculum JSON is empty. Upload a JSON file or paste JSON.'],
    );
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(trimmed);
  } on FormatException catch (e) {
    return CurriculumImportResult(errors: ['Malformed JSON: ${e.message}']);
  }

  if (decoded is! Map<dynamic, dynamic>) {
    const message =
        'Curriculum import root must be a JSON object with '
        '"schemaVersion", "families", and "skills".';
    return const CurriculumImportResult(errors: [message]);
  }

  final root = Map<String, dynamic>.from(decoded);
  final errors = <String>[];
  final warnings = <String>[];

  final schemaVersion = root['schemaVersion'];
  if (schemaVersion != 2) {
    errors.add('Root schemaVersion must equal 2.');
  }

  final rawFamilies = root['families'];
  final rawSkills = root['skills'];

  if (rawFamilies is! List<dynamic>) {
    errors.add('families must be an array of at most $_maxFamilies entries.');
  } else if (rawFamilies.length > _maxFamilies) {
    errors.add('families must contain at most $_maxFamilies entries.');
  }

  if (rawSkills is! List<dynamic>) {
    errors.add('skills must be an array of at most $_maxSkills entries.');
  } else if (rawSkills.length > _maxSkills) {
    errors.add('skills must contain at most $_maxSkills entries.');
  }

  final parsedFamilies = <SkillFamily>[];
  if (rawFamilies is List<dynamic>) {
    final limit = rawFamilies.length < _maxFamilies
        ? rawFamilies.length
        : _maxFamilies;
    for (var i = 0; i < limit; i++) {
      final fam = _validateFamily(rawFamilies[i], i, errors);
      if (fam != null) parsedFamilies.add(fam);
    }
  }

  final parsedSkills = <CurriculumSkill>[];
  if (rawSkills is List<dynamic>) {
    final limit = rawSkills.length < _maxSkills ? rawSkills.length : _maxSkills;
    for (var i = 0; i < limit; i++) {
      final skill = _validateSkill(rawSkills[i], i, errors);
      if (skill != null) parsedSkills.add(skill);
    }
  }

  final graph = _validateGraphAndReferences(
    parsedFamilies,
    parsedSkills,
    errors,
  );

  _validatePublishedPreservation(graph.skillMap, publishedSkills, errors);

  // Reserved to mirror publishedFamilies parameter symmetry with backend.
  if (publishedFamilies.isEmpty) {
    // No family deletion constraint enforced in Phase 2B.
  }

  final payloadBytes = utf8
      .encode(
        jsonEncode({
          'schemaVersion': 2,
          'families': parsedFamilies.map((f) => f.toMap()).toList(),
          'skills': parsedSkills.map((s) => s.toMap()).toList(),
        }),
      )
      .length;

  if (payloadBytes > _warnDraftDocBytes) {
    final sizeKb = (payloadBytes / 1024).round();
    warnings.add(
      "Draft payload size ($sizeKb KB) is approaching Firestore's "
      '1 MiB document limit.',
    );
  }
  if (enforceSizeLimit && payloadBytes > _maxDraftDocBytes) {
    final sizeKb = (payloadBytes / 1024).round();
    final limitKb = (_maxDraftDocBytes / 1024).round();
    errors.add(
      'Draft payload size ($sizeKb KB) exceeds safe single-document limit '
      '($limitKb KB).',
    );
  }

  if (errors.isNotEmpty) {
    return CurriculumImportResult(
      errors: List<String>.unmodifiable(errors),
      warnings: List<String>.unmodifiable(warnings),
      totalLevels: graph.totalLevels,
      sizeBytes: payloadBytes,
    );
  }

  return CurriculumImportResult(
    families: List<SkillFamily>.unmodifiable(parsedFamilies),
    skills: List<CurriculumSkill>.unmodifiable(parsedSkills),
    warnings: List<String>.unmodifiable(warnings),
    totalLevels: graph.totalLevels,
    sizeBytes: payloadBytes,
  );
}

String? _checkId(Object? value, String label, List<String> errors) {
  if (value is! String || !_docIdRegex.hasMatch(value.trim())) {
    errors.add('$label is invalid.');
    return null;
  }
  return value.trim();
}

String? _checkRequiredString(
  Object? value,
  int maxLen,
  String label,
  List<String> errors,
) {
  if (value is! String || value.trim().isEmpty) {
    errors.add('$label is required.');
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.length > maxLen) {
    errors.add('$label must be $maxLen characters or fewer.');
    return null;
  }
  return trimmed;
}

String? _checkOptionalString(
  Object? value,
  int maxLen,
  String label,
  List<String> errors,
) {
  if (value == null) return '';
  if (value is! String) {
    errors.add('$label must be a string.');
    return null;
  }
  final trimmed = value.trim();
  if (trimmed.length > maxLen) {
    errors.add('$label must be $maxLen characters or fewer.');
    return null;
  }
  return trimmed;
}

String? _checkEnum(
  Object? value,
  Set<String> allowed,
  String label,
  List<String> errors,
) {
  if (value is! String || !allowed.contains(value)) {
    errors.add('Invalid $label: "$value".');
    return null;
  }
  return value;
}

List<String> _checkStringList(
  Object? value,
  int maxItems,
  int maxItemLen,
  String label,
  List<String> errors, {
  bool allowEmptyItems = true,
}) {
  if (value == null) return const [];
  if (value is! List<dynamic>) {
    errors.add('$label must be an array.');
    return const [];
  }
  if (value.length > maxItems) {
    errors.add('$label must contain at most $maxItems items.');
  }
  final result = <String>[];
  final limit = value.length < maxItems ? value.length : maxItems;
  for (var i = 0; i < limit; i++) {
    final item = value[i];
    if (item is! String) {
      errors.add('$label[$i] must be a string.');
      continue;
    }
    final trimmed = item.trim();
    if (trimmed.isEmpty) {
      if (!allowEmptyItems) {
        errors.add('$label[$i] must not be empty.');
      }
      continue;
    }
    if (trimmed.length > maxItemLen) {
      errors.add('$label[$i] exceeds $maxItemLen characters.');
      continue;
    }
    result.add(trimmed);
  }
  return result;
}

DateTime? _parseOptionalTimestamp(
  Object? value,
  String label,
  List<String> errors,
) {
  if (value == null || value == '') return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    final trimmed = value.trim();
    final parsed = trimmed.isEmpty ? null : DateTime.tryParse(trimmed);
    if (parsed == null) {
      errors.add('$label must be a valid ISO timestamp.');
      return null;
    }
    return parsed.toUtc();
  }
  errors.add('$label must be a valid timestamp.');
  return null;
}

SkillFamily? _validateFamily(Object? rawValue, int index, List<String> errors) {
  final prefix = 'families[$index]';
  if (rawValue is! Map<dynamic, dynamic>) {
    errors.add('$prefix must be an object.');
    return null;
  }
  final raw = Map<String, dynamic>.from(rawValue);
  final id = _checkId(raw['id'], '$prefix.id', errors);
  final label = id ?? prefix;

  final schemaVersion = raw['schemaVersion'];
  if (schemaVersion != null && schemaVersion != 2) {
    errors.add('Family $label: schemaVersion must be 2.');
  }

  final subject = _checkEnum(
    raw['subject'],
    _validSubjects,
    '$label.subject',
    errors,
  );
  final realm = _checkEnum(raw['realm'], _validRealms, '$label.realm', errors);
  if (subject != null &&
      realm != null &&
      !(_validRealmsBySubject[subject]?.contains(realm) ?? false)) {
    errors.add(
      'Family $label: invalid subject/realm combination $subject/$realm.',
    );
  }

  final name = _checkRequiredString(
    raw['name'],
    120,
    'Family $label.name',
    errors,
  );
  final description = _checkOptionalString(
    raw['description'],
    1000,
    'Family $label.description',
    errors,
  );

  var sortOrder = 0;
  final rawSortOrder = raw['sortOrder'];
  if (rawSortOrder != null) {
    if (rawSortOrder is! int) {
      errors.add('Family $label.sortOrder must be an integer.');
    } else {
      sortOrder = rawSortOrder;
    }
  }

  if (id == null ||
      subject == null ||
      realm == null ||
      name == null ||
      description == null) {
    return null;
  }

  return SkillFamily(
    id: id,
    subject: SkillSubject.fromString(subject),
    realm: parseSkillRealm(realm),
    name: name,
    description: description,
    sortOrder: sortOrder,
  );
}

SkillLevelDefinition? _validateLevel(
  Object? rawValue,
  String skillLabel,
  String levelKey,
  List<String> errors,
) {
  final prefix = '$skillLabel.levels.$levelKey';
  if (rawValue is! Map<dynamic, dynamic>) {
    errors.add('$prefix must be an object.');
    return null;
  }
  final raw = Map<String, dynamic>.from(rawValue);
  final overview = _checkRequiredString(
    raw['overview'],
    1000,
    '$prefix.overview',
    errors,
  );
  final learning = _checkRequiredString(
    raw['learning'],
    1000,
    '$prefix.learning',
    errors,
  );
  final proficient = _checkRequiredString(
    raw['proficient'],
    1000,
    '$prefix.proficient',
    errors,
  );

  final components = <SkillComponent>[];
  final rawComponents = raw['components'];
  if (rawComponents != null) {
    if (rawComponents is! List<dynamic>) {
      errors.add('$prefix.components must be an array.');
    } else {
      if (rawComponents.length > 20) {
        errors.add('$prefix.components must contain at most 20 items.');
      }
      final limit = rawComponents.length < 20 ? rawComponents.length : 20;
      for (var i = 0; i < limit; i++) {
        final rawComp = rawComponents[i];
        if (rawComp is! Map<dynamic, dynamic>) {
          errors.add('$prefix.components[$i] must be an object.');
          continue;
        }
        final comp = Map<String, dynamic>.from(rawComp);
        final title = _checkRequiredString(
          comp['title'],
          120,
          '$prefix.components[$i].title',
          errors,
        );
        final description = _checkOptionalString(
          comp['description'],
          1000,
          '$prefix.components[$i].description',
          errors,
        );
        if (title != null && description != null) {
          components.add(
            SkillComponent(title: title, description: description),
          );
        }
      }
    }
  }

  var standardVersion = 1;
  final rawVer = raw['standardVersion'];
  if (rawVer != null) {
    if (rawVer is! int || rawVer < 1) {
      errors.add('$prefix.standardVersion must be an integer >= 1.');
    } else {
      standardVersion = rawVer;
    }
  }

  final standardUpdatedAt = _parseOptionalTimestamp(
    raw['standardUpdatedAt'],
    '$prefix.standardUpdatedAt',
    errors,
  );

  if (overview == null || learning == null || proficient == null) {
    return null;
  }

  return SkillLevelDefinition(
    overview: overview,
    components: components,
    learning: learning,
    proficient: proficient,
    standardVersion: standardVersion,
    standardUpdatedAt: standardUpdatedAt,
  );
}

SkillLearningGuide? _validateLearningGuide(
  Object? rawValue,
  String? skillId,
  String label,
  List<String> errors,
) {
  if (rawValue == null) return null;
  final prefix = '$label.learningGuide';
  if (rawValue is! Map<dynamic, dynamic>) {
    errors.add('Skill $prefix must be an object.');
    return null;
  }
  final raw = Map<String, dynamic>.from(rawValue);

  final exercises = <SkillPracticeExercise>[];
  final rawExercises = raw['exercises'];
  if (rawExercises != null) {
    if (rawExercises is! List<dynamic>) {
      errors.add('Skill $prefix.exercises must be an array.');
    } else {
      if (rawExercises.length > 4) {
        errors.add(
          'Skill $prefix.exercises must contain at most 4 items.',
        );
      }
      final limit = rawExercises.length < 4 ? rawExercises.length : 4;
      for (var i = 0; i < limit; i++) {
        final item = rawExercises[i];
        if (item is! Map<dynamic, dynamic>) {
          errors.add('Skill $prefix.exercises[$i] must be an object.');
          continue;
        }
        final ex = Map<String, dynamic>.from(item);
        final badgeRaw = ex['badge'] == null
            ? ''
            : _checkOptionalString(
                ex['badge'],
                60,
                '$prefix.exercises[$i].badge',
                errors,
              );
        final title = _checkRequiredString(
          ex['title'],
          120,
          '$prefix.exercises[$i].title',
          errors,
        );
        final summary = _checkRequiredString(
          ex['summary'],
          600,
          '$prefix.exercises[$i].summary',
          errors,
        );
        final whatToNoticeRaw = ex['whatToNotice'] == null
            ? ''
            : _checkOptionalString(
                ex['whatToNotice'],
                400,
                '$prefix.exercises[$i].whatToNotice',
                errors,
              );
        DifficultyState? focusLevel;
        if (ex['focusLevel'] != null) {
          final focusKey = _checkEnum(
            ex['focusLevel'],
            _levelOrder.toSet(),
            '$prefix.exercises[$i].focusLevel',
            errors,
          );
          if (focusKey != null) {
            focusLevel = parseOptionalDifficulty(focusKey);
          }
        }
        if (title != null && summary != null) {
          exercises.add(
            SkillPracticeExercise(
              badge: badgeRaw != null && badgeRaw.isNotEmpty ? badgeRaw : null,
              title: title,
              summary: summary,
              whatToNotice:
                  whatToNoticeRaw != null && whatToNoticeRaw.isNotEmpty
                  ? whatToNoticeRaw
                  : null,
              focusLevel: focusLevel,
            ),
          );
        }
      }
    }
  }

  final commonDifficulties = <SkillCommonDifficulty>[];
  final rawDifficulties = raw['commonDifficulties'];
  if (rawDifficulties != null) {
    if (rawDifficulties is! List<dynamic>) {
      errors.add('Skill $prefix.commonDifficulties must be an array.');
    } else {
      if (rawDifficulties.length > 6) {
        errors.add(
          'Skill $prefix.commonDifficulties must contain at most 6 items.',
        );
      }
      final limit = rawDifficulties.length < 6 ? rawDifficulties.length : 6;
      for (var i = 0; i < limit; i++) {
        final item = rawDifficulties[i];
        if (item is! Map<dynamic, dynamic>) {
          errors.add('Skill $prefix.commonDifficulties[$i] must be an object.');
          continue;
        }
        final diff = Map<String, dynamic>.from(item);
        final issue = _checkRequiredString(
          diff['issue'],
          140,
          '$prefix.commonDifficulties[$i].issue',
          errors,
        );
        final guidance = _checkRequiredString(
          diff['guidance'],
          400,
          '$prefix.commonDifficulties[$i].guidance',
          errors,
        );
        if (issue != null && guidance != null) {
          commonDifficulties.add(
            SkillCommonDifficulty(issue: issue, guidance: guidance),
          );
        }
      }
    }
  }

  final trainerInsightRaw = raw['trainerInsight'] == null
      ? ''
      : _checkOptionalString(
          raw['trainerInsight'],
          400,
          '$prefix.trainerInsight',
          errors,
        );
  final welfareNoteRaw = raw['welfareNote'] == null
      ? ''
      : _checkOptionalString(
          raw['welfareNote'],
          500,
          '$prefix.welfareNote',
          errors,
        );

  final dictionaryTerms = <String>[];
  final rawTerms = raw['relatedDictionaryTerms'];
  if (rawTerms != null) {
    if (rawTerms is! List<dynamic>) {
      errors.add('Skill $prefix.relatedDictionaryTerms must be an array.');
    } else {
      if (rawTerms.length > 8) {
        errors.add(
          'Skill $prefix.relatedDictionaryTerms must contain at most 8 items.',
        );
      }
      final seen = <String>{};
      final limit = rawTerms.length < 8 ? rawTerms.length : 8;
      for (var i = 0; i < limit; i++) {
        final item = rawTerms[i];
        if (item is! String) {
          errors.add('$prefix.relatedDictionaryTerms[$i] must be a string.');
          continue;
        }
        final slug = item.trim();
        if (slug.isEmpty) continue;
        if (slug.length > 100 || !_dictionarySlugRegex.hasMatch(slug)) {
          errors.add(
            '$prefix.relatedDictionaryTerms[$i] must be a valid Dictionary '
            'slug (e.g. "half-halt").',
          );
          continue;
        }
        if (seen.add(slug)) dictionaryTerms.add(slug);
      }
    }
  }

  final relatedIds = <String>[];
  final rawRelatedIds = raw['relatedSkillIds'];
  if (rawRelatedIds != null) {
    if (rawRelatedIds is! List<dynamic>) {
      errors.add('Skill $prefix.relatedSkillIds must be an array.');
    } else {
      if (rawRelatedIds.length > 8) {
        errors.add(
          'Skill $prefix.relatedSkillIds must contain at most 8 items.',
        );
      }
      final seen = <String>{};
      final limit = rawRelatedIds.length < 8 ? rawRelatedIds.length : 8;
      for (var i = 0; i < limit; i++) {
        final targetId = _checkId(
          rawRelatedIds[i],
          '$prefix.relatedSkillIds[$i]',
          errors,
        );
        if (targetId == null) continue;
        if (skillId != null && targetId == skillId) {
          errors.add('Skill $prefix.relatedSkillIds cannot reference itself.');
          continue;
        }
        if (seen.add(targetId)) relatedIds.add(targetId);
      }
    }
  }

  final guide = SkillLearningGuide(
    exercises: exercises,
    commonDifficulties: commonDifficulties,
    trainerInsight:
        trainerInsightRaw != null && trainerInsightRaw.isNotEmpty
        ? trainerInsightRaw
        : null,
    welfareNote:
        welfareNoteRaw != null && welfareNoteRaw.isNotEmpty
        ? welfareNoteRaw
        : null,
    relatedDictionaryTerms: dictionaryTerms,
    relatedSkillIds: relatedIds,
  );
  return guide.hasContent ? guide : null;
}

CurriculumSkill? _validateSkill(
  Object? rawValue,
  int index,
  List<String> errors,
) {
  final prefix = 'skills[$index]';
  if (rawValue is! Map<dynamic, dynamic>) {
    errors.add('$prefix must be an object.');
    return null;
  }
  final raw = Map<String, dynamic>.from(rawValue);
  final id = _checkId(raw['id'], '$prefix.id', errors);
  final label = id ?? prefix;

  final schemaVersion = raw['schemaVersion'];
  if (schemaVersion != null && schemaVersion != 2) {
    errors.add('Skill $label: schemaVersion must be 2.');
  }

  final statusStr = raw['status'] == null
      ? 'active'
      : _checkEnum(raw['status'], _validStatuses, '$label.status', errors);
  final subjectStr = _checkEnum(
    raw['subject'],
    _validSubjects,
    '$label.subject',
    errors,
  );
  final realmStr = _checkEnum(
    raw['realm'],
    _validRealms,
    '$label.realm',
    errors,
  );
  if (subjectStr != null &&
      realmStr != null &&
      !(_validRealmsBySubject[subjectStr]?.contains(realmStr) ?? false)) {
    errors.add(
      'Skill $label: invalid subject/realm combination '
      '$subjectStr/$realmStr.',
    );
  }

  final familyId = _checkId(raw['familyId'], '$label.familyId', errors);
  final name = _checkRequiredString(
    raw['name'],
    120,
    'Skill $label.name',
    errors,
  );
  final summary = _checkRequiredString(
    raw['summary'],
    1000,
    'Skill $label.summary',
    errors,
  );
  final purpose = _checkRequiredString(
    raw['purpose'],
    1000,
    'Skill $label.purpose',
    errors,
  );
  final aliases = _checkStringList(
    raw['aliases'],
    20,
    120,
    '$label.aliases',
    errors,
  );
  final safety = _checkStringList(
    raw['safety'],
    15,
    400,
    '$label.safety',
    errors,
  );
  final legacyIds = _checkStringList(
    raw['legacyIds'],
    20,
    120,
    '$label.legacyIds',
    errors,
    allowEmptyItems: false,
  );

  final availableLevelKeys = <String>[];
  final availableLevels = <DifficultyState>[];
  final rawAvailable = raw['availableLevels'];
  if (rawAvailable is! List<dynamic> ||
      rawAvailable.isEmpty ||
      rawAvailable.length > 3) {
    errors.add('Skill $label.availableLevels must contain 1 to 3 levels.');
  } else {
    var lastOrder = -1;
    final seen = <String>{};
    for (final rawLvl in rawAvailable) {
      final validKey = _checkEnum(
        rawLvl,
        _levelOrder.toSet(),
        '$label.availableLevels',
        errors,
      );
      if (validKey == null) continue;
      if (!seen.add(validKey)) {
        errors.add(
          'Skill $label.availableLevels contains duplicate level "$validKey".',
        );
        continue;
      }
      final orderIdx = _levelOrder.indexOf(validKey);
      if (orderIdx <= lastOrder) {
        errors.add(
          'Skill $label.availableLevels must follow '
          'introductory -> intermediate -> advanced order.',
        );
      }
      lastOrder = orderIdx;
      availableLevelKeys.add(validKey);
      final difficulty = parseOptionalDifficulty(validKey);
      if (difficulty != null) availableLevels.add(difficulty);
    }
  }

  final levelsMap = <DifficultyState, SkillLevelDefinition>{};
  final rawLevels = raw['levels'];
  if (rawLevels is! Map<dynamic, dynamic>) {
    errors.add('Skill $label.levels must be an object.');
  } else {
    for (final key in rawLevels.keys) {
      if (key is! String || !_levelOrder.contains(key)) {
        errors.add('Skill $label.levels contains invalid level key "$key".');
      } else if (!availableLevelKeys.contains(key)) {
        errors.add(
          'Skill $label.levels defines "$key", '
          'which is missing from availableLevels.',
        );
      }
    }
    for (final lvlKey in availableLevelKeys) {
      if (!rawLevels.containsKey(lvlKey)) {
        errors.add('Skill $label.levels is missing definition for "$lvlKey".');
        continue;
      }
      final def = _validateLevel(rawLevels[lvlKey], label, lvlKey, errors);
      final difficulty = parseOptionalDifficulty(lvlKey);
      if (def != null && difficulty != null) {
        levelsMap[difficulty] = def;
      }
    }
  }

  final relatedSkills = <RelatedSkill>[];
  final rawRelated = raw['relatedSkills'];
  if (rawRelated != null) {
    if (rawRelated is! List<dynamic>) {
      errors.add('Skill $label.relatedSkills must be an array.');
    } else {
      if (rawRelated.length > 20) {
        errors.add(
          'Skill $label.relatedSkills must contain at most 20 entries.',
        );
      }
      final seenPairs = <String>{};
      final limit = rawRelated.length < 20 ? rawRelated.length : 20;
      for (var i = 0; i < limit; i++) {
        final rawRel = rawRelated[i];
        if (rawRel is! Map<dynamic, dynamic>) {
          errors.add('$label.relatedSkills[$i] must be an object.');
          continue;
        }
        final rel = Map<String, dynamic>.from(rawRel);
        final targetId = _checkId(
          rel['skillId'],
          '$label.relatedSkills[$i].skillId',
          errors,
        );
        final relationKey = _checkEnum(
          rel['relation'],
          _validRelations,
          '$label.relatedSkills[$i].relation',
          errors,
        );
        DifficultyState? relLevel;
        if (rel['level'] != null) {
          final levelKey = _checkEnum(
            rel['level'],
            _levelOrder.toSet(),
            '$label.relatedSkills[$i].level',
            errors,
          );
          if (levelKey != null) {
            relLevel = parseOptionalDifficulty(levelKey);
          }
        }
        if (targetId == null || relationKey == null) continue;
        if (id != null && targetId == id) {
          errors.add('Skill $label cannot reference itself in relatedSkills.');
          continue;
        }
        final pairKey = '$targetId:$relationKey';
        if (!seenPairs.add(pairKey)) {
          errors.add(
            'Skill $label contains duplicate $relationKey link to $targetId.',
          );
          continue;
        }
        relatedSkills.add(
          RelatedSkill(
            skillId: targetId,
            relation: SkillRelationType.fromString(relationKey),
            level: relLevel,
          ),
        );
      }
    }
  }

  var sortOrder = 0;
  final rawSortOrder = raw['sortOrder'];
  if (rawSortOrder != null) {
    if (rawSortOrder is! int) {
      errors.add('Skill $label.sortOrder must be an integer.');
    } else {
      sortOrder = rawSortOrder;
    }
  }

  String? replacedBy;
  final rawReplacedBy = raw['replacedBy'];
  if (rawReplacedBy != null && rawReplacedBy != '') {
    replacedBy = _checkId(rawReplacedBy, '$label.replacedBy', errors);
    if (replacedBy != null && id != null && replacedBy == id) {
      errors.add('Skill $label.replacedBy cannot reference itself.');
    }
    if (statusStr != null && statusStr != 'retired') {
      errors.add(
        'Skill $label: replacedBy is only allowed when status is "retired".',
      );
    }
  }

  final updatedAt = _parseOptionalTimestamp(
    raw['updatedAt'],
    '$label.updatedAt',
    errors,
  );
  final updatedBy = raw['updatedBy'] == null
      ? null
      : _checkOptionalString(raw['updatedBy'], 120, '$label.updatedBy', errors);
  final learningGuide = _validateLearningGuide(
    raw['learningGuide'],
    id,
    label,
    errors,
  );

  if (id == null ||
      statusStr == null ||
      subjectStr == null ||
      realmStr == null ||
      familyId == null ||
      name == null ||
      summary == null ||
      purpose == null) {
    return null;
  }

  return CurriculumSkill(
    id: id,
    status: CurriculumSkillStatus.fromString(statusStr),
    subject: SkillSubject.fromString(subjectStr),
    realm: parseSkillRealm(realmStr),
    familyId: familyId,
    name: name,
    aliases: aliases,
    summary: summary,
    purpose: purpose,
    safety: safety,
    availableLevels: availableLevels,
    levels: levelsMap,
    relatedSkills: relatedSkills,
    legacyIds: legacyIds,
    sortOrder: sortOrder,
    replacedBy: replacedBy,
    updatedAt: updatedAt,
    updatedBy: updatedBy != null && updatedBy.isEmpty ? null : updatedBy,
    learningGuide: learningGuide,
  );
}

({Map<String, CurriculumSkill> skillMap, int totalLevels})
_validateGraphAndReferences(
  List<SkillFamily> families,
  List<CurriculumSkill> skills,
  List<String> errors,
) {
  final familyMap = <String, SkillFamily>{};
  for (final f in families) {
    if (familyMap.containsKey(f.id)) {
      errors.add('Duplicate family ID: ${f.id}.');
      continue;
    }
    familyMap[f.id] = f;
  }

  final skillMap = <String, CurriculumSkill>{};
  final legacySeen = <String, String>{};
  var totalLevels = 0;

  for (final s in skills) {
    if (skillMap.containsKey(s.id)) {
      errors.add('Duplicate skill ID: ${s.id}.');
      continue;
    }
    skillMap[s.id] = s;
    totalLevels += s.availableLevels.length;

    final fam = familyMap[s.familyId];
    if (fam == null) {
      errors.add('Skill ${s.id}: unknown familyId "${s.familyId}".');
    } else if (fam.subject != s.subject || fam.realm != s.realm) {
      errors.add(
        'Skill ${s.id}: family "${s.familyId}" subject/realm '
        '(${fam.subject.toWireString()}/${Skill.categoryToString(fam.realm)}) '
        'does not match skill '
        '(${s.subject.toWireString()}/${Skill.categoryToString(s.realm)}).',
      );
    }

    for (final oldId in s.legacyIds) {
      final previousSkill = legacySeen[oldId];
      if (previousSkill != null) {
        errors.add(
          'Legacy ID "$oldId" mapped twice: $previousSkill and ${s.id}.',
        );
      } else {
        legacySeen[oldId] = s.id;
      }
    }
  }

  for (final s in skillMap.values) {
    final replacedBy = s.replacedBy;
    if (replacedBy != null) {
      final replacement = skillMap[replacedBy];
      if (replacement == null) {
        errors.add('Skill ${s.id}: replacedBy target "$replacedBy" not found.');
      } else {
        if (replacement.status != CurriculumSkillStatus.active) {
          errors.add(
            'Skill ${s.id}: replacedBy target "$replacedBy" '
            'must have status "active".',
          );
        }
        if (replacement.subject != s.subject) {
          errors.add(
            'Skill ${s.id}: replacedBy target "$replacedBy" subject '
            '(${replacement.subject.toWireString()}) must match '
            'retired skill subject (${s.subject.toWireString()}).',
          );
        }
      }
    }

    for (final rel in s.relatedSkills) {
      final target = skillMap[rel.skillId];
      if (target == null) {
        errors.add('Skill ${s.id}: relatedSkill "${rel.skillId}" not found.');
        continue;
      }
      if (rel.relation == SkillRelationType.counterpart) {
        if (target.subject == s.subject) {
          errors.add(
            'Skill ${s.id}: counterpart "${rel.skillId}" '
            'must be opposite subject.',
          );
        }
        final reverse = target.relatedSkills.any(
          (r) =>
              r.skillId == s.id && r.relation == SkillRelationType.counterpart,
        );
        if (!reverse) {
          errors.add(
            'Skill ${s.id}: counterpart "${rel.skillId}" is not symmetric.',
          );
        }
      }
      if (rel.level != null && !target.availableLevels.contains(rel.level)) {
        errors.add(
          'Skill ${s.id}: relatedSkill "${rel.skillId}" '
          'does not offer level "${difficultyToKey(rel.level!)}".',
        );
      }
    }

    final guide = s.learningGuide;
    if (guide != null) {
      for (final targetId in guide.relatedSkillIds) {
        if (!skillMap.containsKey(targetId)) {
          errors.add(
            'Skill ${s.id}: learningGuide.relatedSkillIds target '
            '"$targetId" not found.',
          );
        }
      }
    }
  }

  final visiting = <String>{};
  final visited = <String>{};
  final stack = <String>[];

  void detectCycle(String skillId) {
    if (visited.contains(skillId)) return;
    if (visiting.contains(skillId)) {
      final idx = stack.indexOf(skillId);
      final cycle = [...stack.sublist(idx), skillId].join(' -> ');
      errors.add('Cycle detected in foundation links: $cycle.');
      return;
    }
    visiting.add(skillId);
    stack.add(skillId);
    final skill = skillMap[skillId];
    if (skill != null) {
      for (final rel in skill.relatedSkills) {
        if (rel.relation == SkillRelationType.foundation &&
            skillMap.containsKey(rel.skillId)) {
          detectCycle(rel.skillId);
        }
      }
    }
    stack.removeLast();
    visiting.remove(skillId);
    visited.add(skillId);
  }

  for (final skillId in skillMap.keys) {
    detectCycle(skillId);
  }

  return (skillMap: skillMap, totalLevels: totalLevels);
}

void _validatePublishedPreservation(
  Map<String, CurriculumSkill> skillMap,
  List<CurriculumSkill> publishedSkills,
  List<String> errors,
) {
  if (publishedSkills.isEmpty) return;

  for (final pub in publishedSkills) {
    final draft = skillMap[pub.id];
    if (draft == null) {
      errors.add(
        'Published skill "${pub.id}" cannot be deleted; '
        'set status to "retired" instead.',
      );
      continue;
    }

    if (draft.subject != pub.subject) {
      errors.add(
        'Published skill "${pub.id}" cannot change subject from '
        '"${pub.subject.toWireString()}" to "${draft.subject.toWireString()}".',
      );
    }

    final draftLegacy = draft.legacyIds.toSet();
    for (final legacyId in pub.legacyIds) {
      if (!draftLegacy.contains(legacyId)) {
        errors.add(
          'Published legacyId "$legacyId" on skill "${pub.id}" '
          'cannot be removed.',
        );
      }
    }

    final draftLevels = draft.availableLevels.toSet();
    for (final lvl in pub.availableLevels) {
      if (!draftLevels.contains(lvl)) {
        errors.add(
          'Published difficulty level "${difficultyToKey(lvl)}" on skill '
          '"${pub.id}" cannot be deleted so existing user progress stays '
          'valid.',
        );
      }
    }

    for (final lvl in pub.availableLevels) {
      final pubDef = pub.levels[lvl];
      final draftDef = draft.levels[lvl];
      if (pubDef == null || draftDef == null) continue;
      final lvlKey = difficultyToKey(lvl);
      if (draftDef.standardVersion < pubDef.standardVersion) {
        errors.add(
          'Skill "${pub.id}" level "$lvlKey": standardVersion cannot '
          'decrease below published v${pubDef.standardVersion}.',
        );
      } else if (draftDef.proficient.trim() != pubDef.proficient.trim() &&
          draftDef.standardVersion <= pubDef.standardVersion) {
        errors.add(
          'Skill "${pub.id}" level "$lvlKey": proficient standard changed; '
          'increment standardVersion above v${pubDef.standardVersion}.',
        );
      }
    }
  }
}
