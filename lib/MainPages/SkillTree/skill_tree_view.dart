import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/app_bar_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_progress_badge.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateSkillDialog/skill_create_dialog.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_app_bar_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_title_search_bar.dart';
import 'package:horseandriderscompanion/Settings/skill_tree_layout.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class SkillTreeView extends StatefulWidget {
  const SkillTreeView({super.key, this.skillId});

  static const skillsListName = 'SkillsList';
  static const skillLevelName = 'SkillLevel';
  static const skillsListPath = '/Skills';
  static const skillLevelPath = 'Skill::$skillPathParam';
  static const skillPathParam = 'skillId';

  static void openSkill(GoRouter router, String id) =>
      router.goNamed(skillLevelName, pathParameters: {skillPathParam: id});

  final String? skillId;

  @override
  State<SkillTreeView> createState() => _SkillTreeViewState();
}

class _SkillTreeViewState extends State<SkillTreeView> {
  final _scroll = ScrollController();
  final _detail = GlobalKey();
  double _listOffset = 0;

  @override
  void initState() {
    super.initState();
    _syncRouteSkill();
  }

  @override
  void didUpdateWidget(covariant SkillTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skillId != widget.skillId) {
      _syncRouteSkill();
    }
  }

  void _syncRouteSkill() {
    final id = widget.skillId;
    if (id != null) {
      final cubit = context.read<AppCubit>()
        ..setSkillTree()
        ..setSkill(id);
      cubit.navigateToSkillLevel(skill: cubit.state.skill);
      _showDetail();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _showDetail() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final detail = _detail.currentContext;
      if (mounted &&
          detail != null &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        Scrollable.ensureVisible(
          detail,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
        );
      }
    });
  }

  void _closeDetail() {
    if (widget.skillId != null) {
      context.goNamed(SkillTreeView.skillsListName);
      return;
    }
    context.read<AppCubit>().navigateToSkillsList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(
          _listOffset.clamp(0.0, _scroll.position.maxScrollExtent),
        );
      }
    });
  }

  void _editSkill(AppState state, [Skill? skill]) {
    final cubit = context.read<AppCubit>();
    if (skill != null && !cubit.canEditSkill(skill)) {
      cubit.createError('You do not have permission to edit this skill');
      return;
    }
    final rider = state.usersProfile;
    if (rider == null) return;
    showDialog<CreateSkillDialog>(
      context: context,
      builder: (_) => CreateSkillDialog(
        skill: skill,
        isEdit: skill != null,
        allSkills: state.allSkills,
        isForRider: skill?.rider ?? state.isForRider,
        usersProfile: rider,
        position: skill?.position ?? state.sortedSkills.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final layout = SkillTreeLayoutScope.of(context);
    return BlocConsumer<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.skill?.id != current.skill?.id ||
          previous.skillTreeNavigation != current.skillTreeNavigation ||
          (widget.skillId != null && previous.allSkills != current.allSkills),
      buildWhen: (previous, current) =>
          previous.skill != current.skill ||
          previous.skillTreeNavigation != current.skillTreeNavigation ||
          previous.sortedSkills != current.sortedSkills ||
          previous.allSkills != current.allSkills ||
          previous.isGuest != current.isGuest ||
          previous.isEdit != current.isEdit ||
          previous.isViewing != current.isViewing ||
          previous.isForRider != current.isForRider ||
          previous.usersProfile != current.usersProfile ||
          previous.viewingProfile != current.viewingProfile ||
          previous.horseProfile != current.horseProfile ||
          previous.categorySortState != current.categorySortState ||
          previous.difficultySortState != current.difficultySortState,
      listener: (context, state) {
        if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
        if (widget.skillId case final id?) {
          if (state.skill == null && cubit.skillExists(id)) {
            cubit.setSkill(id);
            return;
          }
        }
        if (state.skillTreeNavigation == SkillTreeNavigation.SkillLevel) {
          _showDetail();
        }
      },
      builder: (context, state) {
        final showsDetail =
            widget.skillId != null ||
            state.skillTreeNavigation == SkillTreeNavigation.SkillLevel;
        final skills = state.sortedSkills.whereType<Skill>().toList();
        final canEdit =
            !state.isGuest && state.isEdit && state.usersProfile != null;
        final selectedId = showsDetail ? state.skill?.id : null;
        final details = showsDetail ? _skillDetails(selectedId) : null;

        LevelState levelFor(Skill skill) => getLevelState(
          skill: skill,
          profile: state.isViewing ? state.viewingProfile : state.usersProfile,
          horseProfile: state.isForRider ? null : state.horseProfile,
        );

        Widget row(Skill skill, {bool showStatus = true}) => _SkillLibraryRow(
          skill: skill,
          level: levelFor(skill),
          verified:
              isVerified(
                skill: skill,
                profile: state.isViewing
                    ? state.viewingProfile
                    : state.usersProfile,
                horseProfile: state.isForRider ? null : state.horseProfile,
              ) ??
              false,
          showStatus: showStatus,
          selected: selectedId == skill.id,
          onSelect: () {
            if (_scroll.hasClients) _listOffset = _scroll.offset;
            if (selectedId == skill.id) {
              if (layout == SkillTreeLayout.expandInPlace) {
                _closeDetail();
              } else {
                _showDetail();
              }
            } else {
              cubit.navigateToSkillLevel(skill: skill);
            }
          },
          onEdit: canEdit ? () => _editSkill(state, skill) : null,
        );

        return Scaffold(
          appBar: ThemedAppBar(
            leading: BackButton(
              onPressed: showsDetail
                  ? _closeDetail
                  : () => cubit.changeIndex(0),
            ),
            title: const SkillTreeSearchTitleBar(
              key: Key('skillTreeSearchTitleBar'),
            ),
            actions: const [
              AppBarSearchButton(),
              SkillTreeAppBarOverFlowMenu(),
            ],
          ),
          floatingActionButton: canEdit
              ? FloatingActionButton(
                  key: const Key('addSkillButton'),
                  tooltip: 'Add a skill',
                  onPressed: () => _editSkill(state),
                  child: const Icon(Icons.add),
                )
              : null,
          body: AppScaffoldBackdrop(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final wideLibrary =
                    layout == SkillTreeLayout.library &&
                    constraints.maxWidth >= 740;
                final completedCount = skills.where((skill) {
                  final level = levelFor(skill);
                  return level == LevelState.PROFICIENT ||
                      level == LevelState.VERIFIED;
                }).length;
                final progressRatio = skills.isEmpty
                    ? 0.0
                    : completedCount / skills.length;
                final header = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.isForRider ? 'Rider Skills' : 'Horse Skills',
                            style: AppTokens.sectionTitleStyle(
                              context,
                            ).copyWith(fontSize: 26),
                          ),
                        ),
                        if (skills.isNotEmpty)
                          _SkillProgressSummary(progress: progressRatio),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final category in CategorySortState.values)
                          ChoiceChip(
                            label: Text(
                              category == CategorySortState.In_Hand
                                  ? 'In hand'
                                  : category.name,
                            ),
                            selected: category == state.categorySortState,
                            selectedColor: isDark
                                ? AppTokens.coralAccent
                                : null,
                            backgroundColor: isDark
                                ? AppTokens.midnightButtonFill
                                : null,
                            side: isDark
                                ? BorderSide(
                                    color: category == state.categorySortState
                                        ? AppTokens.coralAccent
                                        : AppTokens.cardBorderDark,
                                  )
                                : null,
                            labelStyle: isDark
                                ? TextStyle(
                                    color: category == state.categorySortState
                                        ? AppTokens.coralText
                                        : AppTokens.primaryTextDark,
                                    fontWeight: FontWeight.w600,
                                  )
                                : null,
                            checkmarkColor: isDark ? AppTokens.coralText : null,
                            onSelected: (_) =>
                                cubit.categorySortChanged(category),
                          ),
                        SizedBox(
                          width: 196,
                          child: DropdownButtonFormField<DifficultySortState>(
                            key: ValueKey(state.difficultySortState),
                            initialValue: state.difficultySortState,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              for (final difficulty
                                  in DifficultySortState.values)
                                DropdownMenuItem(
                                  value: difficulty,
                                  child: Text(
                                    difficulty == DifficultySortState.All
                                        ? 'All levels'
                                        : difficulty.name,
                                  ),
                                ),
                            ],
                            onChanged: (difficulty) {
                              if (difficulty != null) {
                                cubit.difficultySortChanged(difficulty);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
                final selectedIsVisible = skills.any(
                  (skill) => skill.id == selectedId,
                );
                const emptySkills = AppEmptyState(
                  icon: Icons.account_tree_outlined,
                  title: 'No skills match these filters.',
                  description:
                      'Try choosing a different category or difficulty level.',
                );
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout == SkillTreeLayout.expandInPlace
                          ? 850
                          : 1320,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        wideLibrary ? 0 : 16,
                      ),
                      child: wideLibrary
                          ? Column(
                              key: const Key('skillLibraryWide'),
                              spacing: 16,
                              children: [
                                header,
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 20,
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: skills.isEmpty
                                            ? emptySkills
                                            : ListView.separated(
                                                primary: false,
                                                padding: const EdgeInsets.only(
                                                  bottom: 88,
                                                ),
                                                itemCount: skills.length,
                                                separatorBuilder: (_, _) =>
                                                    const SizedBox(height: 8),
                                                itemBuilder: (_, index) =>
                                                    row(skills[index]),
                                              ),
                                      ),
                                      Expanded(
                                        flex: 6,
                                        child: SingleChildScrollView(
                                          key: ValueKey(selectedId),
                                          primary: false,
                                          padding: const EdgeInsets.only(
                                            bottom: 88,
                                          ),
                                          child:
                                              details ??
                                              AppSurfaceCard(
                                                padding: const EdgeInsets.all(
                                                  24,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.touch_app_outlined,
                                                      color:
                                                          AppTokens.accentColor(
                                                            context,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Expanded(
                                                      child: Text(
                                                        'Select a skill to '
                                                        'view its details and '
                                                        'resources.',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : SingleChildScrollView(
                              key: ValueKey(switch (layout) {
                                SkillTreeLayout.library =>
                                  'skillLibraryCompact',
                                SkillTreeLayout.expandInPlace =>
                                  'skillExpandInPlace',
                                SkillTreeLayout.progressBoard =>
                                  'skillProgressBoard',
                              }),
                              controller: _scroll,
                              padding: const EdgeInsets.only(bottom: 88),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 8,
                                children: [
                                  header,
                                  const SizedBox(height: 4),
                                  if (layout ==
                                      SkillTreeLayout.progressBoard) ...[
                                    _SkillProgressBoard(
                                      skills: skills,
                                      levelFor: levelFor,
                                      row: (skill) =>
                                          row(skill, showStatus: false),
                                    ),
                                    if (details != null)
                                      KeyedSubtree(
                                        key: _detail,
                                        child: details,
                                      ),
                                  ] else ...[
                                    if (details != null && !selectedIsVisible)
                                      KeyedSubtree(
                                        key: _detail,
                                        child: details,
                                      ),
                                    if (skills.isEmpty) emptySkills,
                                    for (final skill in skills) ...[
                                      row(skill),
                                      if (details != null &&
                                          selectedId == skill.id)
                                        KeyedSubtree(
                                          key: _detail,
                                          child: details,
                                        ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _skillDetails(String? selectedId) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 6,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _closeDetail,
          icon: const Icon(Icons.close),
          label: const Text('Close details'),
        ),
      ),
      SkillLevelView(skillId: selectedId ?? widget.skillId),
    ],
  );
}

class _SkillProgressSummary extends StatelessWidget {
  const _SkillProgressSummary({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SizedBox(
      width: 192,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'My Progress',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTokens.secondaryTextColor(context),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$percent%',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.primaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: isDark
                  ? AppTokens.cardBorderDark
                  : theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTokens.accentColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillLibraryRow extends StatelessWidget {
  const _SkillLibraryRow({
    required this.skill,
    required this.level,
    required this.selected,
    required this.showStatus,
    required this.verified,
    required this.onSelect,
    this.onEdit,
  });

  final Skill skill;
  final LevelState level;
  final bool selected;
  final bool showStatus;
  final bool verified;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppTokens.radiusMd);

    final tile = Material(
      type: isDark ? MaterialType.transparency : MaterialType.canvas,
      color: isDark
          ? null
          : (selected ? colors.secondaryContainer : colors.surface),
      shape: isDark
          ? null
          : RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: selected,
        key: ValueKey('library-skill-${skill.id}'),
        title: Text(
          skill.skillName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTokens.primaryTextColor(context),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                skill.difficulty == DifficultyState.All
                    ? 'All levels'
                    : skill.difficulty.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTokens.secondaryTextColor(context),
                ),
              ),
              if (showStatus || verified || level == LevelState.VERIFIED)
                SkillProgressBadge(level: level, verified: verified),
            ],
          ),
        ),
        onTap: onSelect,
        trailing: onEdit == null
            ? null
            : IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit ${skill.skillName}',
                onPressed: onEdit,
              ),
      ),
    );

    if (!isDark) return tile;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTokens.coralAccent.withValues(alpha: 0.16),
                  AppTokens.midnightCardBottom,
                ],
              )
            : AppTokens.cardSurfaceGradient,
        border: Border.all(
          color: selected ? AppTokens.coralAccent : AppTokens.cardBorderDark,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: ClipRRect(borderRadius: radius, child: tile),
    );
  }
}

class _SkillProgressBoard extends StatelessWidget {
  const _SkillProgressBoard({
    required this.skills,
    required this.levelFor,
    required this.row,
  });

  final List<Skill> skills;
  final LevelState Function(Skill) levelFor;
  final Widget Function(Skill) row;

  @override
  Widget build(BuildContext context) {
    final lanes = <LevelState, List<Skill>>{
      LevelState.NO_PROGRESS: [],
      LevelState.LEARNING: [],
      LevelState.PROFICIENT: [],
    };
    for (final skill in skills) {
      final level = levelFor(skill);
      lanes[level == LevelState.VERIFIED ? LevelState.PROFICIENT : level]!.add(
        skill,
      );
    }

    final theme = Theme.of(context);
    final columns = [
      for (final entry in lanes.entries)
        AppSurfaceCard(
          key: ValueKey(entry.key),
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      switch (entry.key) {
                        LevelState.LEARNING => 'Learning',
                        LevelState.PROFICIENT => 'Proficient',
                        _ => 'Not started',
                      },
                      style: AppTokens.sectionTitleStyle(
                        context,
                      ).copyWith(fontSize: 18),
                    ),
                  ),
                  AppStatusBadge(
                    label: '${entry.value.length}',
                    tone: switch (entry.key) {
                      LevelState.LEARNING => AppStatusTone.coral,
                      LevelState.PROFICIENT => AppStatusTone.success,
                      _ => AppStatusTone.neutral,
                    },
                  ),
                ],
              ),
              if (entry.value.isEmpty)
                Text(
                  'No skills',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTokens.secondaryTextColor(context),
                  ),
                ),
              for (final skill in entry.value) row(skill),
            ],
          ),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 690
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [for (final column in columns) Expanded(child: column)],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: columns,
            ),
    );
  }
}
