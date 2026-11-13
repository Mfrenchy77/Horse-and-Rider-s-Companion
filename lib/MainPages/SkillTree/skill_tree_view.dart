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
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

class SkillTreeView extends StatefulWidget {
  const SkillTreeView({super.key, this.skillId, this.trainingPathId});

  static const skillsListName = 'SkillsList';
  static const skillLevelName = 'SkillLevel';
  static const trainingPathListName = 'TrainingPathList';
  static const trainingPathViewName = 'TrainingPathView';
  static const skillsListPath = '/Skills';
  static const skillLevelPath = 'Skill::$skillPathParam';
  static const trainingPathListPath = '/TrainingPaths';
  static const trainingPathViewPath = 'TrainingPath::$trainingPathPathParam';
  static const skillPathParam = 'skillId';
  static const trainingPathPathParam = 'trainingPathId';

  static void openSkill(GoRouter router, String id) =>
      router.goNamed(skillLevelName, pathParameters: {skillPathParam: id});

  final String? skillId;
  final String? trainingPathId;

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
    if (widget.skillId != null) _showDetail();
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final wideLibrary =
                  layout == SkillTreeLayout.library &&
                  constraints.maxWidth >= 740;
              final header = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  Text(
                    state.isForRider ? 'Rider Skills' : 'Horse Skills',
                    style: Theme.of(context).textTheme.headlineMedium,
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
                            for (final difficulty in DifficultySortState.values)
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 20,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: skills.isEmpty
                                          ? const Text(
                                              'No skills match these filters.',
                                            )
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
                                            const GradientCard(
                                              margin: EdgeInsets.zero,
                                              child: Padding(
                                                padding: EdgeInsets.all(20),
                                                child: Text(
                                                  'Select a skill to view its '
                                                  'details and resources.',
                                                ),
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
                              SkillTreeLayout.library => 'skillLibraryCompact',
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
                                    KeyedSubtree(key: _detail, child: details),
                                ] else ...[
                                  if (details != null && !selectedIsVisible)
                                    KeyedSubtree(key: _detail, child: details),
                                  if (skills.isEmpty)
                                    const Text(
                                      'No skills match these filters.',
                                    ),
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
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.secondaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: selected,
        key: ValueKey('library-skill-${skill.id}'),
        title: Text(skill.skillName),
        subtitle: Wrap(
          spacing: 8,
          runSpacing: 3,
          children: [
            Text(
              skill.difficulty == DifficultyState.All
                  ? 'All levels'
                  : skill.difficulty.name,
            ),
            if (showStatus || verified || level == LevelState.VERIFIED)
              SkillProgressBadge(level: level, verified: verified),
          ],
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
        GradientCard(
          key: ValueKey(entry.key),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(switch (entry.key) {
                        LevelState.LEARNING => 'Learning',
                        LevelState.PROFICIENT => 'Proficient',
                        _ => 'Not started',
                      }, style: theme.textTheme.titleMedium),
                    ),
                    Text(
                      '${entry.value.length}',
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
                if (entry.value.isEmpty)
                  Text('No skills', style: theme.textTheme.bodySmall),
                for (final skill in entry.value) row(skill),
              ],
            ),
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
