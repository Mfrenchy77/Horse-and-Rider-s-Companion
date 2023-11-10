import 'package:auto_size_text/auto_size_text.dart';
import 'package:database_repository/database_repository.dart';
import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/responsive_appbar.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/skilltree_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/category_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/level_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/skill_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/sub_category_create_dialog.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

///   This is the main view for the Skill Tree
/// It will display the categories, subcategories, skills, and levels
/// for the selected category, subcategory, skill, or level
/// it will also allow authorized users to edit the skill tree
///
class SkillTreeViewFilter extends StatelessWidget {
  const SkillTreeViewFilter({
    required RiderProfile? usersProfile,
    RiderProfile? viewingProfile,
    HorseProfile? horseProfile,
    super.key,
    required this.homeContext,
  })  : _usersProfile = usersProfile,
        _horseProfile = horseProfile,
        _viewingProfile = viewingProfile;
  final BuildContext homeContext;
  // ViewingProfile is if a user is viewing another users skill tree
  // if it is null then the user is viewing their own skill tree
  final RiderProfile? _viewingProfile;
  // usersProfile is the profile of the user that is logged in
  // if it is null then we restrict access to what can be done and viewed
  final RiderProfile? _usersProfile;
  // HorseProfile is the profile of the horse that is being viewed
  // if it is not null then the user is viewing the horse skill tree
  final HorseProfile? _horseProfile;

  @override
  Widget build(BuildContext context) {
    //screen size
    return BlocProvider(
      create: (context) => SkilltreeCubit(
        usersProfile: _usersProfile,
        skillTreeRepository: context.read<SkillTreeRepository>(),
        horseProfile: _horseProfile,
        viewingProfile: _viewingProfile,
      ),
      child: BlocBuilder<SkilltreeCubit, SkilltreeState>(
        builder: (context, state) {
          return Scaffold(
            appBar: _appBar(
              state: state,
              context: context,
              homeContext: homeContext,
            ),
            body: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: _skillTreeNavigationText(
                          context: context,
                          state: state,
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: _description(state: state),
                      // ),
                    ],
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    child: Center(
                      child: _skillTreeItems(context: context, state: state),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: Visibility(
              visible: state.isSkillTreeEdit,
              child: Visibility(
                visible: state.usersProfile != null,
                child: _floatingActionButton(
                  skillTreeContext: context,
                  state: state,
                ),
              ),
            ),

            ///
          );
        },
      ),
    );
  }
}

Widget _description({required SkilltreeState state}) {
  switch (state.filterState) {
    case FilterState.Category:
      return const Text('');
    case FilterState.SubCategory:
      debugPrint('Category Description: ${state.category?.description}');
      return Text(state.category?.description ?? '');
    case FilterState.Skill:
      debugPrint('SubCategory Description: ${state.subCategory?.description}');
      return Text(state.subCategory?.description ?? '');
    case FilterState.Level:
      return Text(state.skill?.description ?? '');
  }
}

//Search Bar for Skills
PreferredSizeWidget _appBar({
  required SkilltreeState state,
  required BuildContext context,
  required BuildContext homeContext,
}) {
  final skillNames = <String>[
    ...?state.skills?.map((skill) => skill?.skillName ?? ''),
  ];
  debugPrint('Skill List: ${skillNames.length}');
  if (state.filterState == FilterState.Skill) {
    return EasySearchBar(
      openOverlayOnSearch: true,
      title: AutoSizeText(
        _appbarTitle(state),
        maxLines: 1,
      ),
      suggestions: skillNames,
      onSuggestionTap: (data) {
        debugPrint('Suggestion: $data');
        context.read<SkilltreeCubit>().skillSelected(
              skill: state.skills!.firstWhere(
                (skill) => skill?.skillName == data,
              )!,
            );
      },
      putActionsOnRight: true,
      actions: _appbarActions(state: state, context: context),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
        ),
        onPressed: () {
          // if we are in the subcategories filter we are going to
          // change the filter to categories

          if (state.filterState == FilterState.SubCategory) {
            context.read<SkilltreeCubit>().backToCategory();
          } else if (state.filterState == FilterState.Skill) {
            // if we are in the skills filter we are going to
            // change the filter to subcategories for the selected category
            homeContext.read<HomeCubit>().riderProfileNavigationSelected();
          } else if (state.filterState == FilterState.Level) {
            // if we are in the levels filter we are going to
            // change the filter to skills for the selected subcategory
            homeContext.read<HomeCubit>().skillTreeNavigationSelected();
          } else {
            homeContext.read<HomeCubit>().riderProfileNavigationSelected();
          }
        },
      ),
      onSearch: (p0) {
        debugPrint('Search: $p0');
      },
    );
  } else {
    return AppBar(
      title: AutoSizeText(_appbarTitle(state), maxLines: 1),
      actions: _appbarActions(state: state, context: context),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // if we are in the subcategories filter we are going to
          // change the filter to categories

          if (state.filterState == FilterState.SubCategory) {
            context.read<SkilltreeCubit>().backToCategory();
          } else if (state.filterState == FilterState.Skill) {
            // if we are in the skills filter we are going to
            // change the filter to subcategories for the selected category
            context.read<SkilltreeCubit>().categorySelected(
                  category: state.category!,
                );
          } else if (state.filterState == FilterState.Level) {
            // if we are in the levels filter we are going to
            // change the filter to skills for the selected subcategory
            context.read<SkilltreeCubit>().skillTreeHome();
          } else {
            homeContext.read<HomeCubit>().riderProfileNavigationSelected();
          }
        },
      ),
    );
  }
}

List<Widget> _appbarActions({
  required SkilltreeState state,
  required BuildContext context,
}) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  final actions = <Widget>[];

// popup menu for the edit button when the
// screen size is small we only want to show the
// Difficulty option if the FilterState is Skill
  final Widget popupMenu = Visibility(
    visible: isMobile,
    child: PopupMenuButton<String>(
      itemBuilder: (context) {
        if (state.filterState == FilterState.Skill) {
          return [
            // adding a filter option to select a category or a subcategory

            const PopupMenuItem(
              value: 'Difficulty',
              child: Text('Difficulty'),
            ),
            const PopupMenuItem(
              value: 'Edit',
              child: Text('Toggle Edit Controls'),
            ),
          ];
        } else {
          return [
            const PopupMenuItem(
              value: 'Edit',
              child: Text('Edit'),
            ),
          ];
        }
      },
      onSelected: (value) {
        if (value == 'Difficulty') {
          // open the sort dialog
          context.read<SkilltreeCubit>().openDifficultySelectDialog(
                context: context,
                subCategory: state.subCategory!,
              );
        }
        if (value == 'Edit') {
          context.read<SkilltreeCubit>().toggleSkillTreeEdit();
        }
      },
    ),
  );

  // icon for editing the skill tree
  final Widget editIcon = Visibility(
    visible: !isMobile,
    child: Visibility(
      visible: state.usersProfile!.editor ?? false,
      child: Tooltip(
        message: state.isSkillTreeEdit ? 'Done Editing' : 'Edit Skill Tree',
        child: Switch(
          value: state.isSkillTreeEdit,
          onChanged: (value) {
            context.read<SkilltreeCubit>().toggleSkillTreeEdit();
          },
        ),
      ),
    ),
  );

  //difficulty
  final Widget difficulty = Visibility(
    visible: !isMobile,
    child: Visibility(
      visible: state.filterState == FilterState.Skill,
      child: Tooltip(
        message: 'Sort by Difficulty',
        child: IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () {
            // open the sort dialog
            context.read<SkilltreeCubit>().openDifficultySelectDialog(
                  context: context,
                  subCategory: state.subCategory!,
                );
          },
        ),
      ),
    ),
  );
  actions
    ..add(difficulty)
    ..add(editIcon)
    ..add(popupMenu);
  return actions;
}

String _appbarTitle(SkilltreeState state) {
  switch (state.filterState) {
    case FilterState.Category:
      return 'Skill Tree Categories';
    case FilterState.SubCategory:
      return 'SubCategories for ${state.category?.name ?? ''}';
    case FilterState.Skill:
      return 'Skills';
    case FilterState.Level:
      return 'Levels for ${state.skill?.skillName ?? ''}';
  }
}

// this will determite what the filterstate is and return the
// appropriate widget
Widget _skillTreeItems({
  required BuildContext context,
  required SkilltreeState state,
}) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  final scaler = ResponsiveScaler();
  switch (state.filterState) {
    case FilterState.Category:
      if (state.categories != null && state.categories!.isNotEmpty) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: scaler.dynamicSpacing(context: context),
          spacing: scaler.dynamicSpacing(context: context),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: state.categories!
              .map(
                (category) => _skillTreeItem(
                  difficulty: null,
                  name: category!.name,
                  onTap: () => context
                      .read<SkilltreeCubit>()
                      .categorySelected(category: category),
                  onEdit: () => showDialog<CreateCategoryDialog>(
                    context: context,
                    builder: (context) => CreateCategoryDialog(
                      isRider: state.isForRider,
                      isEdit: true,
                      category: category,
                      userName: state.usersProfile!.name!,
                      position: category.position,
                    ),
                  ),
                  state: state,
                  backgroundColor: Colors.transparent,
                ),
              )
              .toList(),
        );
      } else {
        return const Text('No Categories');
      }

    case FilterState.SubCategory:
      if (state.subCategories != null && state.subCategories!.isNotEmpty) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.spaceEvenly,
          runSpacing: scaler.dynamicSpacing(context: context),
          spacing: scaler.dynamicSpacing(context: context),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: state.subCategories!
              .map(
                (subCategory) => _skillTreeItem(
                  difficulty: null,
                  name: subCategory!.name,
                  onTap: () => context
                      .read<SkilltreeCubit>()
                      .subCategorySelected(subCategory: subCategory),
                  onEdit: () => showDialog<CreateSubCategoryDialog>(
                    context: context,
                    builder: (dialogContext) => CreateSubCategoryDialog(
                      skillTreeContext: context,
                      skills: state.skills,
                      subCategory: subCategory,
                      isEdit: true,
                      isRider: state.isForRider,
                      category: state.category,
                      userName: state.usersProfile?.name,
                      position: subCategory.position,
                    ),
                  ),
                  state: state,
                  backgroundColor: Colors.transparent,
                ),
              )
              .toList(),
        );
      } else {
        return const Expanded(child: Center(child: Text('No SubCategories')));
      }
    case FilterState.Skill:
      if (state.skills != null && state.skills!.isNotEmpty) {
        switch (state.difficultyState) {
          /// Filter is set to all so we will display all skills
          /// in the selected subcategory
          case DifficultyState.all:
            return Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                /// Introductory
                ColoredBox(
                  color: Colors.greenAccent.shade200.withOpacity(0.4),
                  child: Column(
                    children: [
                      Visibility(
                        visible: state.skills!
                            .where(
                              (skill) =>
                                  skill!.difficulty ==
                                  DifficultyState.introductory,
                            )
                            .isNotEmpty,
                        child: const Center(
                          child: Text(
                            'Introductory',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      smallGap(),
                      Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...state.skills!
                              .where(
                                (skill) =>
                                    skill!.difficulty ==
                                    DifficultyState.introductory,
                              )
                              .map(
                                (skill) => _skillTreeItem(
                                  difficulty: DifficultyState.introductory,
                                  name: skill!.skillName,
                                  onTap: () => context
                                      .read<SkilltreeCubit>()
                                      .skillSelected(skill: skill),
                                  onEdit: () => showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      allSubCategories:
                                          state.subCategories ?? [],
                                      subCategory: state.subCategory,
                                      isRider: state.isForRider,
                                      isEdit: true,
                                      skill: skill,
                                      userName: state.usersProfile?.name,
                                      position: state.skills != null &&
                                              state.skills!.isNotEmpty
                                          ? state.skills!.length
                                          : 0,
                                    ),
                                  ),
                                  state: state,
                                  backgroundColor: Colors.greenAccent.shade200,
                                ),
                              ),
                        ],
                      ),
                      smallGap(),
                    ],
                  ),
                ),

                /// Intermediate

                ColoredBox(
                  color: Colors.yellowAccent.shade200.withOpacity(0.4),
                  child: Column(
                    children: [
                      Visibility(
                        visible: state.skills!
                            .where(
                              (skill) =>
                                  skill!.difficulty ==
                                  DifficultyState.intermediate,
                            )
                            .isNotEmpty,
                        child: const Center(
                          child: Text(
                            'Intermediate',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      smallGap(),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runAlignment: WrapAlignment.spaceEvenly,
                        runSpacing: scaler.dynamicSpacing(context: context),
                        spacing: scaler.dynamicSpacing(context: context),
                        crossAxisAlignment: WrapCrossAlignment.center,
                        direction: !isMobile ? Axis.vertical : Axis.horizontal,
                        children: [
                          ...state.skills!
                              .where(
                                (skill) =>
                                    skill!.difficulty ==
                                    DifficultyState.intermediate,
                              )
                              .map(
                                (skill) => _skillTreeItem(
                                  difficulty: DifficultyState.intermediate,
                                  name: skill!.skillName,
                                  onTap: () => context
                                      .read<SkilltreeCubit>()
                                      .skillSelected(skill: skill),
                                  onEdit: () => showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      allSubCategories:
                                          state.subCategories ?? [],
                                      subCategory: state.subCategory,
                                      isRider: state.isForRider,
                                      isEdit: true,
                                      skill: skill,
                                      userName: state.usersProfile?.name,
                                      position: state.skills != null &&
                                              state.skills!.isNotEmpty
                                          ? state.skills!.length
                                          : 0,
                                    ),
                                  ),
                                  state: state,
                                  backgroundColor: Colors.yellowAccent.shade200,
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// Advanced

                ColoredBox(
                  color: Colors.redAccent.shade200.withOpacity(0.4),
                  child: Column(
                    children: [
                      smallGap(),
                      Visibility(
                        visible: state.skills!
                            .where(
                              (skill) =>
                                  skill!.difficulty == DifficultyState.advanced,
                            )
                            .isNotEmpty,
                        child: const Center(
                          child: Text(
                            'Advanced',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      smallGap(),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runAlignment: WrapAlignment.spaceEvenly,
                        runSpacing: scaler.dynamicSpacing(context: context),
                        spacing: scaler.dynamicSpacing(context: context),
                        crossAxisAlignment: WrapCrossAlignment.center,
                        direction: !isMobile ? Axis.vertical : Axis.horizontal,
                        children: [
                          ...state.skills!
                              .where(
                                (skill) =>
                                    skill!.difficulty ==
                                    DifficultyState.advanced,
                              )
                              .map(
                                (skill) => _skillTreeItem(
                                  difficulty: DifficultyState.advanced,
                                  name: skill!.skillName,
                                  backgroundColor: Colors.redAccent.shade200,
                                  onTap: () => context
                                      .read<SkilltreeCubit>()
                                      .skillSelected(skill: skill),
                                  onEdit: () => showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      allSubCategories:
                                          state.subCategories ?? [],
                                      subCategory: state.subCategory,
                                      isRider: state.isForRider,
                                      isEdit: true,
                                      skill: skill,
                                      userName: state.usersProfile?.name,
                                      position: state.skills != null &&
                                              state.skills!.isNotEmpty
                                          ? state.skills!.length
                                          : 0,
                                    ),
                                  ),
                                  state: state,
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          case DifficultyState.introductory:
            return Wrap(
              children: [
                const Center(
                  child: Text(
                    'Introductory',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                smallGap(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.spaceEvenly,
                  runSpacing: scaler.dynamicSpacing(context: context),
                  spacing: scaler.dynamicSpacing(context: context),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  direction: !isMobile ? Axis.vertical : Axis.horizontal,
                  children: [
                    ...state.skills!
                        .where(
                          (skill) =>
                              skill!.difficulty == DifficultyState.introductory,
                        )
                        .map(
                          (skill) => _skillTreeItem(
                            difficulty: DifficultyState.introductory,
                            name: skill!.skillName,
                            onTap: () => context
                                .read<SkilltreeCubit>()
                                .skillSelected(skill: skill),
                            onEdit: () => showDialog<CreateSkillDialog>(
                              context: context,
                              builder: (context) => CreateSkillDialog(
                                allSubCategories: state.subCategories ?? [],
                                subCategory: state.subCategory,
                                isRider: state.isForRider,
                                isEdit: true,
                                skill: skill,
                                userName: state.usersProfile?.name,
                                position: state.skills != null &&
                                        state.skills!.isNotEmpty
                                    ? state.skills!.length
                                    : 0,
                              ),
                            ),
                            state: state,
                            backgroundColor: Colors.greenAccent.shade200,
                          ),
                        ),
                  ],
                ),
              ],
            );
          case DifficultyState.intermediate:
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Intermediate',
                  style: TextStyle(fontSize: 20),
                ),
                smallGap(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.spaceEvenly,
                  runSpacing: scaler.dynamicSpacing(context: context),
                  spacing: scaler.dynamicSpacing(context: context),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  direction: !isMobile ? Axis.vertical : Axis.horizontal,
                  children: [
                    ...state.skills!
                        .where(
                          (skill) =>
                              skill!.difficulty == DifficultyState.intermediate,
                        )
                        .map(
                          (skill) => _skillTreeItem(
                            difficulty: DifficultyState.intermediate,
                            name: skill!.skillName,
                            onTap: () => context
                                .read<SkilltreeCubit>()
                                .skillSelected(skill: skill),
                            onEdit: () => showDialog<CreateSkillDialog>(
                              context: context,
                              builder: (context) => CreateSkillDialog(
                                allSubCategories: state.subCategories ?? [],
                                subCategory: state.subCategory,
                                isRider: state.isForRider,
                                isEdit: true,
                                skill: skill,
                                userName: state.usersProfile?.name,
                                position: state.skills != null &&
                                        state.skills!.isNotEmpty
                                    ? state.skills!.length
                                    : 0,
                              ),
                            ),
                            state: state,
                            backgroundColor: Colors.yellowAccent.shade200,
                          ),
                        ),
                  ],
                ),
              ],
            );
          case DifficultyState.advanced:
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Advanced',
                  style: TextStyle(fontSize: 20),
                ),
                smallGap(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.spaceEvenly,
                  runSpacing: scaler.dynamicSpacing(context: context),
                  spacing: scaler.dynamicSpacing(context: context),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  direction: !isMobile ? Axis.vertical : Axis.horizontal,
                  children: [
                    ...state.skills!
                        .where(
                          (skill) =>
                              skill!.difficulty == DifficultyState.advanced,
                        )
                        .map(
                          (skill) => _skillTreeItem(
                            difficulty: DifficultyState.advanced,
                            name: skill!.skillName,
                            onTap: () => context
                                .read<SkilltreeCubit>()
                                .skillSelected(skill: skill),
                            onEdit: () => showDialog<CreateSkillDialog>(
                              context: context,
                              builder: (context) => CreateSkillDialog(
                                allSubCategories: state.subCategories ?? [],
                                subCategory: state.subCategory,
                                isRider: state.isForRider,
                                isEdit: true,
                                skill: skill,
                                userName: state.usersProfile?.name,
                                position: state.skills != null &&
                                        state.skills!.isNotEmpty
                                    ? state.skills!.length
                                    : 0,
                              ),
                            ),
                            state: state,
                            backgroundColor: Colors.redAccent.shade200,
                          ),
                        ),
                  ],
                ),
              ],
            );
        }
      } else {
        return const Expanded(child: Center(child: Text('No Skills')));
      }
    case FilterState.Level:
      if (state.levels != null && state.levels!.isNotEmpty) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.spaceEvenly,
          runSpacing: scaler.dynamicSpacing(context: context),
          spacing: scaler.dynamicSpacing(context: context),
          crossAxisAlignment: WrapCrossAlignment.center,
          direction: !isMobile ? Axis.vertical : Axis.horizontal,
          children: state.levels!
              .map(
                (level) => _levelItem(level: level, context: context),
              )
              .toList(),
        );
      } else {
        return const Text('No Levels');
      }
  }
}
// a reusable widget for all of the items of the skill tree

Widget _skillTreeItem({
  required String? name,
  required VoidCallback onTap,
  required VoidCallback onEdit,
  required SkilltreeState state,
  required Color backgroundColor,
  required DifficultyState? difficulty,
}) {
  return InkWell(
    onTap: onTap,
    child: Card(
      color: backgroundColor,
      elevation: 8,
      child: SizedBox(
        width: 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name ?? '',
                  style: TextStyle(
                    color: difficulty == DifficultyState.advanced
                        ? Colors.white70
                        : Colors.black,
                  ),
                ),
                Visibility(
                  visible: state.isSkillTreeEdit && state.usersProfile != null,
                  child: InkWell(
                    onTap: onEdit,
                    child: Icon(
                      Icons.edit,
                      color: difficulty == DifficultyState.advanced
                          ? Colors.white70
                          : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

//FIXME: I think this whole section is not need and
//FIXME: we should go directly to the SkillLevel
Widget _levelItem({required Level? level, required BuildContext context}) {
  return InkWell(
    onTap: () {
      // Level selected
      context.read<SkilltreeCubit>().levelSelected(level: level!);
    },
    child: Container(
      padding: const EdgeInsets.all(50), // You can adjust the padding as needed
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue, // Change the color as needed
        // You can add a border or shadow here if you want
      ),
      child: Center(
        child: Text(
          level?.levelName ?? '',
          style: const TextStyle(
            color: Colors.white, // Change the text color as needed
            // Add text styling as needed
          ),
        ),
      ),
    ),
  );
}

// this will determite what the filterstate is and return the
// appropriate text
Widget _skillTreeNavigationText({
  required BuildContext context,
  required SkilltreeState state,
}) {
  final screenSize = MediaQuery.of(context).size.width;

  switch (state.filterState) {
    case FilterState.Category:
      return Row(
        children: [
          Icon(
            HorseAndRiderIcons.riderSkillIcon,
            size: screenSize * .07,
          ),
          smallGap(),
          const Text('Skill Tree Categories'),
        ],
      );

    case FilterState.SubCategory:
      return Row(
        children: [
          Icon(
            HorseAndRiderIcons.riderSkillIcon,
            size: screenSize * .07,
          ),
          smallGap(),
          Text('${state.category?.name ?? ''} - '),
          const Text('SubCategories'),
        ],
      );
    case FilterState.Skill:
      if (state.difficultyState == DifficultyState.all) {
        return Row(
          children: [
            Icon(
              HorseAndRiderIcons.riderSkillIcon,
              size: screenSize * .075,
            ),
            smallGap(),
            Text('${state.category?.name ?? ''} '),
            Text(state.subCategory?.name ?? ''),
            const Text('Skills - All'),
          ],
        );
      } else if (state.difficultyState == DifficultyState.introductory) {
        return Row(
          children: [
            Icon(
              HorseAndRiderIcons.riderSkillIcon,
              size: screenSize * .07,
            ),
            smallGap(),
            Text('${state.category?.name ?? ''} - '),
            Text('${state.subCategory?.name ?? ''} - '),
            const Text('Skills - Introductory'),
          ],
        );
      } else if (state.difficultyState == DifficultyState.intermediate) {
        return Row(
          children: [
            Icon(
              HorseAndRiderIcons.riderSkillIcon,
              size: screenSize * .07,
            ),
            smallGap(),
            Text('${state.category?.name ?? ''} - '),
            Text('${state.subCategory?.name ?? ''} - '),
            const Text('Skillls - Intermediate'),
          ],
        );
      } else if (state.difficultyState == DifficultyState.advanced) {
        return Row(
          children: [
            Icon(
              HorseAndRiderIcons.riderSkillIcon,
              size: screenSize * .07,
            ),
            smallGap(),
            Text('${state.category?.name ?? ''} - '),
            Text('${state.subCategory?.name ?? ''} - '),
            const Text('Skills - Advanced'),
          ],
        );
      } else {
        return Row(
          children: [
            Icon(
              HorseAndRiderIcons.riderSkillIcon,
              size: screenSize * .07,
            ),
            smallGap(),
            Text('${state.category?.name ?? ''} - '),
            Text('${state.subCategory?.name ?? ''} - '),
            const Text('Skills'),
          ],
        );
      }
    case FilterState.Level:
      return Row(
        children: [
          Icon(
            HorseAndRiderIcons.riderSkillIcon,
            size: screenSize * .07,
          ),
          smallGap(),
          Text('${state.category?.name ?? ''} - '),
          Text('${state.subCategory?.name ?? ''} - '),
          Text('${state.skill?.skillName ?? ''} - '),
          const Text('Levels'),
        ],
      );
  }
}

FloatingActionButton _floatingActionButton({
  required BuildContext skillTreeContext,
  required SkilltreeState state,
}) {
  return FloatingActionButton(
    onPressed: () {
      // open the add dialog
      // asscosiated with the current filter state
      switch (state.filterState) {
        case FilterState.Category:
          showDialog<CreateCategoryDialog>(
            context: skillTreeContext,
            builder: (context) => CreateCategoryDialog(
              isRider: true,
              isEdit: false,
              userName: state.usersProfile?.name ?? '',
              position:
                  state.categories!.isNotEmpty ? state.categories!.length : 0,
            ),
          );
          break;
        case FilterState.SubCategory:
          showDialog<CreateSubCategoryDialog>(
            context: skillTreeContext,
            builder: (context) => CreateSubCategoryDialog(
              skillTreeContext: skillTreeContext,
              skills: skillTreeContext.read<SkilltreeCubit>().getAllSkills(),
              subCategory: null,
              isEdit: false,
              isRider: true,
              category: state.category,
              userName: state.usersProfile?.name ?? '',
              position:
                  state.subCategories != null && state.subCategories!.isNotEmpty
                      ? state.subCategories!.length
                      : 0,
            ),
          );
          break;
        case FilterState.Skill:
          // open the add dialog
          // asscosiated with the current filter state
          showDialog<CreateSkillDialog>(
            context: skillTreeContext,
            builder: (context) => CreateSkillDialog(
              allSubCategories: state.subCategories ?? [],
              subCategory: state.subCategory,
              isRider: true,
              isEdit: false,
              userName: state.usersProfile?.name,
              position: state.skills != null && state.skills!.isNotEmpty
                  ? state.skills!.length
                  : 0,
            ),
          );
          break;
        case FilterState.Level:
          // open the add dialog
          // asscosiated with the current filter state
          showDialog<CreateLevelDialog>(
            context: skillTreeContext,
            builder: (context) => CreateLevelDialog(
              isEdit: false,
              isForRider: state.isForRider,
              skill: state.skill,
              userName: state.usersProfile?.name,
              position: state.levels != null && state.levels!.isNotEmpty
                  ? state.levels!.length
                  : 0,
            ),
          );
          break;
      }
    },
    tooltip: _toolTipText(state),
    child: const Icon(Icons.add),
  );
}

String _toolTipText(SkilltreeState state) {
  switch (state.filterState) {
    case FilterState.Category:
      return 'Add a new Category';
    case FilterState.SubCategory:
      return 'Add a new SubCategory';
    case FilterState.Skill:
      return 'Add a new Skill';
    case FilterState.Level:
      return 'Add a new Level';
  }
}
