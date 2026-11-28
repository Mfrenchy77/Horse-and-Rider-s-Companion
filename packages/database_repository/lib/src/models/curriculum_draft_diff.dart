// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars

import 'package:database_repository/src/models/curriculum_skill.dart';
import 'package:database_repository/src/models/skill.dart';
import 'package:database_repository/src/models/skill_family.dart';

/// Describes a single modified [SkillFamily] between published and draft.
class FamilyDiffItem {
  const FamilyDiffItem({
    required this.family,
    required this.changedFields,
  });

  final SkillFamily family;
  final List<String> changedFields;
}

/// Records a standardVersion increment or downgrade on one difficulty level.
class LevelVersionChange {
  const LevelVersionChange({
    required this.level,
    required this.previousVersion,
    required this.nextVersion,
  });

  final DifficultyState level;
  final int previousVersion;
  final int nextVersion;
}

/// Describes a single modified [CurriculumSkill] between published and draft.
class SkillDiffItem {
  const SkillDiffItem({
    required this.skill,
    required this.changedFields,
    this.standardVersionChanges = const [],
  });

  final CurriculumSkill skill;
  final List<String> changedFields;
  final List<LevelVersionChange> standardVersionChanges;
}

/// Semantic difference between a published curriculum and an admin draft.
///
/// Ignores transient metadata such as `updatedAt`, `updatedBy`, and
/// `standardUpdatedAt` so saving or loading a draft never produces
/// false-positive modifications.
class CurriculumDraftDiff {
  const CurriculumDraftDiff({
    this.addedFamilies = const [],
    this.modifiedFamilies = const [],
    this.removedFamilies = const [],
    this.addedSkills = const [],
    this.modifiedSkills = const [],
    this.retiredSkills = const [],
    this.removedSkills = const [],
  });

  factory CurriculumDraftDiff.compute({
    required List<SkillFamily> publishedFamilies,
    required List<CurriculumSkill> publishedSkills,
    required List<SkillFamily> draftFamilies,
    required List<CurriculumSkill> draftSkills,
  }) {
    final pubFamilyMap = {for (final f in publishedFamilies) f.id: f};
    final draftFamilyMap = {for (final f in draftFamilies) f.id: f};

    final addedFamilies = <SkillFamily>[];
    final modifiedFamilies = <FamilyDiffItem>[];
    final removedFamilies = <SkillFamily>[];

    for (final f in draftFamilies) {
      final pub = pubFamilyMap[f.id];
      if (pub == null) {
        addedFamilies.add(f);
        continue;
      }
      final changed = _diffFamily(pub, f);
      if (changed.isNotEmpty) {
        modifiedFamilies.add(FamilyDiffItem(family: f, changedFields: changed));
      }
    }
    for (final f in publishedFamilies) {
      if (!draftFamilyMap.containsKey(f.id)) {
        removedFamilies.add(f);
      }
    }

    final pubSkillMap = {for (final s in publishedSkills) s.id: s};
    final draftSkillMap = {for (final s in draftSkills) s.id: s};

    final addedSkills = <CurriculumSkill>[];
    final modifiedSkills = <SkillDiffItem>[];
    final retiredSkills = <CurriculumSkill>[];
    final removedSkills = <CurriculumSkill>[];

    for (final s in draftSkills) {
      final pub = pubSkillMap[s.id];
      if (pub == null) {
        addedSkills.add(s);
        continue;
      }
      if (pub.status != CurriculumSkillStatus.retired &&
          s.status == CurriculumSkillStatus.retired) {
        retiredSkills.add(s);
      }
      final versionChanges = <LevelVersionChange>[];
      final changed = _diffSkill(pub, s, versionChanges);
      if (changed.isNotEmpty) {
        modifiedSkills.add(
          SkillDiffItem(
            skill: s,
            changedFields: changed,
            standardVersionChanges: versionChanges,
          ),
        );
      }
    }

    for (final s in publishedSkills) {
      if (!draftSkillMap.containsKey(s.id)) {
        removedSkills.add(s);
      }
    }

    return CurriculumDraftDiff(
      addedFamilies: addedFamilies,
      modifiedFamilies: modifiedFamilies,
      removedFamilies: removedFamilies,
      addedSkills: addedSkills,
      modifiedSkills: modifiedSkills,
      retiredSkills: retiredSkills,
      removedSkills: removedSkills,
    );
  }

  final List<SkillFamily> addedFamilies;
  final List<FamilyDiffItem> modifiedFamilies;
  final List<SkillFamily> removedFamilies;
  final List<CurriculumSkill> addedSkills;
  final List<SkillDiffItem> modifiedSkills;
  final List<CurriculumSkill> retiredSkills;
  final List<CurriculumSkill> removedSkills;

  bool get hasChanges =>
      addedFamilies.isNotEmpty ||
      modifiedFamilies.isNotEmpty ||
      removedFamilies.isNotEmpty ||
      addedSkills.isNotEmpty ||
      modifiedSkills.isNotEmpty ||
      retiredSkills.isNotEmpty ||
      removedSkills.isNotEmpty;
}

List<String> _diffFamily(SkillFamily pub, SkillFamily draft) {
  final changed = <String>[];
  if (pub.subject != draft.subject) changed.add('subject');
  if (pub.realm != draft.realm) changed.add('realm');
  if (pub.name.trim() != draft.name.trim()) changed.add('name');
  if (pub.description.trim() != draft.description.trim()) {
    changed.add('description');
  }
  if (pub.sortOrder != draft.sortOrder) changed.add('sortOrder');
  if (pub.schemaVersion != draft.schemaVersion) changed.add('schemaVersion');
  return changed;
}

List<String> _diffSkill(
  CurriculumSkill pub,
  CurriculumSkill draft,
  List<LevelVersionChange> versionChanges,
) {
  final changed = <String>[];
  if (pub.status != draft.status) changed.add('status');
  if (pub.subject != draft.subject) changed.add('subject');
  if (pub.realm != draft.realm) changed.add('realm');
  if (pub.familyId.trim() != draft.familyId.trim()) changed.add('familyId');
  if (pub.name.trim() != draft.name.trim()) changed.add('name');
  if (!_stringListsEqual(pub.aliases, draft.aliases)) changed.add('aliases');
  if (pub.summary.trim() != draft.summary.trim()) changed.add('summary');
  if (pub.purpose.trim() != draft.purpose.trim()) changed.add('purpose');
  if (!_stringListsEqual(pub.safety, draft.safety)) changed.add('safety');
  if (!_levelsListEqual(pub.availableLevels, draft.availableLevels)) {
    changed.add('availableLevels');
  }
  if ((pub.replacedBy ?? '').trim() != (draft.replacedBy ?? '').trim()) {
    changed.add('replacedBy');
  }
  if (!_relatedSkillsEqual(pub.relatedSkills, draft.relatedSkills)) {
    changed.add('relatedSkills');
  }
  if (!_stringListsEqual(pub.legacyIds, draft.legacyIds)) {
    changed.add('legacyIds');
  }
  if (pub.sortOrder != draft.sortOrder) changed.add('sortOrder');
  if (pub.schemaVersion != draft.schemaVersion) changed.add('schemaVersion');
  if (pub.learningGuide != draft.learningGuide) {
    changed.add('learningGuide');
  }

  final allLevels = <DifficultyState>{
    ...pub.availableLevels,
    ...draft.availableLevels,
  };
  for (final level in kOrderedLevelOrder) {
    if (!allLevels.contains(level)) continue;
    final pubDef = pub.levels[level];
    final draftDef = draft.levels[level];
    if (pubDef == null || draftDef == null) {
      changed.add('${_levelLabel(level)} standard');
      continue;
    }
    if (pubDef.standardVersion != draftDef.standardVersion) {
      versionChanges.add(
        LevelVersionChange(
          level: level,
          previousVersion: pubDef.standardVersion,
          nextVersion: draftDef.standardVersion,
        ),
      );
    }
    if (!_levelDefinitionsEqual(pubDef, draftDef)) {
      final suffix = pubDef.standardVersion != draftDef.standardVersion
          ? ' (v${pubDef.standardVersion} → v${draftDef.standardVersion})'
          : '';
      changed.add('${_levelLabel(level)} standard$suffix');
    }
  }
  return changed;
}

const List<DifficultyState> kOrderedLevelOrder = [
  DifficultyState.Introductory,
  DifficultyState.Intermediate,
  DifficultyState.Advanced,
];

String _levelLabel(DifficultyState level) {
  return switch (level) {
    DifficultyState.Introductory => 'Introductory',
    DifficultyState.Intermediate => 'Intermediate',
    DifficultyState.Advanced => 'Advanced',
    DifficultyState.All => 'All',
  };
}

bool _stringListsEqual(List<String> a, List<String> b) {
  final na = a.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  final nb = b.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (na.length != nb.length) return false;
  for (var i = 0; i < na.length; i++) {
    if (na[i] != nb[i]) return false;
  }
  return true;
}

bool _levelsListEqual(List<DifficultyState> a, List<DifficultyState> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _relatedSkillsEqual(List<RelatedSkill> a, List<RelatedSkill> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].skillId.trim() != b[i].skillId.trim() ||
        a[i].relation != b[i].relation ||
        a[i].level != b[i].level) {
      return false;
    }
  }
  return true;
}

bool _levelDefinitionsEqual(SkillLevelDefinition a, SkillLevelDefinition b) {
  if (a.overview.trim() != b.overview.trim()) return false;
  if (a.learning.trim() != b.learning.trim()) return false;
  if (a.proficient.trim() != b.proficient.trim()) return false;
  if (a.standardVersion != b.standardVersion) return false;
  if (a.components.length != b.components.length) return false;
  for (var i = 0; i < a.components.length; i++) {
    if (a.components[i].title.trim() != b.components[i].title.trim() ||
        a.components[i].description.trim() !=
            b.components[i].description.trim()) {
      return false;
    }
  }
  return true;
}
