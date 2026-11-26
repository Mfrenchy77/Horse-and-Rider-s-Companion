import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/guest_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/skill_tree_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_icon.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Illustrated Skill Family & compact skill list for Skill Tree 2.0
/// Explore Skills.
///
/// Adapts across viewports without additional Firestore reads:
/// - `< 600px` (mobile) & `>= 900px` (desktop master rail): 1-column cards.
/// - `600px .. < 900px` (tablet, when not searching): 2-column family grid
///   with full-width inline expansion below the active row.
class SkillFamilyListV2 extends StatelessWidget {
  const SkillFamilyListV2({
    super.key,
    required this.state,
    required this.onSelectSkill,
    required this.onToggleFamily,
    this.isAdminEditMode = false,
    this.onEditFamily,
    this.onAddSkillToFamily,
    this.contributorNames = const [],
  });

  final SkillTreeV2State state;
  final ValueChanged<CurriculumSkill> onSelectSkill;
  final ValueChanged<String> onToggleFamily;
  final bool isAdminEditMode;
  final ValueChanged<SkillFamily>? onEditFamily;
  final ValueChanged<SkillFamily>? onAddSkillToFamily;
  final List<String> contributorNames;

  @override
  Widget build(BuildContext context) {
    final visible = state.visibleSkills;
    final isSearching = state.searchQuery.trim().isNotEmpty;

    // Group visible skills by familyId in a single pass.
    final skillsByFamilyId = <String, List<CurriculumSkill>>{};
    for (final skill in visible) {
      skillsByFamilyId.putIfAbsent(skill.familyId, () => []).add(skill);
    }
    for (final list in skillsByFamilyId.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final candidateFamilies = isSearching
        ? (state.families
              .where(
                (f) =>
                    f.subject == state.subject &&
                    (skillsByFamilyId[f.id]?.isNotEmpty ?? false),
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        : state.realmFamilies;

    final visibleFamilies = [
      for (final family in candidateFamilies)
        if ((skillsByFamilyId[family.id]?.isNotEmpty ?? false) ||
            (isAdminEditMode && !isSearching))
          family,
    ];

    if (visibleFamilies.isEmpty) {
      return AppSurfaceCard(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 36,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              isSearching
                  ? 'No matching skills'
                  : 'No skills in this category yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTokens.spaceXs),
            Text(
              isSearching
                  ? 'Try another equestrian term or switch between Rider and '
                        'Horse.'
                  : 'Skills for this area will appear here once added.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final familyEntries = [
      for (var i = 0; i < visibleFamilies.length; i++)
        _FamilyRenderEntry(
          index: i,
          family: visibleFamilies[i],
          skills: skillsByFamilyId[visibleFamilies[i].id] ?? const [],
          expanded:
              isSearching ||
              state.expandedFamilyIds.contains(visibleFamilies[i].id),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = MediaQuery.sizeOf(context).width;
        final isTabletGrid =
            !isSearching && constraints.maxWidth >= 520 && viewportWidth < 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTokens.spaceMd,
          children: [
            if (isTabletGrid)
              ..._buildTabletGridRows(context, familyEntries)
            else
              for (final entry in familyEntries)
                _buildSingleColumnCard(
                  entry,
                  showSelectionHighlight: viewportWidth >= 900,
                ),
            if (contributorNames.isNotEmpty)
              _ContributorsFooter(names: contributorNames),
          ],
        );
      },
    );
  }

  Widget _buildSingleColumnCard(
    _FamilyRenderEntry entry, {
    required bool showSelectionHighlight,
  }) {
    final hasSelectedSkill =
        showSelectionHighlight &&
        entry.skills.any((s) => s.id == state.selectedSkillId);
    final card = AppSurfaceCard(
      key: Key('skillFamily_${entry.family.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FamilyHeaderTile(
            family: entry.family,
            skillCount: entry.skills.length,
            expanded: entry.expanded,
            hasSelectedSkill: hasSelectedSkill,
            isSearching: state.searchQuery.trim().isNotEmpty,
            isAdminEditMode: isAdminEditMode,
            onToggle: () => onToggleFamily(entry.family.id),
            onEditFamily: onEditFamily == null
                ? null
                : () => onEditFamily!(entry.family),
          ),
          if (entry.expanded)
            _ExpandedFamilySkillsPanel(
              entry: entry,
              selectedSkillId: state.selectedSkillId,
              progressBySkillId: state.progressBySkillId,
              verificationsBySkillId: state.verificationsBySkillId,
              isAdminEditMode: isAdminEditMode,
              onSelectSkill: onSelectSkill,
              onAddSkillToFamily: onAddSkillToFamily,
            ),
        ],
      ),
    );

    if (entry.index != 0) return card;
    return _wrapWithFamilyTourKey(card);
  }

  List<Widget> _buildTabletGridRows(
    BuildContext context,
    List<_FamilyRenderEntry> entries,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      final left = entries[i];
      final right = i + 1 < entries.length ? entries[i + 1] : null;
      rows.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppTokens.spaceSm,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildGridTileCard(context, left)),
                  const SizedBox(width: AppTokens.spaceMd),
                  Expanded(
                    child: right == null
                        ? const SizedBox.shrink()
                        : _buildGridTileCard(context, right),
                  ),
                ],
              ),
            ),
            if (left.expanded) _buildTabletExpandedDrawer(context, left),
            if (right != null && right.expanded)
              _buildTabletExpandedDrawer(context, right),
          ],
        ),
      );
    }
    return rows;
  }

  Widget _buildGridTileCard(BuildContext context, _FamilyRenderEntry entry) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppTokens.coralAccent : theme.colorScheme.primary;
    final activeBorder = entry.expanded ? accent.withValues(alpha: 0.65) : null;
    final tile = AppSurfaceCard(
      key: Key('skillFamily_${entry.family.id}'),
      padding: EdgeInsets.zero,
      borderColor: activeBorder,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: _FamilyHeaderTile(
          family: entry.family,
          skillCount: entry.skills.length,
          expanded: entry.expanded,
          hasSelectedSkill: false,
          isSearching: false,
          isAdminEditMode: isAdminEditMode,
          onToggle: () => onToggleFamily(entry.family.id),
          onEditFamily: onEditFamily == null
              ? null
              : () => onEditFamily!(entry.family),
        ),
      ),
    );

    if (entry.index != 0) return tile;
    return _wrapWithFamilyTourKey(tile);
  }

  Widget _buildTabletExpandedDrawer(
    BuildContext context,
    _FamilyRenderEntry entry,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppTokens.coralAccent : theme.colorScheme.primary;
    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: accent.withValues(alpha: 0.45),
      child: _ExpandedFamilySkillsPanel(
        entry: entry,
        selectedSkillId: state.selectedSkillId,
        progressBySkillId: state.progressBySkillId,
        verificationsBySkillId: state.verificationsBySkillId,
        isAdminEditMode: isAdminEditMode,
        onSelectSkill: onSelectSkill,
        onAddSkillToFamily: onAddSkillToFamily,
        showTopDivider: false,
      ),
    );
  }

  Widget _wrapWithFamilyTourKey(Widget child) {
    return ValueListenableBuilder<bool>(
      valueListenable: SkillTreeSpotlightTour.isTourActive,
      builder: (context, isMemberTourActive, inner) {
        return KeyedSubtree(
          key: isMemberTourActive
              ? SkillTreeSpotlightTour.familyKey
              : GuestSpotlightTour.skillTreeFamilyKey,
          child: inner!,
        );
      },
      child: child,
    );
  }
}

class _FamilyRenderEntry {
  const _FamilyRenderEntry({
    required this.index,
    required this.family,
    required this.skills,
    required this.expanded,
  });

  final int index;
  final SkillFamily family;
  final List<CurriculumSkill> skills;
  final bool expanded;
}

class _FamilyHeaderTile extends StatelessWidget {
  const _FamilyHeaderTile({
    required this.family,
    required this.skillCount,
    required this.expanded,
    required this.hasSelectedSkill,
    required this.isSearching,
    required this.isAdminEditMode,
    required this.onToggle,
    this.onEditFamily,
  });

  final SkillFamily family;
  final int skillCount;
  final bool expanded;
  final bool hasSelectedSkill;
  final bool isSearching;
  final bool isAdminEditMode;
  final VoidCallback onToggle;
  final VoidCallback? onEditFamily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final countLabel = '$skillCount ${skillCount == 1 ? 'skill' : 'skills'}';
    final selected = expanded || hasSelectedSkill;

    return Semantics(
      button: true,
      expanded: expanded,
      label: '${family.name}, $countLabel',
      child: InkWell(
        key: Key('skillFamilyHeader_${family.id}'),
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        onTap: isSearching ? null : onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceMd,
            vertical: AppTokens.spaceMd,
          ),
          child: Row(
            children: [
              SkillFamilyIconBadge(
                familyId: family.id,
                fallbackRealm: family.realm,
                badgeSize: 54,
                iconSize: 38,
                state: selected
                    ? SkillFamilyIconState.selected
                    : SkillFamilyIconState.normal,
              ),
              const SizedBox(width: AppTokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      family.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      countLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTokens.secondaryTextDark
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAdminEditMode && onEditFamily != null)
                IconButton(
                  key: Key('editFamilyButton_${family.id}'),
                  tooltip: 'Edit family',
                  visualDensity: VisualDensity.compact,
                  onPressed: onEditFamily,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
              const SizedBox(width: AppTokens.spaceXs),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0.0,
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.expand_more,
                  color: selected
                      ? (isDark
                            ? AppTokens.coralAccent
                            : theme.colorScheme.primary)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedFamilySkillsPanel extends StatelessWidget {
  const _ExpandedFamilySkillsPanel({
    required this.entry,
    required this.selectedSkillId,
    required this.progressBySkillId,
    required this.verificationsBySkillId,
    required this.isAdminEditMode,
    required this.onSelectSkill,
    this.onAddSkillToFamily,
    this.showTopDivider = true,
  });

  final _FamilyRenderEntry entry;
  final String? selectedSkillId;
  final Map<String, SkillProgressRecord> progressBySkillId;
  final Map<String, SkillVerificationRecord> verificationsBySkillId;
  final bool isAdminEditMode;
  final ValueChanged<CurriculumSkill> onSelectSkill;
  final ValueChanged<SkillFamily>? onAddSkillToFamily;
  final bool showTopDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasDescription = entry.family.description.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.spaceMd,
        0,
        AppTokens.spaceMd,
        AppTokens.spaceMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTopDivider)
            Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: isDark ? 0.3 : 0.18),
            ),
          if (!showTopDivider) const SizedBox(height: AppTokens.spaceMd),
          if (hasDescription) ...[
            if (showTopDivider) const SizedBox(height: AppTokens.spaceSm),
            Text(
              entry.family.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppTokens.secondaryTextDark
                    : theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.spaceSm),
          for (
            var skillIdx = 0;
            skillIdx < entry.skills.length;
            skillIdx++
          ) ...[
            if (skillIdx > 0) const SizedBox(height: AppTokens.spaceXs),
            _buildSkillRow(
              entry.skills[skillIdx],
              isFirstTourTarget: entry.index == 0 && skillIdx == 0,
            ),
          ],
          if (isAdminEditMode && onAddSkillToFamily != null) ...[
            const SizedBox(height: AppTokens.spaceSm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: Key('addSkillButton_${entry.family.id}'),
                onPressed: () => onAddSkillToFamily!(entry.family),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add skill to family'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillRow(
    CurriculumSkill skill, {
    required bool isFirstTourTarget,
  }) {
    final row = _SkillRowCard(
      skill: skill,
      selected: selectedSkillId == skill.id,
      progress: progressBySkillId[skill.id],
      verification: verificationsBySkillId[skill.id],
      onTap: () {
        GuestSpotlightTour.notifySkillSelected();
        onSelectSkill(skill);
      },
    );
    if (!isFirstTourTarget) return row;

    return ValueListenableBuilder<bool>(
      valueListenable: SkillTreeSpotlightTour.isTourActive,
      builder: (context, isMemberTourActive, inner) {
        return KeyedSubtree(
          key: isMemberTourActive
              ? SkillTreeSpotlightTour.skillRowKey
              : GuestSpotlightTour.skillTreeSkillRowKey,
          child: inner!,
        );
      },
      child: row,
    );
  }
}

class _ContributorsFooter extends StatelessWidget {
  const _ContributorsFooter({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSurfaceCard(
      key: const Key('communityContributorsCard'),
      padding: const EdgeInsets.all(AppTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.diversity_3_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTokens.spaceXs),
              Text(
                'Community Contributors',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceXs),
          Text(
            'With contributions from ${names.join(', ')} and other members '
            'who help refine the horsemanship curriculum.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillRowCard extends StatelessWidget {
  const _SkillRowCard({
    required this.skill,
    required this.selected,
    required this.progress,
    required this.verification,
    required this.onTap,
  });

  final CurriculumSkill skill;
  final bool selected;
  final SkillProgressRecord? progress;
  final SkillVerificationRecord? verification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppTokens.coralAccent : theme.colorScheme.primary;
    final bgColor = selected
        ? accent.withValues(alpha: isDark ? 0.14 : 0.08)
        : (isDark
              ? AppTokens.midnightBase.withValues(alpha: 0.45)
              : theme.colorScheme.surfaceContainerLowest.withValues(
                  alpha: 0.7,
                ));
    final borderColor = selected
        ? accent.withValues(alpha: 0.72)
        : theme.dividerColor.withValues(alpha: isDark ? 0.35 : 0.2);

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        key: Key('skillCard_${skill.id}'),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceMd,
              vertical: AppTokens.spaceSm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      Text(
                        skill.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final level in skill.availableLevels)
                            _LevelStatusPill(
                              level: level,
                              state: progress?.levels[level]?.state,
                              verified:
                                  verification?.levels.containsKey(level) ??
                                  false,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.spaceXs),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: selected ? accent : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelStatusPill extends StatelessWidget {
  const _LevelStatusPill({
    required this.level,
    required this.state,
    required this.verified,
  });

  final DifficultyState level;
  final LevelState? state;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final label = shortDifficultyLabel(level);

    Color bg;
    Color fg;
    IconData? icon;
    if (verified) {
      bg = AppTokens.successDark.withValues(alpha: 0.22);
      fg = isDark ? AppTokens.successDark : Colors.green.shade800;
      icon = Icons.verified;
    } else if (state == LevelState.PROFICIENT) {
      bg = AppTokens.successDark.withValues(alpha: 0.14);
      fg = isDark ? AppTokens.successDark : Colors.green.shade800;
      icon = Icons.check_circle_outline_rounded;
    } else if (state == LevelState.LEARNING) {
      bg = AppTokens.warningDark.withValues(alpha: 0.16);
      fg = isDark ? AppTokens.warningDark : Colors.orange.shade900;
      icon = Icons.school_outlined;
    } else {
      bg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
      fg = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
