import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class InstructorAbilityMatrixV2View extends StatelessWidget {
  const InstructorAbilityMatrixV2View({
    super.key,
    required this.state,
    required this.canVerify,
    required this.onChangeFilter,
    required this.onSelectCell,
    required this.onVerifyCell,
  });

  final SkillTreeV2State state;
  final bool canVerify;
  final ValueChanged<AbilityMatrixFilter> onChangeFilter;
  final void Function(CurriculumSkill skill, DifficultyState level)
  onSelectCell;
  final void Function(
    CurriculumSkill skill,
    DifficultyState level, {
    required bool verified,
  })
  onVerifyCell;

  static const List<DifficultyState> _levels = [
    DifficultyState.Introductory,
    DifficultyState.Intermediate,
    DifficultyState.Advanced,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _matchingSkills();
    final isWide = MediaQuery.sizeOf(context).width >= 900;

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
                'Instructor Ability Matrix · '
                '${subjectDisplayLabel(state.subject)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Wrap(
                spacing: AppTokens.spaceXs,
                runSpacing: AppTokens.spaceXs,
                children: [
                  ChoiceChip(
                    key: const Key('matrixFilter_needsReview'),
                    label: const Text('Needs review'),
                    selected:
                        state.matrixFilter == AbilityMatrixFilter.needsReview,
                    onSelected: (_) =>
                        onChangeFilter(AbilityMatrixFilter.needsReview),
                  ),
                  ChoiceChip(
                    key: const Key('matrixFilter_verified'),
                    label: const Text('Verified'),
                    selected:
                        state.matrixFilter == AbilityMatrixFilter.verified,
                    onSelected: (_) =>
                        onChangeFilter(AbilityMatrixFilter.verified),
                  ),
                  ChoiceChip(
                    key: const Key('matrixFilter_allWithActivity'),
                    label: const Text('All with activity'),
                    selected:
                        state.matrixFilter ==
                        AbilityMatrixFilter.allWithActivity,
                    onSelected: (_) =>
                        onChangeFilter(AbilityMatrixFilter.allWithActivity),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (rows.isEmpty)
          AppSurfaceCard(
            child: Text(
              'No abilities match the selected filter.',
              style: theme.textTheme.bodyMedium,
            ),
          )
        else if (isWide)
          AppSurfaceCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Ability')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Intro')),
                  DataColumn(label: Text('Int')),
                  DataColumn(label: Text('Adv')),
                ],
                rows: [
                  for (final skill in rows)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(skill.name),
                          onTap: () => onSelectCell(
                            skill,
                            skill.availableLevels.first,
                          ),
                        ),
                        DataCell(Text(realmDisplayLabel(skill.realm))),
                        for (final level in _levels)
                          DataCell(_buildCell(context, skill, level)),
                      ],
                    ),
                ],
              ),
            ),
          )
        else
          for (final skill in rows)
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppTokens.spaceXs,
                children: [
                  Text(
                    skill.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    realmDisplayLabel(skill.realm),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTokens.secondaryTextColor(context),
                    ),
                  ),
                  Wrap(
                    spacing: AppTokens.spaceXs,
                    runSpacing: AppTokens.spaceXs,
                    children: [
                      for (final level in skill.availableLevels)
                        _buildCell(context, skill, level),
                    ],
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    CurriculumSkill skill,
    DifficultyState level,
  ) {
    if (!skill.availableLevels.contains(level)) {
      return const Text('—');
    }
    final progress = state.progressBySkillId[skill.id]?.levels[level]?.state;
    final verified =
        state.verificationsBySkillId[skill.id]?.levels.containsKey(level) ??
        false;
    final label = verified
        ? '${shortDifficultyLabel(level)}: Verified'
        : switch (progress) {
            LevelState.PROFICIENT =>
              '${shortDifficultyLabel(level)}: Proficient',
            LevelState.LEARNING => '${shortDifficultyLabel(level)}: Learning',
            _ => '${shortDifficultyLabel(level)}: —',
          };

    return ActionChip(
      key: Key('matrixCell_${skill.id}_${level.name}'),
      avatar: verified
          ? const Icon(Icons.verified, size: 16)
          : progress == LevelState.PROFICIENT
          ? const Icon(Icons.pending_actions_outlined, size: 16)
          : null,
      label: Text(label),
      onPressed: () {
        if (canVerify && (progress == LevelState.PROFICIENT || verified)) {
          onVerifyCell(skill, level, verified: !verified);
        } else {
          onSelectCell(skill, level);
        }
      },
    );
  }

  List<CurriculumSkill> _matchingSkills() {
    return state.subjectSkills.where((skill) {
      final progress = state.progressBySkillId[skill.id];
      final verification = state.verificationsBySkillId[skill.id];
      for (final level in skill.availableLevels) {
        final selfState = progress?.levels[level]?.state;
        final isVerified = verification?.levels.containsKey(level) ?? false;
        switch (state.matrixFilter) {
          case AbilityMatrixFilter.needsReview:
            if (selfState == LevelState.PROFICIENT && !isVerified) return true;
          case AbilityMatrixFilter.verified:
            if (isVerified) return true;
          case AbilityMatrixFilter.allWithActivity:
            if (selfState != null || isVerified) return true;
        }
      }
      return false;
    }).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
