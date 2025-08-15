import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/app_bar_search_button.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_app_bar_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_title_search_bar.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skills_list_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_path_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_paths_list.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

class SkillTreeView extends StatefulWidget {
  const SkillTreeView({super.key, this.skillId, this.trainingPathId});

  ///Full screnn Naming constants

  /// Mobile Naming Constants
  static const String skillsListName = 'SkillsList';
  static const String skillLevelName = 'SkillLevel';
  static const String trainingPathListName = 'TrainingPathList';
  static const String trainingPathViewName = 'TrainingPathView';
  static const String skillsListPath = '/Skills';
  static const String skillLevelPath = 'Skill::$skillPathParam';
  static const String trainingPathListPath = '/TrainingPaths';
  static const String trainingPathViewPath =
      'TrainingPath::$trainingPathPathParam';
  static const String skillPathParam = 'skillId';
  static const String trainingPathPathParam = 'trainingPathId';

  final String? skillId;
  final String? trainingPathId;

  @override
  State<SkillTreeView> createState() => _SkillTreeViewState();
}

class _SkillTreeViewState extends State<SkillTreeView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppCubit _cubit;
  late bool isInitialized;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<AppCubit>();
    isInitialized = false;
  }

  // @override
  // void didUpdateWidget(covariant SkillTreeView old) {
  //   super.didUpdateWidget(old);
  //   final isLarge = MediaQuery.of(context).size.width >=
  //       StringConstants.splitScreenBreakpoint;

  //   // 1) Skill deep‐link changed?
  //   if (widget.skillId != old.skillId && widget.skillId != null) {
  //     _cubit.setSkill(widget.skillId);
  //     _tabController.index = isLarge ? 0 : 1;
  //   } else {
  //     debugPrint('SkillId ${widget.skillId} is'
  //         ' skill in state null ${_cubit.state.skill?.skillName}');
  //   }
  //   // 2) TrainingPath deep‐link changed?
  //   if (widget.trainingPathId != old.trainingPathId &&
  //       widget.trainingPathId != null) {
  //     _cubit.setTrainingPath(widget.trainingPathId);
  //     _tabController.index = isLarge ? 1 : 3;
  //   } else {
  //     debugPrint('SkillId ${widget.skillId} and '
  //         'TrainingPathId ${widget.trainingPathId} is'
  //         ' trainingPath in state null ${_cubit.state.trainingPath?.name}');
  //     _cubit.setSkillTreeTabIndex(0);
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!isInitialized) {
      final isLargeScreen = MediaQuery.of(context).size.width >=
          StringConstants.splitScreenBreakpoint;

      final tabCount = isLargeScreen ? 2 : 4;

      _tabController = TabController(
        length: tabCount,
        vsync: this,
        initialIndex: _cubit.state.skillTreeTabIndex,
      );

      isInitialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBackPressed() {
    final isLarge = MediaQuery.of(context).size.width >=
        StringConstants.splitScreenBreakpoint;
    final index = _tabController.index;
    final cubit = context.read<AppCubit>();

    // On a wide screen, if we are on index 0 and the flag
    // isFromTrainingPath is true,
    // we should go back to the TrainingPathView.
    if (isLarge && index == 0 && cubit.state.isFromTrainingPath) {
      final pathId = cubit.getSelectedTrainingPathId();
      debugPrint('Back pressed on Skills List, '
          'going to TrainingPathView with pathId: $pathId');

      context.goNamed(
        SkillTreeView.trainingPathViewName,
        pathParameters: {
          SkillTreeView.trainingPathPathParam: pathId ?? '',
        },
      );
      cubit.setIsFromTrainingPath(isFromTrainingPath: false);

      return;
    } else if (isLarge && index == 0) {
      // If we are on Skills List and not from TrainingPath,
      // just go back to Profile
      cubit.changeIndex(0);
      return;
    }
    // SMALL SCREEN LOGIC:
    switch (index) {
      // 1: Skill Detail
      case 1:
        // If we arrived here via TrainingPathView
        if (cubit.state.isFromTrainingPath) {
          cubit.setIsFromTrainingPath(isFromTrainingPath: false);
          final pathId = cubit.getSelectedTrainingPathId();
          debugPrint('Back pressed on Skill Detail, '
              'going to TrainingPathView with pathId: $pathId');
          if (pathId != null) {
            context.goNamed(
              SkillTreeView.trainingPathViewName,
              pathParameters: {
                SkillTreeView.trainingPathPathParam: pathId,
              },
            );
          }
        } else {
          // Otherwise just go back to the Skills list
          context.goNamed(SkillTreeView.skillsListName);
        }
        break;

      // 3: Training Path Detail
      case 3:
        // Go back to the TrainingPaths list
        context.goNamed(SkillTreeView.trainingPathListName);
        break;

      // 2: Training Paths List
      case 2:
        context.goNamed(
          SkillTreeView.skillLevelName,
          pathParameters: {
            SkillTreeView.skillPathParam: cubit.state.skill?.id ?? '',
          },
        );

        break;

      // 0: Skills List
      default:
        // Last stop: go back to Profile
        cubit.changeIndex(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width >=
        StringConstants.splitScreenBreakpoint;

    return BlocListener<AppCubit, AppState>(
      listenWhen: (previous, current) =>
          previous.skillTreeTabIndex != current.skillTreeTabIndex,
      listener: (context, state) {
        debugPrint('SkillTreeView BlocListener: '
            'Tab Index changed from ${_tabController.index} to '
            '${state.skillTreeTabIndex}');
        if (_tabController.index != state.skillTreeTabIndex) {
          _tabController.animateTo(state.skillTreeTabIndex);
        }
      },
      child: BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: _handleBackPressed),
              centerTitle: true,
              title: const SkillTreeSearchTitleBar(
                key: Key('skillTreeSearchTitleBar'),
              ),
              actions: const [
                AppBarSearchButton(),
                SkillTreeAppBarOverFlowMenu(),
              ],
              bottom: TabBar(
                controller: _tabController,
                onTap: (index) {
                  final isLarge = MediaQuery.of(context).size.width >=
                      StringConstants.splitScreenBreakpoint;
                  final cubit = context.read<AppCubit>();

                  switch (index) {
                    // SKILLS LIST
                    case 0:
                      context.goNamed(
                        SkillTreeView.skillsListName,
                        // no params
                      );
                      break;

                    // DETAIL (skill or path)
                    case 1:
                      if (isLarge) {
                        // on a wide screen this is "TrainingPaths List"
                        context.goNamed(SkillTreeView.trainingPathListName);
                      } else {
                        // small: detail of selected skill
                        final skillId = cubit.getSelectedSkillId();
                        if (skillId != null) {
                          context.goNamed(
                            SkillTreeView.skillLevelName,
                            pathParameters: {
                              SkillTreeView.skillPathParam: skillId,
                            },
                          );
                        }
                      }
                      break;

                    // TRAINING PATHS LIST (only on small screens is index 2)
                    case 2:
                      if (!isLarge) {
                        context.goNamed(SkillTreeView.trainingPathListName);
                      }
                      break;

                    // PATH DETAIL
                    case 3:
                      final pathId = cubit.getSelectedTrainingPathId();
                      if (pathId != null) {
                        context.goNamed(
                          SkillTreeView.trainingPathViewName,
                          pathParameters: {
                            SkillTreeView.trainingPathPathParam: pathId,
                          },
                        );
                      }
                      break;
                  }
                },
                tabs: isLargeScreen
                    ? const [
                        Tab(text: 'Skills'),
                        Tab(text: 'Training Paths'),
                      ]
                    : const [
                        Tab(text: 'Skills'),
                        Tab(text: 'Detail'),
                        Tab(text: 'Training Paths'),
                        Tab(text: 'Path Detail'),
                      ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: isLargeScreen
                  ? [
                      _SplitSkillsView(
                        skillId: widget.skillId,
                      ),
                      const _SplitTrainingPathsView(),
                    ]
                  : [
                      const SkillsListView(
                          // onSkillSelected: () =>
                          // _cubit.setSkillTreeTabIndex(1),
                          ),
                      SkillLevelView(
                        skillId: widget.skillId,
                      ),
                      const TrainingPathListView(
                          // onTrainingPathSelected: () =>
                          //     _cubit.setSkillTreeTabIndex(3),
                          ),
                      TrainingPathView(
                        trainingPathId: context
                            .read<AppCubit>()
                            .getSelectedTrainingPathId(),
                      ),
                    ],
            ),
          );
        },
      ),
    );
  }
}

class _SplitSkillsView extends StatelessWidget {
  const _SplitSkillsView({required this.skillId});
  final String? skillId;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 3, child: SkillsListView()),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: SkillLevelView(
            skillId: skillId,
          ),
        ),
      ],
    );
  }
}

class _SplitTrainingPathsView extends StatelessWidget {
  const _SplitTrainingPathsView();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 3, child: TrainingPathListView()),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: TrainingPathView(
            trainingPathId:
                context.read<AppCubit>().getSelectedTrainingPathId(),
          ),
        ),
      ],
    );
  }
}
