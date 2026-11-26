import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/cubit/skill_tree_v2_state.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_helpers.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/widgets/skill_family_icon.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Lightweight in-memory progress summary for a single Skill Family, computed
/// directly from [SkillTreeV2State] without additional backend reads.
class SkillFamilyProgressSummary {
  const SkillFamilyProgressSummary({
    required this.totalSkills,
    required this.startedSkills,
    required this.learningLevels,
    required this.proficientLevels,
    required this.verifiedLevels,
    required this.totalLevels,
  });

  factory SkillFamilyProgressSummary.fromState({
    required List<CurriculumSkill> skills,
    required Map<String, SkillProgressRecord> progressBySkillId,
    required Map<String, SkillVerificationRecord> verificationsBySkillId,
  }) {
    var startedSkills = 0;
    var learningLevels = 0;
    var proficientLevels = 0;
    var verifiedLevels = 0;
    var totalLevels = 0;

    for (final skill in skills) {
      totalLevels += skill.availableLevels.length;
      final progress = progressBySkillId[skill.id];
      final verification = verificationsBySkillId[skill.id];
      var skillStarted = false;

      for (final level in skill.availableLevels) {
        final verified = verification?.levels.containsKey(level) ?? false;
        final selfState = progress?.levels[level]?.state;
        if (verified) {
          verifiedLevels++;
          proficientLevels++;
          skillStarted = true;
        } else if (selfState == LevelState.PROFICIENT) {
          proficientLevels++;
          skillStarted = true;
        } else if (selfState == LevelState.LEARNING) {
          learningLevels++;
          skillStarted = true;
        }
      }
      if (skillStarted) startedSkills++;
    }

    return SkillFamilyProgressSummary(
      totalSkills: skills.length,
      startedSkills: startedSkills,
      learningLevels: learningLevels,
      proficientLevels: proficientLevels,
      verifiedLevels: verifiedLevels,
      totalLevels: totalLevels,
    );
  }

  final int totalSkills;
  final int startedSkills;
  final int learningLevels;
  final int proficientLevels;
  final int verifiedLevels;
  final int totalLevels;

  double get completionRatio =>
      totalLevels == 0 ? 0 : (proficientLevels / totalLevels).clamp(0, 1);

  String get skillCountLabel =>
      '$totalSkills ${totalSkills == 1 ? 'skill' : 'skills'}';

  String? get progressLabel {
    if (startedSkills == 0) return null;
    if (verifiedLevels > 0) {
      return '$verifiedLevels verified · $startedSkills/$totalSkills started';
    }
    if (proficientLevels > 0) {
      return '$proficientLevels/$totalLevels proficient';
    }
    return '$startedSkills/$totalSkills learning';
  }
}

/// Phase 2 prototype Skill Family card featuring a custom monochrome vector
/// emblem, compact collapsed header (name, count, optional progress, open cue),
/// and expandable description + simplified skill previews.
class SkillFamilyCardPrototype extends StatelessWidget {
  const SkillFamilyCardPrototype({
    super.key,
    required this.family,
    required this.skills,
    required this.progressBySkillId,
    required this.verificationsBySkillId,
    required this.isExpanded,
    required this.onToggle,
    required this.onSelectSkill,
    this.selectedSkillId,
    this.showProgress = false,
    this.isEnabled = true,
  });

  final SkillFamily family;
  final List<CurriculumSkill> skills;
  final Map<String, SkillProgressRecord> progressBySkillId;
  final Map<String, SkillVerificationRecord> verificationsBySkillId;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<CurriculumSkill> onSelectSkill;
  final String? selectedSkillId;
  final bool showProgress;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = SkillFamilyProgressSummary.fromState(
      skills: skills,
      progressBySkillId: progressBySkillId,
      verificationsBySkillId: verificationsBySkillId,
    );
    final containsSelectedSkill =
        selectedSkillId != null &&
        skills.any((skill) => skill.id == selectedSkillId);
    final iconState = !isEnabled
        ? SkillFamilyIconState.disabled
        : (isExpanded || containsSelectedSkill)
        ? SkillFamilyIconState.selected
        : SkillFamilyIconState.normal;

    final expandDuration = AppTokens.motionDuration(context);
    final secondaryColor = AppTokens.secondaryTextColor(context);
    final accent = AppTokens.accentColor(context);
    final progressLabel = showProgress ? summary.progressLabel : null;

    return RepaintBoundary(
      child: AppSurfaceCard(
        key: Key('prototypeSkillFamily_${family.id}'),
        padding: const EdgeInsets.all(AppTokens.spaceSm + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: isExpanded ? AppTokens.spaceSm : 0,
          children: [
            Semantics(
              button: true,
              enabled: isEnabled,
              expanded: isExpanded,
              label:
                  '${family.name}, ${summary.skillCountLabel}'
                  '${progressLabel == null ? '' : ', $progressLabel'}',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('prototypeSkillFamilyHeader_${family.id}'),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  hoverColor: AppTokens.hoverOverlay(context),
                  highlightColor: AppTokens.pressOverlay(context),
                  focusColor: AppTokens.focusOverlay(context),
                  splashColor: AppTokens.pressOverlay(context),
                  onTap: isEnabled ? onToggle : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppTokens.minTouchTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceXs,
                        vertical: AppTokens.spaceXs,
                      ),
                      child: Row(
                        children: [
                          SkillFamilyIconBadge(
                            familyId: family.id,
                            fallbackRealm: family.realm,
                            state: iconState,
                            semanticLabel: '${family.name} illustration',
                          ),
                          const SizedBox(width: AppTokens.spaceMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              spacing: 4,
                              children: [
                                Text(
                                  family.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTokens.sectionTitleStyle(
                                    context,
                                  ).copyWith(fontSize: 17, height: 1.2),
                                ),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    _CompactMetaPill(
                                      label: summary.skillCountLabel,
                                      highlight:
                                          iconState ==
                                          SkillFamilyIconState.selected,
                                    ),
                                    if (progressLabel != null)
                                      Text(
                                        progressLabel,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: accent,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                  ],
                                ),
                                if (showProgress && summary.startedSkills > 0)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: summary.completionRatio > 0
                                          ? summary.completionRatio
                                          : 0.12,
                                      minHeight: 3.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTokens.spaceSm),
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.32),
                            ),
                            child: AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0.0,
                              duration: expandDuration,
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.expand_more,
                                size: 20,
                                color: isExpanded ? accent : secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (expandDuration == Duration.zero) ...[
              if (isExpanded)
                _buildExpandedBody(context, secondaryColor)
              else
                const SizedBox.shrink(),
            ] else
              ClipRect(
                child: AnimatedSize(
                  duration: expandDuration,
                  reverseDuration: AppTokens.motionDuration(
                    context,
                    const Duration(milliseconds: 150),
                  ),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? _buildExpandedBody(context, secondaryColor)
                      : const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedBody(BuildContext context, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppTokens.spaceSm,
      children: [
        if (family.description.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: AppTokens.spaceXs,
              right: AppTokens.spaceXs,
              top: 2,
            ),
            child: Text(
              family.description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: secondaryColor),
            ),
          ),
        for (final skill in skills)
          CompactSkillPreviewRow(
            skill: skill,
            isSelected: skill.id == selectedSkillId,
            progress: progressBySkillId[skill.id],
            verification: verificationsBySkillId[skill.id],
            onTap: () => onSelectSkill(skill),
          ),
      ],
    );
  }
}

/// Alternative 2-column illustrated family tile evaluated for mobile and
/// tablet layouts in the design comparison prototype.
class SkillFamilyGridTilePrototype extends StatelessWidget {
  const SkillFamilyGridTilePrototype({
    super.key,
    required this.family,
    required this.skills,
    required this.progressBySkillId,
    required this.verificationsBySkillId,
    required this.isSelected,
    required this.onTap,
    this.showProgress = false,
  });

  final SkillFamily family;
  final List<CurriculumSkill> skills;
  final Map<String, SkillProgressRecord> progressBySkillId;
  final Map<String, SkillVerificationRecord> verificationsBySkillId;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = SkillFamilyProgressSummary.fromState(
      skills: skills,
      progressBySkillId: progressBySkillId,
      verificationsBySkillId: verificationsBySkillId,
    );
    final iconState = isSelected
        ? SkillFamilyIconState.selected
        : SkillFamilyIconState.normal;
    final secondaryColor = AppTokens.secondaryTextColor(context);

    return RepaintBoundary(
      child: AppSurfaceCard(
        key: Key('prototypeSkillFamilyGrid_${family.id}'),
        padding: const EdgeInsets.all(AppTokens.spaceSm + 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              SkillFamilyIconBadge(
                familyId: family.id,
                fallbackRealm: family.realm,
                badgeSize: 64,
                iconSize: 48,
                state: iconState,
                semanticLabel: '${family.name} illustration',
              ),
              Text(
                family.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.sectionTitleStyle(
                  context,
                ).copyWith(fontSize: 15, height: 1.2),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  Text(
                    summary.skillCountLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: secondaryColor,
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 15, color: secondaryColor),
                ],
              ),
              if (showProgress && summary.startedSkills > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: summary.completionRatio > 0
                        ? summary.completionRatio
                        : 0.14,
                    minHeight: 3.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simplified individual skill preview row showing skill title, compact
/// level/status badges, and selection affordance while keeping full summaries
/// and educational criteria inside the skill detail panel.
class CompactSkillPreviewRow extends StatelessWidget {
  const CompactSkillPreviewRow({
    super.key,
    required this.skill,
    required this.isSelected,
    required this.progress,
    required this.verification,
    required this.onTap,
  });

  final CurriculumSkill skill;
  final bool isSelected;
  final SkillProgressRecord? progress;
  final SkillVerificationRecord? verification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppTokens.radiusSm);

    return AppSelectionHighlight(
      selected: isSelected,
      backgroundColor: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : (isDark
                ? AppTokens.midnightInputFill
                : theme.colorScheme.surfaceContainerLow),
      child: DecoratedBox(
        decoration: isSelected
            ? const BoxDecoration()
            : BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: isDark
                      ? AppTokens.cardBorderDark.withValues(alpha: 0.55)
                      : theme.dividerColor.withValues(alpha: 0.4),
                ),
              ),
        child: InkWell(
          key: Key('prototypeSkillRow_${skill.id}'),
          borderRadius: radius,
          hoverColor: AppTokens.hoverOverlay(context),
          highlightColor: AppTokens.pressOverlay(context),
          focusColor: AppTokens.focusOverlay(context),
          splashColor: AppTokens.pressOverlay(context),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTokens.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMd,
                vertical: AppTokens.spaceSm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Text(
                          skill.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final level in skill.availableLevels)
                              _CompactLevelBadge(
                                level: level,
                                selfState: progress?.levels[level]?.state,
                                isVerified:
                                    verification?.levels.containsKey(level) ??
                                    false,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.spaceSm),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppTokens.secondaryTextColor(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactMetaPill extends StatelessWidget {
  const _CompactMetaPill({required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = highlight
        ? AppTokens.accentColor(context)
        : AppTokens.secondaryTextColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: highlight
            ? AppTokens.accentColor(context).withValues(alpha: 0.14)
            : (isDark
                  ? AppTokens.midnightBase.withValues(alpha: 0.65)
                  : theme.colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight
              ? AppTokens.accentColor(context).withValues(alpha: 0.5)
              : theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CompactLevelBadge extends StatelessWidget {
  const _CompactLevelBadge({
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

    final (IconData? icon, Color bg, Color fg) = isVerified
        ? (
            Icons.verified,
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
          )
        : switch (selfState) {
            LevelState.PROFICIENT => (
              Icons.check_circle_outline,
              theme.colorScheme.tertiaryContainer,
              theme.colorScheme.onTertiaryContainer,
            ),
            LevelState.LEARNING => (
              Icons.school_outlined,
              theme.colorScheme.secondaryContainer,
              theme.colorScheme.onSecondaryContainer,
            ),
            _ => (
              null,
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.onSurfaceVariant,
            ),
          };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTokens.cardBorderDark.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(short, style: theme.textTheme.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
