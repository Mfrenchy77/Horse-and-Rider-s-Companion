import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_repository.dart';
import 'package:horseandriderscompanion/MainPages/Dictionary/dictionary_text.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Displays optional, non-assessed "Develop This Skill" practical learning
/// guidance inside Skill Tree 2.0 skill detail panels.
///
/// Consumes only already-loaded [CurriculumSkill] data and the shared
/// [DictionaryRepository.entriesNotifier] cache so displaying or expanding any
/// section triggers zero additional backend reads.
class DevelopThisSkillSection extends StatefulWidget {
  const DevelopThisSkillSection({
    super.key,
    required this.skill,
    required this.allSkills,
    this.selectedLevel,
    this.onSelectRelatedSkill,
    this.dictionaryEntriesOverride,
  });

  final CurriculumSkill skill;
  final List<CurriculumSkill> allSkills;
  final DifficultyState? selectedLevel;
  final ValueChanged<String>? onSelectRelatedSkill;
  final List<DictionaryEntry>? dictionaryEntriesOverride;

  @override
  State<DevelopThisSkillSection> createState() =>
      _DevelopThisSkillSectionState();
}

class _DevelopThisSkillSectionState extends State<DevelopThisSkillSection> {
  bool _showMoreExercises = false;
  bool _showCommonDifficulties = false;

  @override
  void initState() {
    super.initState();
    if (widget.dictionaryEntriesOverride == null &&
        DictionaryRepository.peekCachedEntries == null) {
      unawaited(DictionaryRepository.cachedEntries());
    }
  }

  @override
  void didUpdateWidget(covariant DevelopThisSkillSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skill.id != widget.skill.id) {
      _showMoreExercises = false;
      _showCommonDifficulties = false;
    }
  }

  List<SkillPracticeExercise> _orderedExercises(SkillLearningGuide guide) {
    final exercises = guide.exercises;
    final selected = widget.selectedLevel;
    if (selected == null || exercises.length <= 1) return exercises;
    final matchIndex = exercises.indexWhere((e) => e.focusLevel == selected);
    if (matchIndex <= 0) return exercises;
    return [
      exercises[matchIndex],
      for (var i = 0; i < exercises.length; i++)
        if (i != matchIndex) exercises[i],
    ];
  }

  List<CurriculumSkill> _resolveRelatedSkills(SkillLearningGuide guide) {
    if (guide.relatedSkillIds.isEmpty) return const [];
    final byId = <String, CurriculumSkill>{
      for (final s in widget.allSkills) s.id: s,
    };
    final resolved = <CurriculumSkill>[];
    for (final id in guide.relatedSkillIds) {
      final skill = byId[id];
      if (skill != null && skill.id != widget.skill.id) {
        resolved.add(skill);
      }
    }
    return resolved;
  }

  List<DictionaryEntry> _resolveDictionaryEntries(
    SkillLearningGuide guide,
    List<DictionaryEntry> catalogue,
  ) {
    if (guide.relatedDictionaryTerms.isEmpty || catalogue.isEmpty) {
      return const [];
    }
    final bySlug = <String, DictionaryEntry>{
      for (final entry in catalogue) entry.slug.trim().toLowerCase(): entry,
    };
    final resolved = <DictionaryEntry>[];
    for (final slug in guide.relatedDictionaryTerms) {
      final entry = bySlug[slug.trim().toLowerCase()];
      if (entry != null) {
        resolved.add(entry);
      }
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.skill.learningGuide;
    if (guide == null || !guide.hasContent) {
      return const SizedBox.shrink();
    }

    final palette = _DevelopSkillPalette.of(context);
    final subjectLabel = widget.skill.subject == SkillSubject.horse
        ? 'Horse'
        : 'Rider';
    final orderedExercises = _orderedExercises(guide);
    final featuredExercise = orderedExercises.isEmpty
        ? null
        : orderedExercises.first;
    final secondaryExercises = orderedExercises.length > 1
        ? orderedExercises.sublist(1)
        : const <SkillPracticeExercise>[];
    final relatedSkills = _resolveRelatedSkills(guide);
    final isNarrow = MediaQuery.sizeOf(context).width < 420;
    final outerPadding = isNarrow ? 14.0 : 18.0;

    return Container(
      key: const Key('developThisSkillSection'),
      decoration: BoxDecoration(
        gradient: palette.outerGradient,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(color: palette.outerBorder),
      ),
      padding: EdgeInsets.all(outerPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            subjectLabel: subjectLabel,
            skillName: widget.skill.name,
            palette: palette,
          ),
          if (featuredExercise != null) ...[
            const SizedBox(height: 14),
            _ExerciseCard(
              key: const Key('developSkillFeaturedExerciseCard'),
              exercise: featuredExercise,
              entriesOverride: widget.dictionaryEntriesOverride,
              palette: palette,
            ),
          ],
          if (secondaryExercises.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DisclosureCard(
              toggleKey: const Key('developSkillMoreExercisesToggle'),
              icon: Icons.add_circle_outline,
              title: secondaryExercises.length == 1
                  ? 'Additional practice: ${secondaryExercises.first.title}'
                  : 'Additional practice (${secondaryExercises.length})',
              subtitle: secondaryExercises.length == 1
                  ? _focusBadgeText(secondaryExercises.first) ??
                        'Optional progression'
                  : 'Optional ways to vary and progress',
              expanded: _showMoreExercises,
              onToggle: () =>
                  setState(() => _showMoreExercises = !_showMoreExercises),
              palette: palette,
              expandedChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: [
                  for (var i = 0; i < secondaryExercises.length; i++)
                    _ExerciseCard(
                      key: Key('developSkillSecondaryExercise_$i'),
                      exercise: secondaryExercises[i],
                      entriesOverride: widget.dictionaryEntriesOverride,
                      palette: palette,
                    ),
                ],
              ),
            ),
          ],
          if (guide.hasCommonDifficulties) ...[
            const SizedBox(height: 10),
            _DisclosureCard(
              toggleKey: const Key('developSkillCommonDifficultiesToggle'),
              icon: Icons.help_outline_rounded,
              title: 'Common difficulties',
              subtitle: guide.commonDifficulties.length == 1
                  ? '1 typical snag & humane reset'
                  : '${guide.commonDifficulties.length} typical snags & '
                        'humane resets',
              expanded: _showCommonDifficulties,
              onToggle: () => setState(
                () => _showCommonDifficulties = !_showCommonDifficulties,
              ),
              palette: palette,
              expandedChild: _CommonDifficultiesList(
                difficulties: guide.commonDifficulties,
                entriesOverride: widget.dictionaryEntriesOverride,
                palette: palette,
              ),
            ),
          ],
          if (guide.hasTrainerInsight || guide.hasWelfareNote) ...[
            const SizedBox(height: 12),
            _InsightAndWelfareRow(
              trainerInsight: guide.trainerInsight,
              welfareNote: guide.welfareNote,
              entriesOverride: widget.dictionaryEntriesOverride,
              palette: palette,
            ),
          ],
          const SizedBox(height: 14),
          if (widget.dictionaryEntriesOverride case final overrideEntries?)
            _FooterRow(
              dictionaryEntries: _resolveDictionaryEntries(
                guide,
                overrideEntries,
              ),
              relatedSkills: relatedSkills,
              onSelectRelatedSkill: widget.onSelectRelatedSkill,
              palette: palette,
            )
          else
            ValueListenableBuilder<List<DictionaryEntry>?>(
              valueListenable: DictionaryRepository.entriesNotifier,
              builder: (context, cachedEntries, _) {
                final effectiveEntries =
                    cachedEntries ??
                    DictionaryRepository.peekCachedEntries ??
                    const <DictionaryEntry>[];
                return _FooterRow(
                  dictionaryEntries: _resolveDictionaryEntries(
                    guide,
                    effectiveEntries,
                  ),
                  relatedSkills: relatedSkills,
                  onSelectRelatedSkill: widget.onSelectRelatedSkill,
                  palette: palette,
                );
              },
            ),
        ],
      ),
    );
  }

  static String? _focusBadgeText(SkillPracticeExercise exercise) {
    final badge = exercise.badge?.trim();
    if (badge != null && badge.isNotEmpty) return badge;
    return switch (exercise.focusLevel) {
      DifficultyState.Introductory => 'Introductory focus',
      DifficultyState.Intermediate => 'Intermediate focus',
      DifficultyState.Advanced => 'Advanced focus',
      _ => null,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.subjectLabel,
    required this.skillName,
    required this.palette,
  });

  final String subjectLabel;
  final String skillName;
  final _DevelopSkillPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_outlined, size: 22, color: palette.coral),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Develop This Skill',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: 0.1,
                  color: palette.primaryText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Practical guidance for $subjectLabel · $skillName',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            color: palette.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.entriesOverride,
    required this.palette,
  });

  final SkillPracticeExercise exercise;
  final List<DictionaryEntry>? entriesOverride;
  final _DevelopSkillPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeLabel = (exercise.badge?.trim().isNotEmpty ?? false)
        ? exercise.badge!.trim().toUpperCase()
        : switch (exercise.focusLevel) {
            DifficultyState.Introductory => 'FOUNDATION EXERCISE',
            DifficultyState.Intermediate => 'PROGRESSION EXERCISE',
            DifficultyState.Advanced => 'REFINEMENT EXERCISE',
            _ => 'PRACTICAL EXERCISE',
          };
    final notice = exercise.whatToNotice?.trim();

    return Container(
      decoration: BoxDecoration(
        gradient: palette.innerGradient,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: palette.innerBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: palette.badgeBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.75,
                color: palette.badgeText,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            exercise.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              height: 1.25,
              color: palette.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          ContextualDictionaryText(
            text: exercise.summary,
            entriesOverride: entriesOverride,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.48,
              color: palette.bodyText,
            ),
          ),
          if (notice != null && notice.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                height: 1,
                thickness: 1,
                color: palette.dividerColor,
              ),
            ),
            Row(
              children: [
                Icon(Icons.visibility_outlined, size: 17, color: palette.coral),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'What to notice',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: palette.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ContextualDictionaryText(
              text: notice,
              entriesOverride: entriesOverride,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: palette.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DisclosureCard extends StatelessWidget {
  const _DisclosureCard({
    required this.toggleKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.palette,
    required this.expandedChild,
  });

  final Key toggleKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final _DevelopSkillPalette palette;
  final Widget expandedChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: palette.innerGradient,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: palette.innerBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: toggleKey,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: palette.coral),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: palette.primaryText,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: palette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0.0,
                      duration: AppTokens.motionDuration(context),
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppTokens.motionDuration(context),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: palette.dividerColor,
                        ),
                        const SizedBox(height: 12),
                        expandedChild,
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CommonDifficultiesList extends StatelessWidget {
  const _CommonDifficultiesList({
    required this.difficulties,
    required this.entriesOverride,
    required this.palette,
  });

  final List<SkillCommonDifficulty> difficulties;
  final List<DictionaryEntry>? entriesOverride;
  final _DevelopSkillPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        for (var i = 0; i < difficulties.length; i++) ...[
          if (i > 0)
            Divider(height: 1, thickness: 1, color: palette.dividerColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                difficulties[i].issue,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: palette.primaryText,
                ),
              ),
              ContextualDictionaryText(
                text: difficulties[i].guidance,
                entriesOverride: entriesOverride,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: palette.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InsightAndWelfareRow extends StatelessWidget {
  const _InsightAndWelfareRow({
    required this.trainerInsight,
    required this.welfareNote,
    required this.entriesOverride,
    required this.palette,
  });

  final String? trainerInsight;
  final String? welfareNote;
  final List<DictionaryEntry>? entriesOverride;
  final _DevelopSkillPalette palette;

  @override
  Widget build(BuildContext context) {
    final hasInsight =
        trainerInsight != null && trainerInsight!.trim().isNotEmpty;
    final hasWelfare = welfareNote != null && welfareNote!.trim().isNotEmpty;

    final insightCard = hasInsight
        ? _PrincipleCard(
            key: const Key('developSkillTrainerInsightCard'),
            icon: Icons.lightbulb_outline,
            title: "Trainer's Insight",
            body: trainerInsight!.trim(),
            entriesOverride: entriesOverride,
            palette: palette,
          )
        : null;

    final welfareCard = hasWelfare
        ? _PrincipleCard(
            key: const Key('developSkillWelfareCard'),
            icon: Icons.monitor_heart_outlined,
            title: 'Horse Welfare',
            body: welfareNote!.trim(),
            entriesOverride: entriesOverride,
            palette: palette,
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn =
            constraints.maxWidth >= 520 &&
            insightCard != null &&
            welfareCard != null;
        if (twoColumn) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: insightCard),
                const SizedBox(width: 12),
                Expanded(child: welfareCard),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [?insightCard, ?welfareCard],
        );
      },
    );
  }
}

class _PrincipleCard extends StatelessWidget {
  const _PrincipleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.entriesOverride,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<DictionaryEntry>? entriesOverride;
  final _DevelopSkillPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: palette.innerGradient,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: palette.innerBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: palette.coral),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: palette.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          ContextualDictionaryText(
            text: body,
            entriesOverride: entriesOverride,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: palette.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.dictionaryEntries,
    required this.relatedSkills,
    required this.onSelectRelatedSkill,
    required this.palette,
  });

  final List<DictionaryEntry> dictionaryEntries;
  final List<CurriculumSkill> relatedSkills;
  final ValueChanged<String>? onSelectRelatedSkill;
  final _DevelopSkillPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRelatedLinks =
        dictionaryEntries.isNotEmpty || relatedSkills.isNotEmpty;

    final educationalBadge = Tooltip(
      message:
          'Optional learning guidance. Does not affect proficiency state or '
          'instructor verification.',
      child: Container(
        key: const Key('developSkillEducationalBadge'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: palette.badgeBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.innerBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 14, color: palette.secondaryText),
            const SizedBox(width: 5),
            Text(
              'Educational',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.badgeText,
              ),
            ),
          ],
        ),
      ),
    );

    if (!hasRelatedLinks) {
      return Row(
        key: const Key('developSkillFooter'),
        mainAxisAlignment: MainAxisAlignment.end,
        children: [educationalBadge],
      );
    }

    final linkItems = <Widget>[
      Text(
        'Related:',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: palette.secondaryText,
        ),
      ),
      for (var i = 0; i < dictionaryEntries.length; i++) ...[
        if (i > 0)
          Text(
            '·',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.secondaryText,
            ),
          ),
        _DictionaryFooterLink(
          entry: dictionaryEntries[i],
          palette: palette,
        ),
      ],
      for (var i = 0; i < relatedSkills.length; i++) ...[
        if (dictionaryEntries.isNotEmpty || i > 0)
          Text(
            '·',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.secondaryText,
            ),
          ),
        _SkillFooterLink(
          skill: relatedSkills[i],
          onTap: onSelectRelatedSkill == null
              ? null
              : () => onSelectRelatedSkill!(relatedSkills[i].id),
          palette: palette,
        ),
      ],
    ];

    return LayoutBuilder(
      key: const Key('developSkillFooter'),
      builder: (context, constraints) {
        final linksWrap = Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: linkItems,
        );
        if (constraints.maxWidth < 400) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              linksWrap,
              Align(
                alignment: Alignment.centerRight,
                child: educationalBadge,
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: linksWrap),
            const SizedBox(width: 10),
            educationalBadge,
          ],
        );
      },
    );
  }
}

class _DictionaryFooterLink extends StatelessWidget {
  const _DictionaryFooterLink({
    required this.entry,
    required this.palette,
  });

  final DictionaryEntry entry;
  final _DevelopSkillPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Open Dictionary definition for ${entry.term}',
      child: Builder(
        builder: (linkContext) => InkWell(
          key: Key('developSkillDictTerm_${entry.slug}'),
          borderRadius: BorderRadius.circular(6),
          onTap: () => showDictionaryDefinitionDialog(
            linkContext,
            entry,
            originContext: linkContext,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            child: Text(
              entry.term,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.linkText,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: palette.linkText.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillFooterLink extends StatelessWidget {
  const _SkillFooterLink({
    required this.skill,
    required this.onTap,
    required this.palette,
  });

  final CurriculumSkill skill;
  final VoidCallback? onTap;
  final _DevelopSkillPalette palette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectPrefix = skill.subject == SkillSubject.horse
        ? 'Horse'
        : 'Rider';
    return Semantics(
      button: true,
      label: 'Open related skill $subjectPrefix · ${skill.name}',
      child: InkWell(
        key: Key('developSkillRelatedSkill_${skill.id}'),
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 13,
                color: palette.coral,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$subjectPrefix · ${skill.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.linkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DevelopSkillPalette {
  const _DevelopSkillPalette({
    required this.outerGradient,
    required this.outerBorder,
    required this.innerGradient,
    required this.innerBorder,
    required this.badgeBackground,
    required this.badgeText,
    required this.primaryText,
    required this.bodyText,
    required this.secondaryText,
    required this.linkText,
    required this.coral,
    required this.dividerColor,
  });

  factory _DevelopSkillPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (isDark) {
      return const _DevelopSkillPalette(
        outerGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0C2227), Color(0xFF08191D)],
        ),
        outerBorder: Color(0x475E8288),
        innerGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF153137), Color(0xFF112A30)],
        ),
        innerBorder: Color(0x3D628388),
        badgeBackground: Color(0xFF214046),
        badgeText: Color(0xFFD5E4E7),
        primaryText: AppTokens.primaryTextDark,
        bodyText: Color(0xFFDCE7EA),
        secondaryText: AppTokens.secondaryTextDark,
        linkText: Color(0xFFD2E3E6),
        coral: AppTokens.coralAccent,
        dividerColor: Color(0x33628388),
      );
    }
    return _DevelopSkillPalette(
      outerGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF3F8F9), Color(0xFFE9F3F5)],
      ),
      outerBorder: theme.colorScheme.outlineVariant.withValues(alpha: 0.75),
      innerGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF7FAFB)],
      ),
      innerBorder: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
      badgeBackground: const Color(0xFFE0ECEF),
      badgeText: const Color(0xFF1A434B),
      primaryText: theme.colorScheme.onSurface,
      bodyText: theme.colorScheme.onSurface.withValues(alpha: 0.90),
      secondaryText: theme.colorScheme.onSurfaceVariant,
      linkText: const Color(0xFF124E59),
      coral: const Color(0xFFC45B43),
      dividerColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
    );
  }

  final LinearGradient outerGradient;
  final Color outerBorder;
  final LinearGradient innerGradient;
  final Color innerBorder;
  final Color badgeBackground;
  final Color badgeText;
  final Color primaryText;
  final Color bodyText;
  final Color secondaryText;
  final Color linkText;
  final Color coral;
  final Color dividerColor;
}
