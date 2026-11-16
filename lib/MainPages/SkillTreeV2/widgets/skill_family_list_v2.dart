import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class SkillFamilyListV2 extends StatelessWidget {
  const SkillFamilyListV2({
    super.key,
    required this.state,
    required this.onSelectSkill,
    required this.onToggleFamily,
    this.isAdminEditMode = false,
    this.onEditFamily,
    this.onAddSkillToFamily,
  });

  final SkillTreeV2State state;
  final ValueChanged<CurriculumSkill> onSelectSkill;
  final ValueChanged<String> onToggleFamily;
  final bool isAdminEditMode;
  final ValueChanged<SkillFamily>? onEditFamily;
  final ValueChanged<SkillFamily>? onAddSkillToFamily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = state.searchQuery.trim().isNotEmpty;
    final visible = state.visibleSkills;

    final families = isSearching
        ? (state.families
              .where(
                (f) =>
                    f.subject == state.subject &&
                    visible.any((s) => s.familyId == f.id),
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        : state.realmFamilies;

    if (visible.isEmpty && !(isAdminEditMode && !isSearching && families.isNotEmpty)) {
      return AppSurfaceCard(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          child: Text(
            isSearching
                ? 'No skills match "${state.searchQuery.trim()}".'
                : 'No skills in this category yet.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: families.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.spaceMd),
      itemBuilder: (context, index) {
        final family = families[index];
        final familySkills =
            visible.where((s) => s.familyId == family.id).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (familySkills.isEmpty && !(isAdminEditMode && !isSearching)) {
          return const SizedBox.shrink();
        }

        final isExpanded =
            isSearching || state.expandedFamilyIds.contains(family.id);

        return RepaintBoundary(
          child: AppSurfaceCard(
            key: Key('skillFamily_${family.id}'),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppTokens.spaceSm,
            children: [
              Semantics(
                button: true,
                expanded: isExpanded,
                label: family.name,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('skillFamilyHeader_${family.id}'),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    onTap: isSearching ? null : () => onToggleFamily(family.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.spaceXs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              spacing: AppTokens.spaceXs,
                              children: [
                                Text(
                                  family.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (family.description.trim().isNotEmpty)
                                  Text(
                                    family.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTokens.secondaryTextColor(
                                        context,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceSm),
                          if (isAdminEditMode && onEditFamily != null)
                            IconButton(
                              key: Key('editFamilyButton_${family.id}'),
                              tooltip: 'Edit Skill Family',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => onEditFamily!(family),
                            ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppTokens.secondaryTextColor(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isExpanded) ...[
                for (final skill in familySkills)
                  _SkillRowCard(
                    skill: skill,
                    subtitle: isSearching
                        ? realmDisplayLabel(skill.realm)
                        : null,
                    isSelected: skill.id == state.selectedSkillId,
                    progress: state.progressBySkillId[skill.id],
                    verification: state.verificationsBySkillId[skill.id],
                    onTap: () => onSelectSkill(skill),
                  ),
                if (isAdminEditMode && onAddSkillToFamily != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: Key('addSkillButton_${family.id}'),
                      onPressed: () => onAddSkillToFamily!(family),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Skill'),
                    ),
                  ),
              ],
            ],
          ),
        ),
        );
      },
    );
  }
}

class _SkillRowCard extends StatelessWidget {
  const _SkillRowCard({
    required this.skill,
    required this.isSelected,
    required this.progress,
    required this.verification,
    required this.onTap,
    this.subtitle,
  });

  final CurriculumSkill skill;
  final bool isSelected;
  final SkillProgressRecord? progress;
  final SkillVerificationRecord? verification;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSelectionHighlight(
      selected: isSelected,
      backgroundColor: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        key: Key('skillCard_${skill.id}'),
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
                      skill.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTokens.secondaryTextColor(context),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              if (skill.summary.trim().isNotEmpty)
                Text(
                  skill.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTokens.secondaryTextColor(context),
                  ),
                ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final level in skill.availableLevels)
                    _LevelStatusPill(
                      level: level,
                      selfState: progress?.levels[level]?.state,
                      isVerified:
                          verification?.levels.containsKey(level) ?? false,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelStatusPill extends StatelessWidget {
  const _LevelStatusPill({
    required this.level,
    required this.selfState,
    required this.isVerified,
  });

  final DifficultyState level;
  final LevelState? selfState;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final short = shortDifficultyLabel(level);
    final (IconData? icon, Color bg, Color fg, String suffix) = isVerified
        ? (
            Icons.verified,
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
            ' · Verified',
          )
        : switch (selfState) {
            LevelState.PROFICIENT => (
              Icons.check_circle_outline,
              theme.colorScheme.tertiaryContainer,
              theme.colorScheme.onTertiaryContainer,
              ' · Proficient',
            ),
            LevelState.LEARNING => (
              Icons.school_outlined,
              theme.colorScheme.secondaryContainer,
              theme.colorScheme.onSecondaryContainer,
              ' · Learning',
            ),
            _ => (
              null,
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.onSurfaceVariant,
              '',
            ),
          };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            '$short$suffix',
            style: theme.textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
