import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_progress_badge.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/profile_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_sync.dart';
import 'package:horseandriderscompanion/Settings/feature_flags.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/skill_level_audit.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// Displays a compact Skill Tree 2.0 progress dashboard on Rider and Horse
/// profiles, falling back to historical legacy `skillLevels` only when V2 has
/// no recorded entries for the profile.
class ProfileSkills extends StatefulWidget {
  const ProfileSkills({
    super.key,
    required this.skillLevels,
    this.subject,
    this.profileDocId,
    this.repository,
  });

  final List<SkillLevel>? skillLevels;
  final SkillSubject? subject;
  final String? profileDocId;
  final SkillTreeV2Repository? repository;

  @override
  State<ProfileSkills> createState() => _ProfileSkillsState();
}

class _ProfileSkillsState extends State<ProfileSkills> {
  static const int _learningPreviewLimit = 4;
  static const int _proficientPreviewLimit = 5;

  bool _loading = false;
  bool _hasError = false;
  bool _hasV2Source = false;
  ProfileSkillsDashboardData? _dashboard;
  int _requestId = 0;

  bool get _canQueryV2 =>
      widget.subject != null &&
      (widget.profileDocId?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    SkillTreeV2Sync.progressRevision.addListener(_handleProgressRevision);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasV2Source && _canQueryV2) {
      unawaited(_loadV2Skills());
    }
  }

  @override
  void didUpdateWidget(covariant ProfileSkills oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject != widget.subject ||
        oldWidget.profileDocId != widget.profileDocId ||
        oldWidget.repository != widget.repository) {
      unawaited(_loadV2Skills());
    }
  }

  @override
  void dispose() {
    SkillTreeV2Sync.progressRevision.removeListener(_handleProgressRevision);
    super.dispose();
  }

  void _handleProgressRevision() {
    if (!mounted || !_canQueryV2) return;
    unawaited(_loadV2Skills());
  }

  SkillTreeV2Repository? _resolveRepository() {
    if (widget.repository != null) return widget.repository;
    try {
      final provided = context.read<SkillTreeV2Repository?>();
      if (provided != null) return provided;
    } catch (_) {
      // RepositoryProvider is optional in isolated widget tests.
    }
    if (Firebase.apps.isNotEmpty) {
      return SkillTreeV2Repository(
        store: HybridCurriculumSkillTreeV2Store(
          primaryStore: FirestoreSkillTreeV2Store(),
        ),
      );
    }
    return null;
  }

  Future<void> _loadV2Skills() async {
    final subject = widget.subject;
    final profileDocId = widget.profileDocId?.trim();
    if (subject == null || profileDocId == null || profileDocId.isEmpty) {
      if (mounted) {
        setState(() {
          _hasV2Source = false;
          _loading = false;
          _hasError = false;
          _dashboard = null;
        });
      }
      return;
    }

    final repo = _resolveRepository();
    if (repo == null) {
      if (mounted) {
        setState(() {
          _hasV2Source = false;
          _loading = false;
          _hasError = false;
          _dashboard = null;
        });
      }
      return;
    }

    final requestId = ++_requestId;
    if (mounted) {
      setState(() {
        _hasV2Source = true;
        _loading = true;
        _hasError = false;
      });
    }

    try {
      final results = await Future.wait<Object>([
        repo.fetchSkills(),
        repo.fetchProgress(subject: subject, profileDocId: profileDocId),
        repo.fetchVerifications(subject: subject, profileDocId: profileDocId),
      ]);
      if (!mounted || requestId != _requestId) return;

      final allSkills = results[0] as List<CurriculumSkill>;
      final progressBySkill = Map<String, SkillProgressRecord>.from(
        results[1] as Map<String, SkillProgressRecord>,
      );
      final verificationsBySkill = Map<String, SkillVerificationRecord>.from(
        results[2] as Map<String, SkillVerificationRecord>,
      );

      if (progressBySkill.isEmpty &&
          verificationsBySkill.isEmpty &&
          (widget.skillLevels?.isNotEmpty ?? false)) {
        var legacyCatalog = const <Skill?>[];
        try {
          legacyCatalog =
              context.read<AppCubit?>()?.state.allSkills ?? const [];
        } catch (_) {
          // Optional in isolated widget tests.
        }
        mergeLegacySkillLevelsIntoV2(
          subject: subject,
          legacySkillLevels: widget.skillLevels!,
          legacyCatalog: legacyCatalog,
          v2Skills: allSkills,
          progressBySkill: progressBySkill,
          verificationsBySkill: verificationsBySkill,
        );
      }

      final dashboard = buildProfileSkillsDashboard(
        subject: subject,
        allSkills: allSkills,
        progressBySkill: progressBySkill,
        verificationsBySkill: verificationsBySkill,
      );

      setState(() {
        _dashboard = dashboard;
        _loading = false;
        _hasError = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      final message = error.toString().toLowerCase();
      final isPermissionDenied = message.contains('permission-denied');
      setState(() {
        _dashboard = null;
        _loading = false;
        _hasError = !isPermissionDenied;
      });
    }
  }

  void _openSkill(CurriculumSkill skill, DifficultyState level) {
    context.read<AppCubit>()
      ..setSkillSubject(isForRider: skill.subject == SkillSubject.rider)
      ..setSkillTree();
    SkillTreeView.openSkill(
      GoRouter.of(context),
      skill.id,
      useV2:
          SettingsControllerScope.maybeOf(context)?.skillTreeV2Enabled ??
          FeatureFlags.kSkillTreeV2Default,
      level: level,
    );
  }

  void _exploreSkillTree() {
    final isForRider = widget.subject != SkillSubject.horse;
    context.read<AppCubit>()
      ..setSkillSubject(isForRider: isForRider)
      ..navigateToSkillsList();
    context.goNamed(SkillTreePage.name);
  }

  Future<void> _showAllEntriesDialog({
    required String title,
    required List<ProfileSkillEntry> entries,
    required bool allowTap,
  }) async {
    await showAppGlassDialog<void>(
      context: context,
      builder: (dialogContext) => AppGlassDialog(
        key: const Key('profileSkillsAllDialog'),
        maxWidth: 580,
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTokens.spaceSm,
          children: [
            for (final entry in entries)
              _ProfileV2SkillRow(
                entry: entry,
                keyPrefix: 'profileSkillAll',
                onTap: !allowTap
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        _openSkill(entry.skill, entry.level);
                      },
              ),
          ],
        ),
        actions: [
          AppOutlinedButton(
            label: 'Close',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = context.select((AppCubit c) => c.state.isGuest);

    if (_hasV2Source && _loading && _dashboard == null) {
      return const Padding(
        key: Key('profileSkillsLoading'),
        padding: EdgeInsets.symmetric(vertical: AppTokens.spaceMd),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_hasV2Source && _hasError && _dashboard == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceSm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Could not load Skill Tree progress.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
            ),
            TextButton(
              key: const Key('profileSkillsRetryButton'),
              onPressed: _loadV2Skills,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final dashboard = _dashboard;
    if (dashboard != null && dashboard.hasRecordedProgress) {
      final learningPreview = dashboard.learningEntries
          .take(_learningPreviewLimit)
          .toList();
      final proficientPreview = dashboard.proficientEntries
          .take(_proficientPreviewLimit)
          .toList();
      final suggestion = dashboard.suggestion;

      return Column(
        key: const Key('profileSkillsV2List'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppTokens.spaceMd,
        children: [
          _SummaryMetricsRow(dashboard: dashboard),
          if (learningPreview.isNotEmpty)
            Column(
              key: const Key('profileSkillsLearningSection'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppTokens.spaceSm,
              children: [
                _SectionSubheader(
                  title: 'Currently Learning',
                  actionLabel:
                      dashboard.learningEntries.length > _learningPreviewLimit
                      ? 'View All (${dashboard.learningEntries.length})'
                      : null,
                  actionKey: const Key('profileSkillsLearningViewAll'),
                  onAction: () => _showAllEntriesDialog(
                    title: 'Currently Learning',
                    entries: dashboard.learningEntries,
                    allowTap: !isGuest,
                  ),
                ),
                for (final entry in learningPreview)
                  _ProfileV2SkillRow(
                    entry: entry,
                    onTap: isGuest
                        ? null
                        : () => _openSkill(entry.skill, entry.level),
                  ),
              ],
            ),
          if (proficientPreview.isNotEmpty)
            Column(
              key: const Key('profileSkillsProficientSection'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppTokens.spaceSm,
              children: [
                _SectionSubheader(
                  title: 'Proficient Skills',
                  actionLabel:
                      dashboard.proficientEntries.length >
                          _proficientPreviewLimit
                      ? 'View All (${dashboard.proficientEntries.length})'
                      : null,
                  actionKey: const Key('profileSkillsProficientViewAll'),
                  onAction: () => _showAllEntriesDialog(
                    title: 'Proficient Skills',
                    entries: dashboard.proficientEntries,
                    allowTap: !isGuest,
                  ),
                ),
                Wrap(
                  spacing: AppTokens.spaceSm,
                  runSpacing: AppTokens.spaceSm,
                  children: [
                    for (final entry in proficientPreview)
                      _ProficientSkillChip(
                        entry: entry,
                        onTap: isGuest
                            ? null
                            : () => _openSkill(entry.skill, entry.level),
                      ),
                  ],
                ),
              ],
            ),
          if (suggestion != null)
            ValueListenableBuilder<bool>(
              valueListenable: ProfileSpotlightTour.isTourActive,
              builder: (context, tourActive, child) => KeyedSubtree(
                key: (widget.subject == SkillSubject.rider && tourActive)
                    ? ProfileSpotlightTour.suggestedNextSkillKey
                    : null,
                child: child!,
              ),
              child: _SuggestedNextSkillCard(
                suggestion: suggestion,
                onTap: isGuest
                    ? null
                    : () => _openSkill(suggestion.skill, suggestion.level),
              ),
            ),
        ],
      );
    }

    return _LegacyProfileSkillsFallback(
      skillLevels: widget.skillLevels,
      subject: widget.subject,
      onExploreSkillTree: _exploreSkillTree,
    );
  }
}

/// Deterministic dashboard data derived from Skill Tree 2.0 curriculum,
/// self-assessment progress, and instructor verifications.
class ProfileSkillsDashboardData {
  const ProfileSkillsDashboardData({
    required this.learningEntries,
    required this.proficientEntries,
    required this.learningLevelCount,
    required this.learningSkillCount,
    required this.proficientLevelCount,
    required this.proficientSkillCount,
    required this.verifiedLevelCount,
    required this.verifiedSkillCount,
    required this.suggestion,
  });

  final List<ProfileSkillEntry> learningEntries;
  final List<ProfileSkillEntry> proficientEntries;
  final int learningLevelCount;
  final int learningSkillCount;
  final int proficientLevelCount;
  final int proficientSkillCount;
  final int verifiedLevelCount;
  final int verifiedSkillCount;
  final SuggestedNextSkill? suggestion;

  bool get hasRecordedProgress =>
      learningEntries.isNotEmpty || proficientEntries.isNotEmpty;
}

/// Single skill + difficulty level progress entry shown on a Profile.
class ProfileSkillEntry {
  const ProfileSkillEntry({
    required this.skill,
    required this.level,
    required this.selfState,
    required this.verified,
    this.verifiedByName,
    this.updatedAt,
  });

  final CurriculumSkill skill;
  final DifficultyState level;
  final LevelState? selfState;
  final bool verified;
  final String? verifiedByName;
  final DateTime? updatedAt;

  LevelState get effectiveState =>
      verified ? LevelState.PROFICIENT : (selfState ?? LevelState.LEARNING);
}

/// Deterministic, explainable next-skill recommendation.
class SuggestedNextSkill {
  const SuggestedNextSkill({
    required this.skill,
    required this.level,
    required this.reason,
    required this.kind,
  });

  final CurriculumSkill skill;
  final DifficultyState level;
  final String reason;
  final SuggestedNextKind kind;
}

enum SuggestedNextKind { continueLearning, nextAvailableLevel, sameFamilySkill }

/// Maps historical legacy [SkillLevel] records onto V2 [CurriculumSkill]
/// progress/verification maps when a profile has not yet written V2 docs.
void mergeLegacySkillLevelsIntoV2({
  required SkillSubject subject,
  required List<SkillLevel> legacySkillLevels,
  required List<Skill?> legacyCatalog,
  required List<CurriculumSkill> v2Skills,
  required Map<String, SkillProgressRecord> progressBySkill,
  required Map<String, SkillVerificationRecord> verificationsBySkill,
}) {
  final legacyById = <String, Skill>{
    for (final skill in legacyCatalog.whereType<Skill>()) skill.id: skill,
  };
  final subjectV2 = v2Skills.where((s) => s.subject == subject).toList();

  for (final legacy in legacySkillLevels) {
    final isVerified =
        legacy.verified || legacy.levelState == LevelState.VERIFIED;
    final isProficient = legacy.levelState == LevelState.PROFICIENT;
    final isLearning = legacy.levelState == LevelState.LEARNING;
    if (!isVerified && !isProficient && !isLearning) continue;

    final matched = subjectV2.where(
      (s) => s.id == legacy.skillId || s.legacyIds.contains(legacy.skillId),
    );
    if (matched.isEmpty) continue;
    final targetSkill = matched.first;
    final ordered = _orderedLevelsFor(targetSkill);
    final legacyDifficulty = legacyById[legacy.skillId]?.difficulty;
    final targetLevel =
        (legacyDifficulty != null &&
            legacyDifficulty != DifficultyState.All &&
            ordered.contains(legacyDifficulty))
        ? legacyDifficulty
        : ordered.first;

    final existingProgress = progressBySkill[targetSkill.id];
    final nextLevels = Map<DifficultyState, LevelProgress>.from(
      existingProgress?.levels ?? const {},
    );
    final mappedState = (isVerified || isProficient)
        ? LevelState.PROFICIENT
        : LevelState.LEARNING;
    nextLevels[targetLevel] = LevelProgress(
      state: mappedState,
      updatedAt: legacy.lastEditDate,
      updatedByName: legacy.lastEditBy,
    );
    progressBySkill[targetSkill.id] = SkillProgressRecord(
      skillId: targetSkill.id,
      subject: subject,
      levels: nextLevels,
      updatedAt: legacy.lastEditDate,
    );

    if (isVerified) {
      final existingVerif = verificationsBySkill[targetSkill.id];
      final nextVerifLevels = Map<DifficultyState, LevelVerification>.from(
        existingVerif?.levels ?? const {},
      );
      nextVerifLevels[targetLevel] = LevelVerification(
        verifiedByName: legacy.lastEditBy ?? 'Instructor',
        verifiedAt: legacy.lastEditDate,
      );
      verificationsBySkill[targetSkill.id] = SkillVerificationRecord(
        skillId: targetSkill.id,
        levels: nextVerifLevels,
        updatedAt: legacy.lastEditDate,
      );
    }
  }
}

/// Builds dashboard metrics, sorted previews, and one deterministic next-skill
/// recommendation from real curriculum standards and recorded progress.
ProfileSkillsDashboardData buildProfileSkillsDashboard({
  required SkillSubject subject,
  required List<CurriculumSkill> allSkills,
  required Map<String, SkillProgressRecord> progressBySkill,
  required Map<String, SkillVerificationRecord> verificationsBySkill,
}) {
  final subjectSkills = allSkills.where((s) => s.subject == subject).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final activeSkills = subjectSkills
      .where((s) => s.status == CurriculumSkillStatus.active)
      .toList();

  final learningEntries = <ProfileSkillEntry>[];
  final proficientEntries = <ProfileSkillEntry>[];
  final learningSkillIds = <String>{};
  final proficientSkillIds = <String>{};
  final verifiedSkillIds = <String>{};
  var verifiedLevelCount = 0;

  for (final skill in subjectSkills) {
    final progress = progressBySkill[skill.id];
    final verification = verificationsBySkill[skill.id];
    if (progress == null && verification == null) continue;

    final orderedLevels = _orderedLevelsFor(skill);
    for (final level in orderedLevels) {
      final levelProgress = progress?.levels[level];
      final selfState = levelProgress?.state;
      final levelVerif = verification?.levels[level];
      final hasSelf =
          selfState == LevelState.LEARNING ||
          selfState == LevelState.PROFICIENT;
      final isVerified = levelVerif != null;
      if (!hasSelf && !isVerified) continue;

      final updatedAt =
          levelProgress?.updatedAt ??
          progress?.updatedAt ??
          levelVerif?.verifiedAt;
      final entry = ProfileSkillEntry(
        skill: skill,
        level: level,
        selfState: selfState,
        verified: isVerified,
        verifiedByName: levelVerif?.verifiedByName,
        updatedAt: updatedAt,
      );

      if (isVerified) {
        verifiedLevelCount++;
        verifiedSkillIds.add(skill.id);
      }

      if (selfState == LevelState.PROFICIENT || isVerified) {
        proficientEntries.add(entry);
        proficientSkillIds.add(skill.id);
      } else if (selfState == LevelState.LEARNING) {
        learningEntries.add(entry);
        learningSkillIds.add(skill.id);
      }
    }
  }

  int compareByRecencyThenSort(ProfileSkillEntry a, ProfileSkillEntry b) {
    final aTime = a.updatedAt;
    final bTime = b.updatedAt;
    if (aTime != null && bTime != null) {
      final cmp = bTime.compareTo(aTime);
      if (cmp != 0) return cmp;
    } else if (aTime != null) {
      return -1;
    } else if (bTime != null) {
      return 1;
    }
    final sortCmp = a.skill.sortOrder.compareTo(b.skill.sortOrder);
    if (sortCmp != 0) return sortCmp;
    return a.level.index.compareTo(b.level.index);
  }

  learningEntries.sort(compareByRecencyThenSort);
  proficientEntries.sort(compareByRecencyThenSort);

  final suggestion = _computeSuggestedNextSkill(
    activeSkills: activeSkills,
    learningEntries: learningEntries,
    proficientEntries: proficientEntries,
    progressBySkill: progressBySkill,
    verificationsBySkill: verificationsBySkill,
  );

  return ProfileSkillsDashboardData(
    learningEntries: learningEntries,
    proficientEntries: proficientEntries,
    learningLevelCount: learningEntries.length,
    learningSkillCount: learningSkillIds.length,
    proficientLevelCount: proficientEntries.length,
    proficientSkillCount: proficientSkillIds.length,
    verifiedLevelCount: verifiedLevelCount,
    verifiedSkillCount: verifiedSkillIds.length,
    suggestion: suggestion,
  );
}

List<DifficultyState> _orderedLevelsFor(CurriculumSkill skill) {
  if (skill.availableLevels.isNotEmpty) return skill.availableLevels;
  return kOrderedDifficultyLevels;
}

SuggestedNextSkill? _computeSuggestedNextSkill({
  required List<CurriculumSkill> activeSkills,
  required List<ProfileSkillEntry> learningEntries,
  required List<ProfileSkillEntry> proficientEntries,
  required Map<String, SkillProgressRecord> progressBySkill,
  required Map<String, SkillVerificationRecord> verificationsBySkill,
}) {
  // 1. Continue a Learning skill (most recently updated first).
  for (final entry in learningEntries) {
    if (entry.skill.status == CurriculumSkillStatus.active) {
      return SuggestedNextSkill(
        skill: entry.skill,
        level: entry.level,
        reason: entry.updatedAt != null
            ? 'Recently marked Learning — continue practicing this standard.'
            : 'Currently marked Learning — pick up where you left off.',
        kind: SuggestedNextKind.continueLearning,
      );
    }
  }

  bool isLevelRecorded(String skillId, DifficultyState level) {
    final self = progressBySkill[skillId]?.levels[level]?.state;
    final verif = verificationsBySkill[skillId]?.levels[level];
    return self == LevelState.LEARNING ||
        self == LevelState.PROFICIENT ||
        verif != null;
  }

  // 2. Explore the next available difficulty level after a Proficient skill.
  for (final entry in proficientEntries) {
    if (entry.skill.status != CurriculumSkillStatus.active) continue;
    final levels = _orderedLevelsFor(entry.skill);
    final currentIndex = levels.indexOf(entry.level);
    if (currentIndex < 0) continue;
    for (var i = currentIndex + 1; i < levels.length; i++) {
      final nextLevel = levels[i];
      if (!isLevelRecorded(entry.skill.id, nextLevel)) {
        return SuggestedNextSkill(
          skill: entry.skill,
          level: nextLevel,
          reason:
              '${difficultyDisplayLabel(entry.level)} is complete — '
              '${difficultyDisplayLabel(nextLevel)} is available to explore.',
          kind: SuggestedNextKind.nextAvailableLevel,
        );
      }
    }
  }

  // 3. Explore an unstarted active skill from the same family.
  bool hasAnyRecordedLevel(CurriculumSkill skill) {
    return _orderedLevelsFor(
      skill,
    ).any((level) => isLevelRecorded(skill.id, level));
  }

  final anchorSkill = proficientEntries.isNotEmpty
      ? proficientEntries.first.skill
      : null;
  if (anchorSkill != null) {
    for (final candidate in activeSkills) {
      if (candidate.id == anchorSkill.id) continue;
      if (candidate.familyId == anchorSkill.familyId &&
          !hasAnyRecordedLevel(candidate)) {
        final targetLevel = _orderedLevelsFor(candidate).first;
        return SuggestedNextSkill(
          skill: candidate,
          level: targetLevel,
          reason:
              'In the same skill family as ${anchorSkill.name} — '
              'a related topic to explore next.',
          kind: SuggestedNextKind.sameFamilySkill,
        );
      }
    }
  }

  // 4. Fallback: first unstarted active skill in the curriculum.
  for (final candidate in activeSkills) {
    if (!hasAnyRecordedLevel(candidate)) {
      final targetLevel = _orderedLevelsFor(candidate).first;
      return SuggestedNextSkill(
        skill: candidate,
        level: targetLevel,
        reason:
            'An unstarted ${realmDisplayLabel(candidate.realm)} skill to '
            'explore next.',
        kind: SuggestedNextKind.sameFamilySkill,
      );
    }
  }

  return null;
}

class _SummaryMetricsRow extends StatelessWidget {
  const _SummaryMetricsRow({required this.dashboard});

  final ProfileSkillsDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const Key('profileSkillsSummary'),
      spacing: AppTokens.spaceSm,
      runSpacing: AppTokens.spaceSm,
      children: [
        _MetricPill(
          key: const Key('profileSkillsLearningMetric'),
          primaryLabel: '${dashboard.learningLevelCount} Learning',
          detailLabel: _countDetail(
            skills: dashboard.learningSkillCount,
            levels: dashboard.learningLevelCount,
          ),
          icon: Icons.school_outlined,
          tone: AppStatusTone.coral,
        ),
        _MetricPill(
          key: const Key('profileSkillsProficientMetric'),
          primaryLabel: '${dashboard.proficientLevelCount} Proficient',
          detailLabel: _countDetail(
            skills: dashboard.proficientSkillCount,
            levels: dashboard.proficientLevelCount,
          ),
          icon: Icons.check_circle_outline,
          tone: AppStatusTone.success,
        ),
        _MetricPill(
          key: const Key('profileSkillsVerifiedMetric'),
          primaryLabel: '${dashboard.verifiedLevelCount} Verified',
          detailLabel: dashboard.verifiedLevelCount == 0
              ? 'Instructor verified'
              : '${_countDetail(
                  skills: dashboard.verifiedSkillCount,
                  levels: dashboard.verifiedLevelCount,
                )} · Instructor',
          icon: Icons.verified_outlined,
          tone: AppStatusTone.warning,
        ),
      ],
    );
  }

  String _countDetail({required int skills, required int levels}) {
    final skillWord = skills == 1 ? 'skill' : 'skills';
    final levelWord = levels == 1 ? 'level' : 'levels';
    return '$skills $skillWord · $levels $levelWord';
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    super.key,
    required this.primaryLabel,
    required this.detailLabel,
    required this.icon,
    required this.tone,
  });

  final String primaryLabel;
  final String detailLabel;
  final IconData icon;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = switch (tone) {
      AppStatusTone.coral => AppTokens.accentColor(context),
      AppStatusTone.success =>
        isDark ? AppTokens.successDark : const Color(0xFF2E7D32),
      AppStatusTone.warning =>
        isDark ? AppTokens.warningDark : const Color(0xFFED6C02),
      AppStatusTone.error => theme.colorScheme.error,
      AppStatusTone.info =>
        isDark ? AppTokens.infoDark : theme.colorScheme.primary,
      AppStatusTone.neutral => AppTokens.secondaryTextColor(context),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSm + 4,
        vertical: AppTokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppTokens.midnightInputFill
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppTokens.spaceSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                primaryLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppTokens.primaryTextColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                detailLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionSubheader extends StatelessWidget {
  const _SectionSubheader({
    required this.title,
    this.actionLabel,
    this.actionKey,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTokens.secondaryTextColor(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            key: actionKey,
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(40, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _ProficientSkillChip extends StatelessWidget {
  const _ProficientSkillChip({required this.entry, required this.onTap});

  final ProfileSkillEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSm);
    final checkColor = isDark
        ? AppTokens.successDark
        : const Color(0xFF2E7D32);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppTokens.midnightInputFill
            : colors.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(
          color: entry.verified
              ? AppTokens.warningDark.withValues(alpha: 0.5)
              : isDark
              ? AppTokens.cardBorderDark.withValues(alpha: 0.65)
              : colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('profileSkillV2_${entry.skill.id}_${entry.level.name}'),
          borderRadius: radius,
          hoverColor: AppTokens.hoverOverlay(context),
          highlightColor: AppTokens.pressOverlay(context),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  entry.verified
                      ? Icons.verified
                      : Icons.check_circle_outline,
                  size: 16,
                  color: entry.verified
                      ? (isDark
                            ? AppTokens.warningDark
                            : const Color(0xFFED6C02))
                      : checkColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${entry.skill.name} · '
                    '${difficultyDisplayLabel(entry.level)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTokens.primaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestedNextSkillCard extends StatelessWidget {
  const _SuggestedNextSkillCard({
    required this.suggestion,
    required this.onTap,
  });

  final SuggestedNextSkill suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppTokens.radiusMd);
    final accent = AppTokens.accentColor(context);

    return DecoratedBox(
      key: const Key('profileSkillsSuggestedNext'),
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTokens.midnightCardTop.withValues(alpha: 0.92),
                  AppTokens.midnightInputFill,
                ],
              )
            : null,
        color: isDark ? null : theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('profileSkillsSuggestedNextButton'),
          borderRadius: radius,
          hoverColor: AppTokens.hoverOverlay(context),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceSm + 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.explore_outlined, size: 20, color: accent),
                const SizedBox(width: AppTokens.spaceSm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Text(
                        'Suggested Next Skill',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${suggestion.skill.name} · '
                        '${difficultyDisplayLabel(suggestion.level)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTokens.primaryTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        suggestion.reason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTokens.secondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: AppTokens.secondaryTextColor(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileV2SkillRow extends StatelessWidget {
  const _ProfileV2SkillRow({
    required this.entry,
    required this.onTap,
    this.keyPrefix = 'profileSkillV2',
  });

  final ProfileSkillEntry entry;
  final VoidCallback? onTap;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSm);
    final icon = switch (entry.skill.realm) {
      SkillCategory.Mounted => HorseAndRiderIcons.riding,
      SkillCategory.In_Hand => HorseAndRiderIcons.inhand,
      SkillCategory.Husbandry => HorseAndRiderIcons.husbandry,
      SkillCategory.Other => Icons.menu_book_outlined,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppTokens.midnightInputFill
            : colors.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? AppTokens.cardBorderDark.withValues(alpha: 0.65)
              : colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('${keyPrefix}_${entry.skill.id}_${entry.level.name}'),
          borderRadius: radius,
          hoverColor: AppTokens.hoverOverlay(context),
          highlightColor: AppTokens.pressOverlay(context),
          focusColor: AppTokens.focusOverlay(context),
          splashColor: AppTokens.pressOverlay(context),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceMd,
              vertical: AppTokens.spaceSm + 2,
            ),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTokens.coralAccent.withValues(alpha: 0.14)
                        : colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isDark
                          ? AppTokens.coralAccent
                          : colors.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        entry.skill.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTokens.primaryTextColor(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            difficultyDisplayLabel(entry.level),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppTokens.secondaryTextColor(context),
                            ),
                          ),
                          SkillProgressBadge(
                            level: entry.effectiveState,
                            verified: entry.verified,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: AppTokens.secondaryTextColor(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegacyProfileSkillsFallback extends StatelessWidget {
  const _LegacyProfileSkillsFallback({
    required this.skillLevels,
    required this.subject,
    required this.onExploreSkillTree,
  });

  final List<SkillLevel>? skillLevels;
  final SkillSubject? subject;
  final VoidCallback onExploreSkillTree;

  @override
  Widget build(BuildContext context) {
    final emptyMessage = subject == SkillSubject.horse
        ? 'No skills recorded yet. Open Skill Tree to track this horse’s '
              'Learning and Proficient milestones.'
        : 'No skills recorded yet. Open Skill Tree to track Learning and '
              'Proficient milestones.';
    final empty = ValueListenableBuilder<bool>(
      valueListenable: ProfileSpotlightTour.isTourActive,
      builder: (context, tourActive, child) => KeyedSubtree(
        key: (subject == SkillSubject.rider && tourActive)
            ? ProfileSpotlightTour.suggestedNextSkillKey
            : null,
        child: child!,
      ),
      child: AppEmptyState(
        key: const Key('profileSkillsEmptyState'),
        icon: Icons.account_tree_outlined,
        title: 'Start tracking skills',
        description: emptyMessage,
        actionLabel: 'Explore Skill Tree',
        onAction: onExploreSkillTree,
      ),
    );
    if (skillLevels?.isNotEmpty != true) return empty;

    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final audit = SkillLevelAudit.evaluate(
          profileSkillLevels: skillLevels,
          allSkills: state.allSkills,
        );
        if (!audit.isCatalogReady) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (audit.validLevels.isEmpty) return empty;

        final skills = {
          for (final skill in state.allSkills.whereType<Skill>())
            skill.id: skill,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (final level in audit.validLevels)
              _LegacyProfileSkillRow(
                level: level,
                skill: skills[level.skillId]!,
                onTap: state.isGuest
                    ? null
                    : () {
                        context.read<AppCubit>().setSkillTree();
                        final skill = skills[level.skillId];
                        SkillTreeView.openSkill(
                          GoRouter.of(context),
                          level.skillId,
                          useV2:
                              SettingsControllerScope.maybeOf(
                                context,
                              )?.skillTreeV2Enabled ??
                              FeatureFlags.kSkillTreeV2Default,
                          level:
                              skill == null ||
                                  skill.difficulty == DifficultyState.All
                              ? null
                              : skill.difficulty,
                        );
                      },
              ),
          ],
        );
      },
    );
  }
}

class _LegacyProfileSkillRow extends StatelessWidget {
  const _LegacyProfileSkillRow({
    required this.level,
    required this.skill,
    required this.onTap,
  });

  final SkillLevel level;
  final Skill skill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSm);
    final icon = switch (skill.category) {
      SkillCategory.Mounted => HorseAndRiderIcons.riding,
      SkillCategory.In_Hand => HorseAndRiderIcons.inhand,
      SkillCategory.Husbandry => HorseAndRiderIcons.husbandry,
      SkillCategory.Other => Icons.school_outlined,
    };
    final verified = level.verified || level.levelState == LevelState.VERIFIED;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? AppTokens.midnightInputFill
            : colors.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(
          color: isDark
              ? AppTokens.cardBorderDark.withValues(alpha: 0.65)
              : colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: radius),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          horizontalTitleGap: 12,
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTokens.coralAccent.withValues(alpha: 0.14)
                  : colors.secondaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                size: 20,
                color: isDark
                    ? AppTokens.coralAccent
                    : colors.onSecondaryContainer,
              ),
            ),
          ),
          title: Text(
            level.skillName,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppTokens.primaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (skill.difficulty != DifficultyState.All)
                  Text(skill.difficulty.name),
                SkillProgressBadge(level: level.levelState, verified: verified),
              ],
            ),
          ),
          trailing: onTap == null
              ? null
              : Icon(
                  Icons.chevron_right,
                  color: AppTokens.secondaryTextColor(context),
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
