import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/app_bar_search_button.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_app_bar_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_tree_title_search_bar.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skills_list.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_path_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_paths_list.dart';

class SkillTreeView extends StatefulWidget {
  const SkillTreeView({super.key});

  static const double splitScreenBreakpoint = 1024;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitialized) {
      final isLargeScreen = MediaQuery.of(context).size.width >=
          SkillTreeView.splitScreenBreakpoint;
      final tabCount = isLargeScreen ? 2 : 4;

      _tabController = TabController(
        length: tabCount,
        vsync: this,
        initialIndex: _cubit.state.skillTreeTabIndex,
      );

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          _cubit.setSkillTreeTabIndex(_tabController.index);
        }
      });

      isInitialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleBackPressed() {
    if (_tabController.index > 0) {
      final newIndex = _tabController.index - 1;
      _tabController.animateTo(newIndex);
      _cubit.setSkillTreeTabIndex(newIndex);
    } else {
      _cubit.changeIndex(0);
    }
  }

  /// Changes the current tab to the specified index and updates
  ///  the cubit's state.
  void _changeTab(int index) {
    _tabController.animateTo(index);
    _cubit.setSkillTreeTabIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width >=
        SkillTreeView.splitScreenBreakpoint;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: _handleBackPressed,
        ),
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
          tabs: isLargeScreen
              ? const [
                  Tab(text: 'Skills'),
                  Tab(text: 'Training Paths'),
                ]
              : const [
                  Tab(text: 'Skills'),
                  Tab(text: 'Skill Detail'),
                  Tab(text: 'Training Paths'),
                  Tab(text: 'Path Detail'),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: isLargeScreen
            ? const [
                _SplitSkillsView(),
                _SplitTrainingPathsView(),
              ]
            : [
                SkillsListView(
                  onSkillSelected: () => _changeTab(1),
                ),
                const SkillLevelView(),
                TrainingPathListView(
                  onTrainingPathSelected: () => _changeTab(3),
                ),
                const TrainingPathView(),
              ],
      ),
    );
  }
}

class _SplitSkillsView extends StatelessWidget {
  const _SplitSkillsView();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 3, child: SkillsListView()),
        VerticalDivider(width: 1),
        Expanded(flex: 2, child: SkillLevelView()),
      ],
    );
  }
}

class _SplitTrainingPathsView extends StatelessWidget {
  const _SplitTrainingPathsView();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 3, child: TrainingPathListView()),
        VerticalDivider(width: 1),
        Expanded(flex: 2, child: TrainingPathView()),
      ],
    );
  }
}
