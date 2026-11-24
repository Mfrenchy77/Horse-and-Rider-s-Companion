import 'package:database_repository/database_repository.dart';

enum SkillTreeV2ResourceSort { helpfulness, newest }

String realmDisplayLabel(SkillCategory realm) => switch (realm) {
  SkillCategory.Husbandry => 'Husbandry',
  SkillCategory.In_Hand => 'In-Hand',
  SkillCategory.Mounted => 'Mounted',
  SkillCategory.Other => 'Theory & Knowledge',
};

String subjectDisplayLabel(SkillSubject subject) =>
    subject == SkillSubject.rider ? 'Rider' : 'Horse';

String difficultyDisplayLabel(DifficultyState level) => switch (level) {
  DifficultyState.Introductory => 'Introductory',
  DifficultyState.Intermediate => 'Intermediate',
  DifficultyState.Advanced => 'Advanced',
  DifficultyState.All => 'All',
};

String shortDifficultyLabel(DifficultyState level) => switch (level) {
  DifficultyState.Introductory => 'Intro',
  DifficultyState.Intermediate => 'Int',
  DifficultyState.Advanced => 'Adv',
  DifficultyState.All => 'All',
};

List<SkillCategory> realmsForSubject(SkillSubject subject) =>
    subject == SkillSubject.rider
    ? const [
        SkillCategory.Husbandry,
        SkillCategory.In_Hand,
        SkillCategory.Mounted,
        SkillCategory.Other,
      ]
    : const [SkillCategory.In_Hand, SkillCategory.Mounted];

/// Returns all canonical, explicit legacy, and name/alias-matched legacy
/// skill IDs that [Resource.skillTreeIds] may reference for [skill].
Set<String> effectiveResourceLookupIds({
  required CurriculumSkill skill,
  List<Skill?> legacySkills = const [],
}) {
  final ids = skill.allResourceLookupIds.toSet();
  if (legacySkills.isEmpty) return ids;

  final isRiderSkill = skill.subject == SkillSubject.rider;
  final candidateNames = <String>{
    normalizeSearchText(skill.name),
    for (final alias in skill.aliases) normalizeSearchText(alias),
  }..removeWhere((name) => name.isEmpty);

  for (final legacy in legacySkills.whereType<Skill>()) {
    if (legacy.rider != isRiderSkill) continue;
    if (ids.contains(legacy.id)) continue;
    final normalizedLegacyName = normalizeSearchText(legacy.skillName);
    if (candidateNames.contains(normalizedLegacyName)) {
      ids.add(legacy.id);
    }
  }
  return ids;
}

/// Ranks related [Resource] items by community helpfulness (Bayesian average
/// accounting for vote counts so 1-2 vote items do not unfairly outrank
/// established resources, while keeping unrated items discoverable) or newest.
List<Resource> filterAndRankResourcesForSkill({
  required CurriculumSkill skill,
  required List<Resource> allResources,
  List<Skill?> legacySkills = const [],
  SkillTreeV2ResourceSort sort = SkillTreeV2ResourceSort.helpfulness,
}) {
  final lookupIds = effectiveResourceLookupIds(
    skill: skill,
    legacySkills: legacySkills,
  );
  final matching = allResources
      .where((resource) => resource.skillTreeIds.any(lookupIds.contains))
      .toList()
    ..sort((a, b) {
      if (sort == SkillTreeV2ResourceSort.newest) {
        final dateA = a.lastEditDate ?? a.createdAt ?? DateTime(1970);
        final dateB = b.lastEditDate ?? b.createdAt ?? DateTime(1970);
        return dateB.compareTo(dateA);
      }
      final scoreCompare = _helpfulnessScore(b).compareTo(_helpfulnessScore(a));
      if (scoreCompare != 0) return scoreCompare;
      final dateA = a.lastEditDate ?? a.createdAt ?? DateTime(1970);
      final dateB = b.lastEditDate ?? b.createdAt ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

  return matching;
}

double _helpfulnessScore(Resource resource) {
  const priorMean = 3.0;
  const priorWeight = 3.0;
  final count = resource.numberOfRates ?? resource.usersWhoRated?.length ?? 0;
  final rating = (resource.rating ?? 0).toDouble();
  if (count <= 0) return priorMean;
  return ((rating * count) + (priorMean * priorWeight)) / (count + priorWeight);
}

class RealmAbilitySummary {
  const RealmAbilitySummary({
    required this.realm,
    required this.totalSkills,
    required this.totalLevels,
    required this.learningLevels,
    required this.proficientLevels,
    required this.verifiedLevels,
    this.highestProficientLevel,
    this.highestVerifiedLevel,
  });

  final SkillCategory realm;
  final int totalSkills;
  final int totalLevels;
  final int learningLevels;
  final int proficientLevels;
  final int verifiedLevels;
  final DifficultyState? highestProficientLevel;
  final DifficultyState? highestVerifiedLevel;
}

class SubjectAbilitySummary {
  const SubjectAbilitySummary({
    required this.subject,
    required this.realmSummaries,
    required this.totalSkills,
    required this.totalLevels,
    required this.learningLevels,
    required this.proficientLevels,
    required this.verifiedLevels,
  });

  final SkillSubject subject;
  final List<RealmAbilitySummary> realmSummaries;
  final int totalSkills;
  final int totalLevels;
  final int learningLevels;
  final int proficientLevels;
  final int verifiedLevels;
}

SubjectAbilitySummary computeAbilitySummary({
  required SkillSubject subject,
  required List<CurriculumSkill> skills,
  required Map<String, SkillProgressRecord> progressBySkillId,
  required Map<String, SkillVerificationRecord> verificationsBySkillId,
}) {
  final subjectSkills = skills.where((s) => s.subject == subject).toList();
  final realms = realmsForSubject(subject);
  final realmSummaries = <RealmAbilitySummary>[];

  var totalSkills = 0;
  var totalLevels = 0;
  var totalLearning = 0;
  var totalProficient = 0;
  var totalVerified = 0;

  for (final realm in realms) {
    final realmSkills = subjectSkills
        .where((s) => s.realm == realm)
        .toList();
    var skillCount = 0;
    var levels = 0;
    var learning = 0;
    var proficient = 0;
    var verified = 0;
    DifficultyState? highestProficient;
    DifficultyState? highestVerified;

    for (final skill in realmSkills) {
      final isActive = skill.status == CurriculumSkillStatus.active;
      if (isActive) {
        skillCount++;
        levels += skill.availableLevels.length;
      }
      final progress = progressBySkillId[skill.id];
      final verification = verificationsBySkillId[skill.id];
      final trackedLevels = <DifficultyState>{
        ...skill.availableLevels,
        ...?progress?.levels.keys,
        ...?verification?.levels.keys,
      };
      for (final level in trackedLevels) {
        final selfState = progress?.levels[level]?.state;
        final isVerified = verification?.levels.containsKey(level) ?? false;
        if (selfState == LevelState.LEARNING) learning++;
        if (selfState == LevelState.PROFICIENT || isVerified) {
          proficient++;
          highestProficient = _maxLevel(highestProficient, level);
        }
        if (isVerified) {
          verified++;
          highestVerified = _maxLevel(highestVerified, level);
        }
      }
    }

    totalSkills += skillCount;
    totalLevels += levels;
    totalLearning += learning;
    totalProficient += proficient;
    totalVerified += verified;

    realmSummaries.add(
      RealmAbilitySummary(
        realm: realm,
        totalSkills: skillCount,
        totalLevels: levels,
        learningLevels: learning,
        proficientLevels: proficient,
        verifiedLevels: verified,
        highestProficientLevel: highestProficient,
        highestVerifiedLevel: highestVerified,
      ),
    );
  }

  return SubjectAbilitySummary(
    subject: subject,
    realmSummaries: realmSummaries,
    totalSkills: totalSkills,
    totalLevels: totalLevels,
    learningLevels: totalLearning,
    proficientLevels: totalProficient,
    verifiedLevels: totalVerified,
  );
}

DifficultyState _maxLevel(DifficultyState? current, DifficultyState candidate) {
  if (current == null) return candidate;
  const order = {
    DifficultyState.Introductory: 0,
    DifficultyState.Intermediate: 1,
    DifficultyState.Advanced: 2,
  };
  return (order[candidate] ?? -1) >= (order[current] ?? -1)
      ? candidate
      : current;
}
