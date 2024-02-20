// ignore_for_file: lines_longer_than_80_chars, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/search_confimatio_dialog.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/skill_level.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/skills_list.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/training_path_view.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/training_paths_list.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/main.dart';
import 'package:searchfield/searchfield.dart';

///   This is the main view for the Skill Tree
/// It will display the categories, subcategories, skills, and levels
/// for the selected category, subcategory, skill, or level
/// it will also allow authorized users to edit the skill tree
///
Widget skillTreeView({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  final skillTreeFocus = FocusNode();

  return Scaffold(
    appBar: _appBar(
      context: context,
      homeCubit: homeCubit,
      state: state,
      skillTreeFocus: skillTreeFocus,
    ),
    body: AdaptiveLayout(
      // topNavigation: SlotLayout(
      //   config: <Breakpoint, SlotLayoutConfig>{
      //     Breakpoints.standard: SlotLayout.from(
      //       key: const Key('topNavigation'),
      //       builder: (_) => _appBar(
      //         skillTreeFocus: skillTreeFocus,
      //       ),
      //     ),
      //   },
      // ),
      body: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          Breakpoints.small: SlotLayout.from(
            key: const Key('primaryView'),
            builder: (_) {
              switch (state.skillTreeNavigation) {
                case SkillTreeNavigation.TrainingPath:
                  return trainingPathView(
                    state: state,
                    homeCubit: homeCubit,
                    context: context,
                  );
                case SkillTreeNavigation.TrainingPathList:
                  return trainingPathsList(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                  );
                case SkillTreeNavigation.SkillList:
                  return skillsList(
                    skills: homeCubit.skillsList(),
                    context: context,
                    state: state,
                    homeCubit: homeCubit,
                  );
                case SkillTreeNavigation.SkillLevel:
                  return skillLevel(
                    homeCubit: homeCubit,
                    state: state,
                    context: context,
                  );
              }
            },
          ),
          Breakpoints.medium: SlotLayout.from(
            key: const Key('primaryView'),
            builder: (_) {
              switch (state.skillTreeNavigation) {
                case SkillTreeNavigation.TrainingPath:
                  return trainingPathView(
                    state: state,
                    homeCubit: homeCubit,
                    context: context,
                  );
                case SkillTreeNavigation.TrainingPathList:
                  return trainingPathsList(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                  );
                case SkillTreeNavigation.SkillList:
                  return skillsList(
                    skills: homeCubit.skillsList(),
                    context: context,
                    state: state,
                    homeCubit: homeCubit,
                  );
                case SkillTreeNavigation.SkillLevel:
                  return skillLevel(
                    homeCubit: homeCubit,
                    state: state,
                    context: context,
                  );
              }
            },
          ),
          Breakpoints.large: SlotLayout.from(
            key: const Key('primaryView'),
            builder: (_) {
              switch (state.skillTreeNavigation) {
                case SkillTreeNavigation.TrainingPath:
                  return trainingPathsList(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                  );
                case SkillTreeNavigation.TrainingPathList:
                  return trainingPathsList(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                  );
                case SkillTreeNavigation.SkillList:
                  return skillsList(
                    skills: homeCubit.skillsList(),
                    context: context,
                    state: state,
                    homeCubit: homeCubit,
                  );
                case SkillTreeNavigation.SkillLevel:
                  return state.isFromProfile
                      ? trainingPathsList(
                          context: context,
                          homeCubit: homeCubit,
                          state: state,
                        )
                      : state.isFromTrainingPath
                          ? trainingPathView(
                              state: state,
                              homeCubit: homeCubit,
                              context: context,
                            )
                          : state.isFromTrainingPathList
                              ? trainingPathView(
                                  state: state,
                                  homeCubit: homeCubit,
                                  context: context,
                                )
                              : skillsList(
                                  skills: homeCubit.skillsList(),
                                  context: context,
                                  state: state,
                                  homeCubit: homeCubit,
                                );
              }
            },
          ),
        },
      ),
      secondaryBody: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          Breakpoints.large: SlotLayout.from(
            key: const Key('secondaryView'),
            builder: (_) {
              switch (state.skillTreeNavigation) {
                case SkillTreeNavigation.TrainingPath:
                  return trainingPathView(
                    state: state,
                    homeCubit: homeCubit,
                    context: context,
                  );
                case SkillTreeNavigation.TrainingPathList:
                  return trainingPathView(
                    state: state,
                    homeCubit: homeCubit,
                    context: context,
                  );
                case SkillTreeNavigation.SkillList:
                  return skillLevel(
                    homeCubit: homeCubit,
                    state: state,
                    context: context,
                  );
                case SkillTreeNavigation.SkillLevel:
                  return skillLevel(
                    homeCubit: homeCubit,
                    state: state,
                    context: context,
                  );
              }
            },
          ),
        },
      ),
    ),
  );
}

//Search Bar for Skills and Resources
PreferredSizeWidget _appBar({
  required FocusNode skillTreeFocus,
  required HomeCubit homeCubit,
  required HomeState state,
  required BuildContext context,
}) {
  final isSplitScreen = MediaQuery.of(context).size.width > 800;

  return AppBar(
    centerTitle: true,
    title: state.isSearch
        ? SearchField<String>(
            suggestionState:
                state.isSearch ? Suggestion.expand : Suggestion.hidden,
            inputType: TextInputType.name,
            // should say search skills, search resources, or search training paths
            hint: state.skillTreeNavigation == SkillTreeNavigation.SkillList
                ? 'Search Skills'
                : state.skillTreeNavigation == SkillTreeNavigation.SkillLevel
                    ? 'Search Resources'
                    : 'Search Training Paths',
            focusNode: skillTreeFocus,
            onSearchTextChanged: (query) {
              state.skillTreeNavigation == SkillTreeNavigation.SkillList
                  ? homeCubit.skillSearchQueryChanged(searchQuery: query)
                  : state.skillTreeNavigation == SkillTreeNavigation.SkillLevel
                      ? homeCubit.resourceSearchQueryChanged(searchQuery: query)
                      : homeCubit.trainingPathSearchQueryChanged(
                          searchQuery: query,
                        );

              return state.searchList
                      ?.map(
                        (e) => SearchFieldListItem<String>(
                          e ?? '',
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(e ?? ''),
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
              suffixIcon: IconButton(
                onPressed: homeCubit.closeSearch,
                icon: const Icon(Icons.clear),
              ),
              hintText:
                  state.skillTreeNavigation == SkillTreeNavigation.SkillList
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
              homeCubit.closeSearch();
              debugPrint('Suggestion Tap Value: ${value.searchKey}');
              state.skillTreeNavigation == SkillTreeNavigation.SkillList
                  ? homeCubit.navigateToSkillLevel(
                      isSplitScreen: isSplitScreen,
                      skill: state.allSkills!.firstWhere(
                        (skill) => skill?.skillName == value.searchKey,
                      ),
                    )
                  : state.skillTreeNavigation ==
                          SkillTreeNavigation.TrainingPathList
                      ? homeCubit.navigateToTrainingPath(
                          trainingPath: state.trainingPaths.firstWhere(
                            (element) => element?.name == value.item,
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
                                    (resource) =>
                                        resource?.name == value.searchKey,
                                  ),
                                )
                                ..closeSearch();
                              Navigator.pop(context);
                            },
                            cancelTap: () {
                              homeCubit.closeSearch();
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
          )
        : appBarTitle(),
    actions: _appbarActions(
      state: state,
      context: context,
      homeCubit: homeCubit,
      skillTreeFocus: skillTreeFocus,
    ),
    leading: Visibility(
      visible: MediaQuery.of(context).size.width < 800,
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back,
        ),
        onPressed: () {
          final isSplitScreen = MediaQuery.of(context).size.width > 1200;
          switch (state.skillTreeNavigation) {
            case SkillTreeNavigation.TrainingPathList:
              homeCubit.profileNavigationSelected();
              break;
            case SkillTreeNavigation.TrainingPath:
              homeCubit.navigateToTrainingPathList();
              break;
            case SkillTreeNavigation.SkillList:
              state.isFromProfile
                  ? homeCubit.profileNavigationSelected()
                  : homeCubit.navigateToTrainingPathList();
              break;
            case SkillTreeNavigation.SkillLevel:
              state.isFromProfile
                  ? homeCubit.profileNavigationSelected()
                  : homeCubit.navigateToSkillsList();
              if (isSplitScreen) {
                state.isFromProfile
                    ? homeCubit.profileNavigationSelected()
                    : state.isFromTrainingPath
                        ? homeCubit.navigateToTrainingPathList()
                        : state.isFromTrainingPathList
                            ? homeCubit.profileNavigationSelected()
                            : homeCubit.navigateToSkillsList();
              } else {
                state.isFromProfile
                    ? homeCubit.profileNavigationSelected()
                    : state.isFromTrainingPath
                        ? homeCubit.navigateToTrainingPath(
                            trainingPath: state.trainingPath,
                          )
                        : state.isFromTrainingPathList
                            ? homeCubit.navigateToTrainingPathList()
                            : homeCubit.navigateToSkillsList();
              }
              break;
            //default navigate to profile
          }
        },
      ),
    ),
  );
}

// FIXME: this is a mess
List<Widget> _appbarActions({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
  required FocusNode skillTreeFocus,
}) {
  final isMobile = MediaQuery.of(context).size.width < 800;
  final actions = <Widget>[];
  final isEditor = state.usersProfile?.editor ?? false;

// popup menu for the edit button when the
// screen size is small we only want to show the
// Difficulty option if the skillTreeNavigation is Skill
  final Widget skillsPopupMenu = PopupMenuButton<String>(
    itemBuilder: (context) {
      if (state.skillTreeNavigation == SkillTreeNavigation.SkillList) {
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
          if (!state.isGuest && isEditor)
            const PopupMenuItem(
              value: 'Edit',
              child: Text('Toggle Edit Controls'),
            ),
        ];
      } else {
        return [
          const PopupMenuItem(
            value: 'Skills',
            child: Text('Skills'),
          ),
          if (!state.isGuest && isEditor)
            const PopupMenuItem(
              value: 'Edit',
              child: Text('Toggle Edit Controls'),
            ),
        ];
      }
    },
    onSelected: (value) {
      switch (value) {
        case 'Skills':
          homeCubit.navigateToSkillsList();
          break;
        case 'Edit':
          homeCubit.toggleIsEditState();
          break;
        case 'Difficulty':
          // open the sort dialog
          homeCubit.openDifficultySelectDialog(
            context: context,
            subCategory: state.subCategory,
          );
          break;
        case 'Training Paths':
          homeCubit.navigateToTrainingPathList();
          break;
      }
    },
  );

//icon for navigating to the skills list
  final Widget skillsList = Visibility(
    visible: !isMobile,
    child: Visibility(
      visible:
          state.skillTreeNavigation == SkillTreeNavigation.TrainingPathList ||
              state.skillTreeNavigation == SkillTreeNavigation.TrainingPath ||
              state.skillTreeNavigation == SkillTreeNavigation.SkillLevel,
      child: Tooltip(
        message: 'Skills',
        child: IconButton(
          icon: const Icon(Icons.list),
          onPressed: homeCubit.navigateToSkillsList,
        ),
      ),
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
      visible: state.skillTreeNavigation == SkillTreeNavigation.SkillList,
      child: Tooltip(
        message: 'Training Paths',
        child: IconButton(
          icon: const Icon(Icons.account_tree_outlined),
          onPressed: () {
            // open the sort dialog
            homeCubit.navigateToTrainingPathList();
          },
        ),
      ),
    ),
  );

  //Search
  final Widget search = Visibility(
    visible: !state.isSearch,
    child: Tooltip(
      message:
          'Search for ${state.skillTreeNavigation == SkillTreeNavigation.SkillList ? 'Skills' : state.skillTreeNavigation == SkillTreeNavigation.SkillLevel ? 'Resources' : 'Training Paths'}',
      child: IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          skillTreeFocus.requestFocus();
          if (state.skillTreeNavigation == SkillTreeNavigation.SkillList) {
            homeCubit.search(
              searchList: state.allSkills!.map((e) => e!.skillName).toList(),
            );
          } else if (state.skillTreeNavigation ==
              SkillTreeNavigation.TrainingPathList) {
            homeCubit.search(
              searchList: state.isForRider
                  ? state.trainingPaths
                      .where((element) => element?.isForHorse == false)
                      .map((e) => e!.name)
                      .toList()
                  : state.trainingPaths
                      .where((element) => element?.isForHorse == true)
                      .map((e) => e!.name)
                      .toList(),
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
  );

  //difficulty
  final Widget difficulty = Visibility(
    visible: !isMobile,
    child: Visibility(
      visible: state.skillTreeNavigation == SkillTreeNavigation.SkillList,
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
    ..add(skillsPopupMenu);
  // ..add(skillsList)
  // ..add(trainingPaths)
  // ..add(difficulty)
  // ..add(editIcon)
  // ;
  return actions;
}
