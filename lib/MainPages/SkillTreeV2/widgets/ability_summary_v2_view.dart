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
  });

  final SkillTreeV2State state;
  final String? profileLabel;
  final ValueChanged<SkillCategory> onBrowseRealm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = computeAbilitySummary(
      subject: state.subject,
      skills: state.skills,
      progressBySkillId: state.progressBySkillId,
      verificationsBySkillId: state.verificationsBySkillId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppTokens.spaceMd,
      children: [
        AppSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppTokens.spaceSm,
            children: [
              Text(
                '${subjectDisplayLabel(state.subject)} Ability Summary'
                '${profileLabel == null ? '' : ' · $profileLabel'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Positive milestones across ${summary.totalSkills} abilities '
                '(${summary.totalLevels} progressive standards).',
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
          ),
        ),
        for (final realmSummary in summary.realmSummaries)
          AppSurfaceCard(
            key: Key('abilitySummaryRealm_${realmSummary.realm.name}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppTokens.spaceSm,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        realmDisplayLabel(realmSummary.realm),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onBrowseRealm(realmSummary.realm),
                      child: const Text('Browse category'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: AppTokens.spaceSm,
                  runSpacing: AppTokens.spaceXs,
                  children: [
                    Text(
                      '${realmSummary.totalSkills} skills · '
                      '${realmSummary.learningLevels} learning · '
                      '${realmSummary.proficientLevels} proficient · '
                      '${realmSummary.verifiedLevels} verified',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                if (realmSummary.highestProficientLevel != null ||
                    realmSummary.highestVerifiedLevel != null)
                  Wrap(
                    spacing: AppTokens.spaceSm,
                    runSpacing: AppTokens.spaceXs,
                    children: [
                      if (realmSummary.highestProficientLevel != null)
                        Chip(
                          avatar: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: Text(
                            'Highest Proficient: '
                            '${difficultyDisplayLabel(
                              realmSummary.highestProficientLevel!,
                            )}',
                          ),
                        ),
                      if (realmSummary.highestVerifiedLevel != null)
                        Chip(
                          avatar: const Icon(Icons.verified, size: 16),
                          label: Text(
                            'Highest Verified: '
                            '${difficultyDisplayLabel(
                              realmSummary.highestVerifiedLevel!,
                            )}',
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
      ],
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
