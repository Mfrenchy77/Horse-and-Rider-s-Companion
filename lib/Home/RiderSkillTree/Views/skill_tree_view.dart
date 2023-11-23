// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/error_view.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/information_dialog.dart';
import 'package:horseandriderscompanion/CommonWidgets/search_confimatio_dialog.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/Resources/View/resource_item.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/category_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/skill_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/sub_category_create_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:searchfield/searchfield.dart';

///   This is the main view for the Skill Tree
/// It will display the categories, subcategories, skills, and levels
/// for the selected category, subcategory, skill, or level
/// it will also allow authorized users to edit the skill tree
///
Widget skillTreeView({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
  final skillTreeFocus = FocusNode();
  return Scaffold(
    appBar: _appBar(
      state: state,
      context: context,
      homeCubit: homeCubit,
      skillTreeFocus: skillTreeFocus,
    ),
    floatingActionButton: Visibility(
      visible: state.usersProfile?.editor ?? false,
      child: _floatingActionButton(
        state: state,
        context: context,
        homeCubit: homeCubit,
        skillTreeFocus: skillTreeFocus,
      ),
    ),
    body: _skillTreeItems(
      state: state,
      context: context,
      homeCubit: homeCubit,
      skillTreeFocus: skillTreeFocus,
    ),
  );
}

Widget _description({required HomeState state}) {
  switch (state.skillTreeNavigation) {
    case SkillTreeNavigation.Category:
      return const Text('');
    case SkillTreeNavigation.SubCategory:
      debugPrint('Category Description: ${state.category?.description}');
      return Text(state.category?.description ?? '');
    case SkillTreeNavigation.Skill:
      debugPrint('SubCategory Description: ${state.subCategory?.description}');
      return Text(state.subCategory?.description ?? '');
    case SkillTreeNavigation.SkillLevel:
      return Text(state.skill?.description ?? '');
  }
}

//Search Bar for Skills and Resources
PreferredSizeWidget _appBar({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
  required FocusNode skillTreeFocus,
}) {
  return AppBar(
    centerTitle: true,
    title: Visibility(
      visible: state.isSearch,
      child: SearchField<String>(
        suggestionState: state.isSearch ? Suggestion.expand : Suggestion.hidden,
        inputType: TextInputType.name,
        hint: state.skillTreeNavigation == SkillTreeNavigation.Skill
            ? 'Search Skills'
            : 'Search Resources',
        focusNode: skillTreeFocus,
        onSearchTextChanged: (query) {
          state.skillSearchState == SkillSearchState.skill
              ? homeCubit.skillSearchQueryChanged(searchQuery: query)
              : homeCubit.resourceSearchQueryChanged(searchQuery: query);

          return state.searchList
                  ?.map(
                    (e) => SearchFieldListItem<String>(
                      e ?? '',
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(e!),
                      ),
                    ),
                  )
                  .toList() ??
              [];
        },
        searchInputDecoration: InputDecoration(
          filled: true,
          iconColor: HorseAndRidersTheme().getTheme().iconTheme.color,
          fillColor: HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
          suffixIcon: IconButton(
            onPressed: () => homeCubit.cancelSearch(),
            icon: const Icon(Icons.clear),
          ),
          hintText: state.skillTreeNavigation == SkillTreeNavigation.Skill
              ? 'Search Skills'
              : 'Search Resources',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        suggestions: state.searchList
                ?.map(
                  (e) => SearchFieldListItem<String>(
                    e ?? '',
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(e!),
                    ),
                  ),
                )
                .toList() ??
            [],
        onSuggestionTap: (value) {
          debugPrint('Suggestion Tap Value: ${value.searchKey}');
          skillTreeFocus.unfocus();
          state.skillTreeNavigation == SkillTreeNavigation.Skill
              ? homeCubit.skillSelected(
                  skill: state.allSkills!.firstWhere(
                    (skill) => skill?.skillName == value.searchKey,
                  ),
                )
              : showDialog<AlertDialog>(
                  context: context,
                  builder: (context) => searchConfirmationDialog(
                    // title should say add or remove depending on if
                    // the resource from the value.searchKey contains
                    // state.skill.id in it's skill id list
                    title: (state.allResources!
                                .firstWhere(
                                  (resource) =>
                                      resource?.name == value.searchKey,
                                  orElse: () => null,
                                )
                                ?.skillTreeIds
                                ?.contains(state.skill?.id) ??
                            false)
                        ? 'Remove'
                        : 'Add',

                    // text should say add or remove depending on if
                    // the resource from the value.searchKey
                    // contains state.skill.id in it's skill id list

                    text: (state.allResources!
                                .firstWhere(
                                  (resource) =>
                                      resource?.name == value.searchKey,
                                  orElse: () => null,
                                )
                                ?.skillTreeIds
                                ?.contains(state.skill?.id) ??
                            false)
                        ? 'Remove ${value.searchKey} from ${state.skill?.skillName}'
                        : 'Add ${value.searchKey} to ${state.skill?.skillName}',
                    confirmTap: () {
                      homeCubit
                        ..addResourceToSkill(
                          skill: state.skill,
                          resource: state.allResources!.firstWhere(
                            (resource) => resource?.name == value.searchKey,
                          ),
                        )
                        ..cancelSearch();
                      Navigator.pop(context);
                    },
                    cancelTap: () {
                      homeCubit.cancelSearch();
                      Navigator.pop(context);
                    },
                  ),
                );
        },
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.words,
        onSubmit: (p0) {
          debugPrint('Submit Value: $p0');
        },
      ),
    ),
    actions: _appbarActions(
      state: state,
      context: context,
      homeCubit: homeCubit,
      skillTreeFocus: skillTreeFocus,
    ),
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back,
      ),
      onPressed: () {
        // if we are in the subcategories filter we are going to
        // change the filter to categories
        switch (state.skillTreeNavigation) {
          case SkillTreeNavigation.Category:
            homeCubit.riderProfileNavigationSelected();
            break;
          case SkillTreeNavigation.SubCategory:
            homeCubit.skillTreeNavigationSelected();
            break;
          case SkillTreeNavigation.Skill:
            // if we are in the skills filter we are going to
            // change the filter to subcategories for the selected category
            homeCubit.riderProfileNavigationSelected();
            break;
          case SkillTreeNavigation.SkillLevel:
            // if we are in the levels filter we are going to
            // change the filter to skills for the selected subcategory
            homeCubit.skillTreeNavigationSelected();
            break;
        }
      },
    ),
  );
}

List<Widget> _appbarActions({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
  required FocusNode skillTreeFocus,
}) {
  final isMobile = MediaQuery.of(context).size.width < 800;
  final actions = <Widget>[];

// popup menu for the edit button when the
// screen size is small we only want to show the
// Difficulty option if the skillTreeNavigation is Skill
  final Widget popupMenu = Visibility(
    visible: isMobile,
    child: PopupMenuButton<String>(
      itemBuilder: (context) {
        if (state.skillTreeNavigation == SkillTreeNavigation.Skill) {
          return [
            // adding a filter option to select a category or a subcategory

            const PopupMenuItem(
              value: 'Difficulty',
              child: Text('Difficulty'),
            ),
            const PopupMenuItem(
              value: 'Training Paths',
              child: Text('Training Paths'),
            ),
            if (!state.isGuest)
              const PopupMenuItem(
                value: 'Edit',
                child: Text('Toggle Edit Controls'),
              ),
          ];
        } else {
          return [
            PopupMenuItem(
              value: 'Edit',
              child: Visibility(
                visible: !state.isGuest,
                child: const Text('Edit'),
              ),
            ),
          ];
        }
      },
      onSelected: (value) {
        if (value == 'Training Paths') {
          homeCubit.showTrainingSelectedPathsDialog(context);
        } else if (value == 'Difficulty') {
          // open the sort dialog
          homeCubit.openDifficultySelectDialog(
            context: context,
            subCategory: state.subCategory,
          );
        }
        if (value == 'Edit') {
          homeCubit.toggleIsEditState();
        }
      },
    ),
  );

  // icon for editing the skill tree
  final Widget editIcon = Visibility(
    visible: !isMobile,
    child: Visibility(
      visible: state.usersProfile?.editor ?? false,
      child: Tooltip(
        message: state.isEditState ? 'Done Editing' : 'Edit Skill Tree',
        child: Switch(
          value: state.isEditState,
          onChanged: (value) {
            homeCubit.toggleIsEditState();
          },
        ),
      ),
    ),
  );
// training paths
  final Widget trainingPaths = Visibility(
    visible: !isMobile,
    child: Visibility(
      visible: state.skillTreeNavigation == SkillTreeNavigation.Skill,
      child: Tooltip(
        message: 'Training Paths',
        child: IconButton(
          icon: const Icon(Icons.list),
          onPressed: () {
            // open the sort dialog
            homeCubit.showTrainingSelectedPathsDialog(context);
          },
        ),
      ),
    ),
  );

  //Search
  final Widget search = Visibility(
    visible: !state.isSearch,
    child: Visibility(
      visible: state.skillTreeNavigation == SkillTreeNavigation.Skill ||
          state.skillTreeNavigation == SkillTreeNavigation.SkillLevel,
      child: Tooltip(
        message: 'Search',
        child: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            skillTreeFocus.requestFocus();
            if (state.skillTreeNavigation == SkillTreeNavigation.Skill) {
              homeCubit.search(
                searchList: state.allSkills!.map((e) => e!.skillName).toList(),
              );
            } else if (state.skillTreeNavigation ==
                SkillTreeNavigation.SkillLevel) {
              homeCubit.search(
                searchList: state.allResources!.map((e) => e!.name).toList(),
              );
            }
          },
        ),
      ),
    ),
  );

  //difficulty
  final Widget difficulty = Visibility(
    visible: !isMobile,
    child: Visibility(
      visible: state.skillTreeNavigation == SkillTreeNavigation.Skill,
      child: Tooltip(
        message: 'Sort by Difficulty',
        child: IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () {
            // open the sort dialog
            homeCubit.openDifficultySelectDialog(
              context: context,
              subCategory: state.subCategory,
            );
          },
        ),
      ),
    ),
  );
  actions
    ..add(search)
    ..add(trainingPaths)
    ..add(difficulty)
    ..add(editIcon)
    ..add(popupMenu);
  return actions;
}

String _appbarTitle(
  HomeState state,
  HomeCubit homeCubit,
) {
  switch (state.skillTreeNavigation) {
    case SkillTreeNavigation.Category:
      return 'Skill Tree Categories';
    case SkillTreeNavigation.SubCategory:
      return 'SubCategories for ${state.category?.name ?? ''}';
    case SkillTreeNavigation.Skill:
      return 'Skills';
    case SkillTreeNavigation.SkillLevel:
      return 'Levels for ${state.skill?.skillName ?? ''}';
  }
}

// this will determite what the skillTreeNavigation is and return the
// appropriate widget
Widget _skillTreeItems({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
  required FocusNode skillTreeFocus,
}) {
  switch (state.skillTreeNavigation) {
    case SkillTreeNavigation.Category:
      if (state.categories != null && state.categories!.isNotEmpty) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 4,
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: state.categories!
              .map(
                (category) => _skillTreeItem(
                  difficulty: null,
                  name: category!.name,
                  onTap: () => context
                      .read<HomeCubit>()
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

    case SkillTreeNavigation.SubCategory:
      if (state.subCategories != null && state.subCategories!.isNotEmpty) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.spaceEvenly,
          runSpacing: 4,
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: state.subCategories!
              .map(
                (subCategory) => _skillTreeItem(
                  difficulty: null,
                  name: subCategory!.name,
                  onTap: () => context
                      .read<HomeCubit>()
                      .subCategorySelected(subCategory: subCategory),
                  onEdit: () => showDialog<CreateSubCategoryDialog>(
                    context: context,
                    builder: (dialogContext) => CreateSubCategoryDialog(
                      skillTreeContext: context,
                      skills: state.allSkills ?? [],
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
        return const Center(child: Text('No SubCategories'));
      }
    case SkillTreeNavigation.Skill:
      if (state.allSkills != null && state.allSkills!.isNotEmpty) {
        switch (state.difficultyState) {
          /// Filter is set to all so we will display all skills
          /// in the selected subcategory
          case DifficultyState.all:
            return Column(
              children: [
                const SizedBox(
                  height: 50,
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    /// Introductory
                    ColoredBox(
                      color: Colors.greenAccent.shade200.withOpacity(0.4),
                      child: Column(
                        children: [
                          smallGap(),
                          Visibility(
                            visible: state.allSkills!
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
                              ...state.introSkills!.map(
                                (skill) => _skillTreeItem(
                                  difficulty: DifficultyState.introductory,
                                  name: skill!.skillName,
                                  onTap: () => context
                                      .read<HomeCubit>()
                                      .skillSelected(skill: skill),
                                  onEdit: () => showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      allSubCategories:
                                          state.subCategories ?? [],
                                      isRider: state.isForRider,
                                      isEdit: true,
                                      skill: skill,
                                      userName: state.usersProfile?.name,
                                      position: state.introSkills != null &&
                                              state.introSkills!.isNotEmpty
                                          ? state.introSkills!.length
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
                            visible: state.intermediateSkills!.isNotEmpty,
                            child: const Center(
                              child: Text(
                                'Intermediate',
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
                              ...state.intermediateSkills!.map(
                                (skill) => _skillTreeItem(
                                  difficulty: DifficultyState.intermediate,
                                  name: skill!.skillName,
                                  onTap: () => context
                                      .read<HomeCubit>()
                                      .skillSelected(skill: skill),
                                  onEdit: () => showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      allSubCategories:
                                          state.subCategories ?? [],
                                      isRider: state.isForRider,
                                      isEdit: true,
                                      skill: skill,
                                      userName: state.usersProfile?.name,
                                      position:
                                          state.intermediateSkills != null &&
                                                  state.intermediateSkills!
                                                      .isNotEmpty
                                              ? state.intermediateSkills!.length
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
                            visible: state.advancedSkills!.isNotEmpty,
                            child: const Center(
                              child: Text(
                                'Advanced',
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
                              ...state.advancedSkills!.map(
                                (skill) => _skillTreeItem(
                                  difficulty: DifficultyState.advanced,
                                  name: skill!.skillName,
                                  backgroundColor: Colors.redAccent.shade200,
                                  onTap: () => context
                                      .read<HomeCubit>()
                                      .skillSelected(skill: skill),
                                  onEdit: () => showDialog<CreateSkillDialog>(
                                    context: context,
                                    builder: (context) => CreateSkillDialog(
                                      allSubCategories:
                                          state.subCategories ?? [],
                                      isRider: state.isForRider,
                                      isEdit: true,
                                      skill: skill,
                                      userName: state.usersProfile?.name,
                                      position: state.advancedSkills != null &&
                                              state.advancedSkills!.isNotEmpty
                                          ? state.advancedSkills!.length
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
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...state.introSkills!.map(
                        (skill) => _skillTreeItem(
                          difficulty: DifficultyState.introductory,
                          name: skill!.skillName,
                          onTap: () => context
                              .read<HomeCubit>()
                              .skillSelected(skill: skill),
                          onEdit: () => showDialog<CreateSkillDialog>(
                            context: context,
                            builder: (context) => CreateSkillDialog(
                              allSubCategories: state.subCategories ?? [],
                              isRider: state.isForRider,
                              isEdit: true,
                              skill: skill,
                              userName: state.usersProfile?.name,
                              position: state.introSkills != null &&
                                      state.introSkills!.isNotEmpty
                                  ? state.introSkills!.length
                                  : 0,
                            ),
                          ),
                          state: state,
                          backgroundColor: Colors.greenAccent.shade200,
                        ),
                      ),
                    ],
                  ),
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
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...state.intermediateSkills!.map(
                        (skill) => _skillTreeItem(
                          difficulty: DifficultyState.intermediate,
                          name: skill!.skillName,
                          onTap: () => context
                              .read<HomeCubit>()
                              .skillSelected(skill: skill),
                          onEdit: () => showDialog<CreateSkillDialog>(
                            context: context,
                            builder: (context) => CreateSkillDialog(
                              allSubCategories: state.subCategories ?? [],
                              isRider: state.isForRider,
                              isEdit: true,
                              skill: skill,
                              userName: state.usersProfile?.name,
                              position: state.intermediateSkills != null &&
                                      state.intermediateSkills!.isNotEmpty
                                  ? state.intermediateSkills!.length
                                  : 0,
                            ),
                          ),
                          state: state,
                          backgroundColor: Colors.yellowAccent.shade200,
                        ),
                      ),
                    ],
                  ),
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
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...state.advancedSkills!.map(
                        (skill) => _skillTreeItem(
                          difficulty: DifficultyState.advanced,
                          name: skill!.skillName,
                          onTap: () => context
                              .read<HomeCubit>()
                              .skillSelected(skill: skill),
                          onEdit: () => showDialog<CreateSkillDialog>(
                            context: context,
                            builder: (context) => CreateSkillDialog(
                              allSubCategories: state.subCategories ?? [],
                              isRider: state.isForRider,
                              isEdit: true,
                              skill: skill,
                              userName: state.usersProfile?.name,
                              position: state.advancedSkills != null &&
                                      state.advancedSkills!.isNotEmpty
                                  ? state.advancedSkills!.length
                                  : 0,
                            ),
                          ),
                          state: state,
                          backgroundColor: Colors.redAccent.shade200,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
        }
      } else {
        return const Center(child: Text('No Skills'));
      }
    case SkillTreeNavigation.SkillLevel:
      if (state.skill != null) {
        debugPrint('Skill: ${state.skill?.skillName} ');
        return _skillLevelItem(
          state: state,
          context: context,
          homeCubit: homeCubit,
          skillTreeFocus: skillTreeFocus,
        );
      } else {
        return errorView(context);
      }
  }
}

/* ****************************************************************************
                                  Skill Level
 **************************************************************************** */

Widget _skillLevelItem({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
  required FocusNode skillTreeFocus,
}) {
  return Stack(
    children: [
      SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(
              height: 50,
            ),
            // learningDescription or ProficientDescription
            // depending on the levelState if No Progress
            // show the learningDescription and if the levelState
            // is Learning show the ProficientDescription
            // if the levelState is Proficient
            // show a custom message
            Text(
              homeCubit.getLevelProgressDescription(),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Divider(),
            ),
            smallGap(),
            Text(state.skill?.description ?? ''),
            smallGap(),
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Divider(),
            ),
            Text('Resources', style: Theme.of(context).textTheme.titleLarge),
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Divider(),
            ),
            smallGap(),
            _skillResourcesList(
              state: state,
              homeCubit: homeCubit,
              context: context,
            ),
            smallGap(),
            const SizedBox(
              height: 50,
            ),
          ],
        ),
      ),

      // ProgressBar at the top

      // hide the progress bar if the
      Visibility(
        child: Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _skillLevelProgressBar(
            state: state,
            context: context,
            homeCubit: homeCubit,
          ),
        ),
      ),

      // AddResourceButton at the bottom
      // Positioned(
      //   bottom: 0,
      //   left: 0,
      //   right: 0,
      //   child: _addResourceButton(
      //     state: state,
      //     context: context,
      //     homeCubit: homeCubit,
      //     skillTreeFocus: skillTreeFocus,
      //   ),
      // ),
    ],
  );
}

Widget _addResourceButton({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
  required FocusNode skillTreeFocus,
}) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: ElevatedButton(
      onPressed: () {
        skillTreeFocus.requestFocus();
        homeCubit.search(
          searchList: state.allResources!.map((e) => e!.name).toList(),
        );
      },
      child: const Text('Add Resource'),
    ),
  );
}

/// Add a resource Dialog that shows all the resources
/// and has a search bar that can sort them by name
/// and a button to add a new resource
Widget _addResourceDialog({
  required BuildContext context,
  required HomeState state,
  required HomeCubit homeCubit,
}) {
  final focus = FocusNode();
  return AlertDialog(
    title: const Text('Add Resource'),
    content: SizedBox(
      width: 1000,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search Bar
          SearchField<String>(
            inputType: TextInputType.name,
            hint: 'Search Resources',
            focusNode: focus,
            onSearchTextChanged: (query) {
              homeCubit.resourceSearchQueryChanged(searchQuery: query);

              return state.searchList
                      ?.map(
                        (e) => SearchFieldListItem<String>(
                          e ?? '',
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(e!),
                          ),
                        ),
                      )
                      .toList() ??
                  [];
            },
            searchInputDecoration: InputDecoration(
              filled: true,
              iconColor: HorseAndRidersTheme().getTheme().iconTheme.color,
              fillColor:
                  HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
              prefixIcon: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios),
              ),
              hintText: 'Search Resources',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            suggestions: state.searchList
                    ?.map(
                      (e) => SearchFieldListItem<String>(
                        e ?? '',
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(e!),
                        ),
                      ),
                    )
                    .toList() ??
                [],
            onSuggestionTap: (value) {
              final selectedResource = state.allResources!.firstWhere(
                (resource) => resource?.name == value.searchKey,
              )!;
              debugPrint('Suggestion Tap Value: ${value.searchKey}');
              if (state.skill != null) {
                homeCubit.addResourceToSkill(
                  skill: state.skill,
                  resource: selectedResource,
                );
              }
            },
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.words,
            onSubmit: (p0) {
              debugPrint('Submit Value: $p0');
            },
          ),
          // Resource List
          Wrap(
            children: state.searchList
                    ?.map(
                      (e) => InkWell(
                        onTap: () => homeCubit.addResourceToSkill(
                          skill: state.skill,
                          resource: state.allResources!.firstWhere(
                            (resource) => resource?.name == e,
                          ),
                        ),
                        child: ListTile(
                          title: Text(e!),
                        ),
                      ),
                    )
                    .toList() ??
                [const Text('No Resources Found')],
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
    ],
  );
}

/// List of Resources for the selected skill shown in a wrap and resourceItem
Widget _skillResourcesList({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
  // Check if resources are not null and not empty
  if (state.allResources?.isNotEmpty ?? false) {
    // Filter the resources based on skillTreeIds containing the skill id
    final filteredResources = state.allResources!
        .where(
          (element) =>
              element?.skillTreeIds?.contains(state.skill?.id) ?? false,
        )
        .toList();

    // Check if the filtered list is not empty
    if (filteredResources.isNotEmpty) {
      return Wrap(
        alignment: WrapAlignment.center,
        runSpacing: 4,
        children: filteredResources
            .map(
              (e) => resourceItem(
                state: state,
                resource: e!,
                context: context,
                homeCubit: homeCubit,
                isResourceList: false,
                usersWhoRated: e.usersWhoRated,
              ),
            )
            .toList(),
      );
    } else {
      return const Text('No Resources Found');
    }
  } else {
    return const Text('No Resources Found');
  }
}

/// This will display the progress bar for the skill level
Widget _skillLevelProgressBar({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
// a bool for if the horseProfile is null and the skill we are viewing is not null
// is skill.isRider
  debugPrint('Skill for rider: ${state.skill?.rider}');
  debugPrint('Horse Profile: ${state.horseProfile}');
  final isConflict = state.horseProfile == null && state.skill?.rider == false;
  debugPrint('Is Conflict: $isConflict');
  return MaxWidthBox(
    maxWidth: 1000,
    child: Row(
      children: [
        // Learning
        Expanded(
          child: InkWell(
            onTap: state.isGuest || isConflict
                ? null
                : () {
                    showDialog<AlertDialog>(
                      context: context,
                      builder: (context) => _skillLevelSelectedConfirmation(
                        context: context,
                        homeCubit: homeCubit,
                        levelState: LevelState.LEARNING,
                      ),
                    );
                  },
            child: ColoredBox(
              color: homeCubit.levelColor(
                levelState: LevelState.LEARNING,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Learning',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      GestureDetector(
                        onTapDown: (details) {
                          InformationDialog.show(
                            context,
                            const Text(
                              // ignore: lines_longer_than_80_chars
                              'Learning: This stage indicates that the individual should be actively engaged in acquiring the skill. They should be in the process of understanding and practicing the basic concepts and techniques. Mistakes are common at this level, but they provide valuable learning experiences. The individual should be developing their abilities but not yet mastered the skill.',
                            ),
                            details.globalPosition,
                          );
                        },
                        child: const Icon(
                          Icons.info_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Proficient
        Expanded(
          child: InkWell(
            onTap: state.isGuest || isConflict
                ? null
                : () {
                    showDialog<AlertDialog>(
                      context: context,
                      builder: (context) => _skillLevelSelectedConfirmation(
                        context: context,
                        homeCubit: homeCubit,
                        levelState: LevelState.PROFICIENT,
                      ),
                    );
                  },
            child: ColoredBox(
              color: homeCubit.levelColor(
                levelState: LevelState.PROFICIENT,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Proficient', textAlign: TextAlign.center),
                      ),
                      GestureDetector(
                        onTapDown: (details) {
                          InformationDialog.show(
                            context,
                            const Text(
                              // ignore: lines_longer_than_80_chars
                              'Proficient: At this level, the individual should have achieved a significant degree of competence in the skill. They should demonstrate consistent and effective application of the skill in relevant situations. Proficiency implies that the individual can perform the skill independently and reliably, with a good understanding of advanced concepts and techniques.',
                            ),
                            details.globalPosition,
                          );
                        },
                        child: const Icon(
                          Icons.info_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Resource list
      ],
    ),
  );
}

Widget _skillLevelSelectedConfirmation({
  required HomeCubit homeCubit,
  required BuildContext context,
  required LevelState levelState,
}) {
  return AlertDialog(
    title: const Text('Confirm Skill Level'),
    content: Text(
      'Are you sure you want to set the skill level to ${levelState.name}?',
    ),
    actions: [
      TextButton(
        onPressed: () {
          homeCubit.levelSelected(
            levelState: levelState,
          );
          Navigator.of(context).pop();
        },
        child: const Text('Yes'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('No'),
      ),
    ],
  );
}

/* ****************************************************************************
                                  Skill Tree Item
 **************************************************************************** */

Widget _skillTreeItem({
  required String? name,
  required VoidCallback onTap,
  required VoidCallback onEdit,
  required HomeState state,
  required Color backgroundColor,
  required DifficultyState? difficulty,
}) {
  return InkWell(
    onTap: onTap,
    child: Card(
      color: backgroundColor,
      elevation: 8,
      child: SizedBox(
        width: 150,
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
                  visible: state.isEditState && state.usersProfile != null,
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

// this will determite what the skillTreeNavigation is and return the
// appropriate text
Widget _skillTreeNavigationText({
  required BuildContext context,
  required HomeState state,
}) {
  final screenSize = MediaQuery.of(context).size.width;

  switch (state.skillTreeNavigation) {
    case SkillTreeNavigation.Category:
      return Row(
        children: [
          _horseOrRiderIcon(state: state, size: screenSize * .07),
          smallGap(),
          const Text('Skill Tree Categories'),
        ],
      );

    case SkillTreeNavigation.SubCategory:
      return Row(
        children: [
          _horseOrRiderIcon(state: state, size: screenSize * .07),
          smallGap(),
          const Text('Training Paths'),
        ],
      );
    case SkillTreeNavigation.Skill:
      if (state.difficultyState == DifficultyState.all) {
        return Row(
          children: [
            _horseOrRiderIcon(state: state, size: screenSize * .07),
            smallGap(),
            Text('${state.category?.name ?? ''} '),
            Text(state.subCategory?.name ?? ''),
            const Text('Skills - All'),
          ],
        );
      } else if (state.difficultyState == DifficultyState.introductory) {
        return Row(
          children: [
            _horseOrRiderIcon(state: state, size: screenSize * .07),
            smallGap(),
            Text('${state.category?.name ?? ''} - '),
            Text('${state.subCategory?.name ?? ''} - '),
            const Text('Skills - Introductory'),
          ],
        );
      } else if (state.difficultyState == DifficultyState.intermediate) {
        return Row(
          children: [
            _horseOrRiderIcon(state: state, size: screenSize * .07),
            smallGap(),
            Text('${state.category?.name ?? ''} - '),
            Text('${state.subCategory?.name ?? ''} - '),
            const Text('Skillls - Intermediate'),
          ],
        );
      } else if (state.difficultyState == DifficultyState.advanced) {
        return Row(
          children: [
            _horseOrRiderIcon(state: state, size: screenSize * .07),
            smallGap(),
            Text('${state.category?.name ?? ''} - '),
            Text('${state.subCategory?.name ?? ''} - '),
            const Text('Skills - Advanced'),
          ],
        );
      } else {
        return Row(
          children: [
            _horseOrRiderIcon(state: state, size: screenSize * .07),
            smallGap(),
            Text('${state.category?.name ?? ''} - '),
            Text('${state.subCategory?.name ?? ''} - '),
            const Text('Skills'),
          ],
        );
      }
    case SkillTreeNavigation.SkillLevel:
      return Row(
        children: [
          _horseOrRiderIcon(state: state, size: screenSize * .07),
          smallGap(),
          Text('${state.skill?.skillName ?? ''} - '),
          const Text('Skill Level'),
        ],
      );
  }
}

Widget _horseOrRiderIcon({required HomeState state, double? size}) {
  if (state.isForRider) {
    return Icon(
      HorseAndRiderIcons.riderSkillIcon,
      size: size,
    );
  } else {
    return Icon(
      HorseAndRiderIcons.horseSkillIcon,
      size: size,
    );
  }
}

FloatingActionButton _floatingActionButton({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
  required FocusNode skillTreeFocus,
}) {
  return FloatingActionButton(
    onPressed: () {
      // open the add dialog
      // asscosiated with the current filter state
      switch (state.skillTreeNavigation) {
        case SkillTreeNavigation.Category:
          showDialog<CreateCategoryDialog>(
            context: context,
            builder: (context) => CreateCategoryDialog(
              isRider: true,
              isEdit: false,
              userName: state.usersProfile?.name ?? '',
              position:
                  state.categories!.isNotEmpty ? state.categories!.length : 0,
            ),
          );
          break;
        case SkillTreeNavigation.SubCategory:
          showDialog<CreateSubCategoryDialog>(
            context: context,
            builder: (context) => CreateSubCategoryDialog(
              skillTreeContext: context,
              skills: homeCubit.getAllSkills(),
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
        case SkillTreeNavigation.Skill:
          // open the add dialog
          // asscosiated with the current filter state
          showDialog<CreateSkillDialog>(
            context: context,
            builder: (context) => CreateSkillDialog(
              allSubCategories: state.subCategories ?? [],
              isRider: true,
              isEdit: false,
              userName: state.usersProfile?.name,
              position: state.allSkills != null && state.allSkills!.isNotEmpty
                  ? state.allSkills!.length
                  : 0,
            ),
          );
          break;
        case SkillTreeNavigation.SkillLevel:
          skillTreeFocus.requestFocus();
          homeCubit.search(
            searchList: state.allResources!.map((e) => e!.name).toList(),
          );
      }
    },
    tooltip: _toolTipText(state),
    child: const Icon(Icons.add),
  );
}

String _toolTipText(HomeState state) {
  switch (state.skillTreeNavigation) {
    case SkillTreeNavigation.Category:
      return 'Add a new Category';
    case SkillTreeNavigation.SubCategory:
      return 'Add a new SubCategory';
    case SkillTreeNavigation.Skill:
      return 'Add a new Skill';
    case SkillTreeNavigation.SkillLevel:
      return '';
  }
}
