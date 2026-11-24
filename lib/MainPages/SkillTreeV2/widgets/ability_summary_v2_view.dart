import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class AbilitySummaryV2View extends StatelessWidget {
  const AbilitySummaryV2View({
    super.key,
    required this.state,
    required this.profileLabel,
    required this.onBrowseRealm,
    required this.onExploreSkills,
    required this.onSelectSkill,
    this.canVerify = false,
    this.onOpenReviewVerifications,
  });

  final SkillTreeV2State state;
  final String? profileLabel;
  final bool canVerify;
  final ValueChanged<SkillCategory> onBrowseRealm;
  final VoidCallback onExploreSkills;
  final void Function(CurriculumSkill skill, DifficultyState? level)
  onSelectSkill;
  final VoidCallback? onOpenReviewVerifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = computeAbilitySummary(
      subject: state.subject,
      skills: state.skills,
      progressBySkillId: state.progressBySkillId,
      verificationsBySkillId: state.verificationsBySkillId,
    );
    final startedByRealm = _startedSkillsByRealm();
    final totalStartedSkills = startedByRealm.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );
    final headingPrefix = state.subject == SkillSubject.horse
        ? 'Horse Skills'
        : 'My Skills';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppTokens.spaceMd,
      children: [
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppTokens.spaceSm,
            children: [
              Wrap(
                spacing: AppTokens.spaceSm,
                runSpacing: AppTokens.spaceSm,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '$headingPrefix'
                    '${profileLabel == null ? '' : ' · $profileLabel'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (canVerify && onOpenReviewVerifications != null)
                    OutlinedButton.icon(
                      key: const Key('reviewVerificationsButton'),
                      onPressed: onOpenReviewVerifications,
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Review Verifications'),
                    ),
                ],
              ),
              if (totalStartedSkills > 0) ...[
                Text(
                  '$totalStartedSkills '
                  '${totalStartedSkills == 1 ? 'skill' : 'skills'} started',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTokens.secondaryTextColor(context),
                  ),
                ),
                Wrap(
                  spacing: AppTokens.spaceSm,
                  runSpacing: AppTokens.spaceSm,
                  children: [
                    _MilestoneStatChip(
                      icon: Icons.school_outlined,
                      label: 'Learning',
                      count: summary.learningLevels,
                    ),
                    _MilestoneStatChip(
                      icon: Icons.check_circle_outline,
                      label: 'Proficient',
                      count: summary.proficientLevels,
                    ),
                    _MilestoneStatChip(
                      icon: Icons.verified_outlined,
                      label: 'Instructor Verified',
                      count: summary.verifiedLevels,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (totalStartedSkills == 0)
          AppSurfaceCard(
            key: const Key('mySkillsEmptyState'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppTokens.spaceMd,
              children: [
                Text(_emptyStateMessage(), style: theme.textTheme.bodyMedium),
                FilledButton.tonalIcon(
                  key: const Key('mySkillsEmptyExploreButton'),
                  onPressed: onExploreSkills,
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('Explore Skills'),
                ),
              ],
            ),
          )
        else
          for (final entry in startedByRealm.entries)
            AppSurfaceCard(
              key: Key('abilitySummaryRealm_${entry.key.name}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppTokens.spaceSm,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          realmDisplayLabel(entry.key),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => onBrowseRealm(entry.key),
                        child: const Text('Browse category'),
                      ),
                    ],
                  ),
                  for (final item in entry.value)
                    _StartedSkillTile(
                      item: item,
                      onTap: () =>
                          onSelectSkill(item.skill, item.levels.first.level),
                    ),
                ],
              ),
            ),
      ],
    );
  }

  String _emptyStateMessage() {
    if (state.subject == SkillSubject.horse) {
      final hasHorseName =
          profileLabel != null && profileLabel!.trim().isNotEmpty;
      if (hasHorseName) {
        return 'No skills have been tracked for $profileLabel yet. '
            'Explore the Skill Tree to get started.';
      }
      return 'No horse skills have been started yet. '
          'Explore the Skill Tree to get started.';
    }
    return "You haven't started tracking any skills yet. "
        'Explore the Skill Tree to get started.';
  }

  Map<SkillCategory, List<_StartedSkillEntry>> _startedSkillsByRealm() {
    final result = <SkillCategory, List<_StartedSkillEntry>>{};
    for (final realm in realmsForSubject(state.subject)) {
      final realmSkills =
          state.subjectSkills.where((s) => s.realm == realm).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final entries = <_StartedSkillEntry>[];
      for (final skill in realmSkills) {
        final progress = state.progressBySkillId[skill.id];
        final verification = state.verificationsBySkillId[skill.id];
        final orderedLevels = [
          for (final lvl in kOrderedDifficultyLevels)
            if (skill.availableLevels.contains(lvl) ||
                (progress?.levels.containsKey(lvl) ?? false) ||
                (verification?.levels.containsKey(lvl) ?? false))
              lvl,
        ];
        final startedLevels = <_StartedLevelStatus>[];
        for (final level in orderedLevels) {
          final selfState = progress?.levels[level]?.state;
          final isVerified = verification?.levels.containsKey(level) ?? false;
          if (selfState != null || isVerified) {
            startedLevels.add(
              _StartedLevelStatus(
                level: level,
                selfState: selfState,
                isVerified: isVerified,
              ),
            );
          }
        }
        if (startedLevels.isNotEmpty) {
          entries.add(
            _StartedSkillEntry(skill: skill, levels: startedLevels),
          );
        }
      }
      if (entries.isNotEmpty) {
        result[realm] = entries;
      }
    }
    return result;
  }
}

class _StartedSkillEntry {
  const _StartedSkillEntry({required this.skill, required this.levels});

  final CurriculumSkill skill;
  final List<_StartedLevelStatus> levels;
}

class _StartedLevelStatus {
  const _StartedLevelStatus({
    required this.level,
    required this.selfState,
    required this.isVerified,
  });

  final DifficultyState level;
  final LevelState? selfState;
  final bool isVerified;
}

class _StartedSkillTile extends StatelessWidget {
  const _StartedSkillTile({required this.item, required this.onTap});

  final _StartedSkillEntry item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      child: InkWell(
        key: Key('mySkillCard_${item.skill.id}'),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppTokens.spaceXs,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.skill.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (item.skill.status == CurriculumSkillStatus.retired) ...[
                    Container(
                      key: Key('retiredBadge_${item.skill.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Retired',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTokens.secondaryTextColor(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final status in item.levels)
                    _StartedLevelChip(status: status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartedLevelChip extends StatelessWidget {
  const _StartedLevelChip({required this.status});

  final _StartedLevelStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelLabel = difficultyDisplayLabel(status.level);
    final (IconData icon, Color bg, Color fg, String suffix) =
        status.isVerified
        ? (
            Icons.verified,
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
            'Verified',
          )
        : status.selfState == LevelState.PROFICIENT
        ? (
            Icons.check_circle_outline,
            theme.colorScheme.tertiaryContainer,
            theme.colorScheme.onTertiaryContainer,
            'Proficient',
          )
        : (
            Icons.school_outlined,
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer,
            'Learning',
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            '$levelLabel · $suffix',
            style: theme.textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

class _MilestoneStatChip extends StatelessWidget {
  const _MilestoneStatChip({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceMd,
        vertical: AppTokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            '$count $label',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
