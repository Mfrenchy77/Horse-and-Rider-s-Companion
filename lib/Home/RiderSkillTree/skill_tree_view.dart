// ignore_for_file: lines_longer_than_80_chars, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/search_confimatio_dialog.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/CreateSkillTreeDialogs/Views/training_path_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/skill_level.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/skills_list.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/training_path_view.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/training_paths_list.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:searchfield/searchfield.dart';

///   This is the main view for the Skill Tree
/// It will display the categories, subcategories, skills, and levels
/// for the selected category, subcategory, skill, or level
/// it will also allow authorized users to edit the skill tree
///
Widget skillTreeView() {
  final skillTreeFocus = FocusNode();

  return BlocBuilder<HomeCubit, HomeState>(
    builder: (context, state) {
      final homeCubit = context.read<HomeCubit>();
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
                      return trainingPathView();
                    case SkillTreeNavigation.TrainingPathList:
                      return trainingPathsList();
                    case SkillTreeNavigation.SkillList:
                      return skillsList();
                    case SkillTreeNavigation.SkillLevel:
                      return skillLevel();
                  }
                },
              ),
              Breakpoints.medium: SlotLayout.from(
                key: const Key('primaryView'),
                builder: (_) {
                  switch (state.skillTreeNavigation) {
                    case SkillTreeNavigation.TrainingPath:
                      return trainingPathView();
                    case SkillTreeNavigation.TrainingPathList:
                      return trainingPathsList();
                    case SkillTreeNavigation.SkillList:
                      return skillsList();
                    case SkillTreeNavigation.SkillLevel:
                      return skillLevel();
                  }
                },
              ),
              Breakpoints.large: SlotLayout.from(
                key: const Key('primaryView'),
                builder: (_) {
                  switch (state.skillTreeNavigation) {
                    case SkillTreeNavigation.TrainingPath:
                      return trainingPathsList();
                    case SkillTreeNavigation.TrainingPathList:
                      return trainingPathsList();
                    case SkillTreeNavigation.SkillList:
                      return skillsList();
                    case SkillTreeNavigation.SkillLevel:
                      return state.isFromTrainingPath
                          ? trainingPathView()
                          : state.isFromTrainingPathList
                              ? trainingPathView()
                              : skillsList();
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
                      return trainingPathView();
                    case SkillTreeNavigation.TrainingPathList:
                      return trainingPathView();
                    case SkillTreeNavigation.SkillList:
                      return skillLevel();
                    case SkillTreeNavigation.SkillLevel:
                      return skillLevel();
                  }
                },
              ),
            },
          ),

          // Add additional configurations for other UI elements like bottomNavigation, etc.
        ),
      );
    },
  );

  // return Scaffold(
  //   appBar: _appBar(
  //     state: state,
  //     context: context,
  //     homeCubit: homeCubit,
  //     skillTreeFocus: skillTreeFocus,
  //   ),
  //   floatingActionButton: Visibility(
  //     visible: state.usersProfile?.editor ?? false,
  //     child: _floatingActionButton(
  //       state: state,
  //       context: context,
  //       homeCubit: homeCubit,
  //       skillTreeFocus: skillTreeFocus,
  //     ),
  //   ),
  //   body: _skillTreeItems(
  //     state: state,
  //     context: context,
  //     homeCubit: homeCubit,
  //     skillTreeFocus: skillTreeFocus,
  //   ),
  // );
}

// Widget _description({required HomeState state}) {
//   switch (state.skillTreeNavigation) {
//     case SkillTreeNavigation.Category:
//       return const Text('');
//     case SkillTreeNavigation.SubCategory:
//       debugPrint('Category Description: ${state.category?.description}');
//       return Text(state.category?.description ?? '');
//     case SkillTreeNavigation.Skill:
//       debugPrint('SubCategory Description: ${state.subCategory?.description}');
//       return Text(state.subCategory?.description ?? '');
//     case SkillTreeNavigation.SkillLevel:
//       return Text(state.skill?.description ?? '');
//   }
// }

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
            hint: state.skillTreeNavigation == SkillTreeNavigation.SkillList
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
              debugPrint('Suggestion Tap Value: ${value.searchKey}');
              skillTreeFocus.unfocus();
              state.skillTreeNavigation == SkillTreeNavigation.SkillList
                  ? homeCubit.navigateToSkillLevel(
                      isSplitScreen: isSplitScreen,
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
        : Text(_appbarTitle(state, homeCubit)),
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
              homeCubit.navigateToTrainingPathList();
              break;
            case SkillTreeNavigation.SkillLevel:
              if (isSplitScreen) {
                state.isFromTrainingPath
                    ? homeCubit.navigateToTrainingPathList()
                    : state.isFromTrainingPathList
                        ? homeCubit.profileNavigationSelected()
                        : homeCubit.navigateToSkillsList();
              } else {
                state.isFromTrainingPath
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
          homeCubit.navigateToTrainingPathList();
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
  final Widget createTraingPath = IconButton(
    onPressed: state.usersProfile == null
        ? null
        : () => showDialog<CreateTrainingPathDialog>(
              context: context,
              builder: (context) => CreateTrainingPathDialog(
                usersProfile: state.usersProfile!,
                trainingPath: null,
                isEdit: false,
                allSkills: state.allSkills!,
                isForRider: true,
              ),
            ),
    icon: const Icon(Icons.add),
  );
//icon for navigating to the skills list
  final Widget skillsList = Visibility(
    visible: isMobile,
    child: Visibility(
      visible:
          state.skillTreeNavigation == SkillTreeNavigation.TrainingPathList ||
              state.skillTreeNavigation == SkillTreeNavigation.TrainingPath ||
              state.skillTreeNavigation == SkillTreeNavigation.SkillLevel,
      child: Tooltip(
        message: 'Skills',
        child: IconButton(
          icon: const Icon(Icons.list),
          onPressed: () {
            homeCubit.navigateToSkillsList();
          },
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
          icon: const Icon(Icons.list),
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
    child: Visibility(
      visible: state.skillTreeNavigation == SkillTreeNavigation.SkillLevel ||
          state.skillTreeNavigation == SkillTreeNavigation.SkillLevel,
      child: Tooltip(
        message: 'Search',
        child: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            skillTreeFocus.requestFocus();
            if (state.skillTreeNavigation == SkillTreeNavigation.SkillList) {
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
    ..add(skillsList)
    ..add(search)
    ..add(createTraingPath)
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
    case SkillTreeNavigation.TrainingPathList:
      return 'Training Paths';
    case SkillTreeNavigation.TrainingPath:
      return state.trainingPath?.name ?? '';
    case SkillTreeNavigation.SkillList:
      return 'Skills';
    case SkillTreeNavigation.SkillLevel:
      return 'Levels for ${state.skill?.skillName ?? ''}';
  }
}

// this will determite what the skillTreeNavigation is and return the
// appropriate text
// Widget _skillTreeNavigationText({
//   required BuildContext context,
//   required HomeState state,
// }) {
//   final screenSize = MediaQuery.of(context).size.width;

//   switch (state.skillTreeNavigation) {
//     case SkillTreeNavigation.Category:
//       return Row(
//         children: [
//           _horseOrRiderIcon(state: state, size: screenSize * .07),
//           smallGap(),
//           const Text('Skill Tree Categories'),
//         ],
//       );

//     case SkillTreeNavigation.SubCategory:
//       return Row(
//         children: [
//           _horseOrRiderIcon(state: state, size: screenSize * .07),
//           smallGap(),
//           const Text('Training Paths'),
//         ],
//       );
//     case SkillTreeNavigation.Skill:
//       if (state.difficultyState == DifficultyState.all) {
//         return Row(
//           children: [
//             _horseOrRiderIcon(state: state, size: screenSize * .07),
//             smallGap(),
//             Text('${state.category?.name ?? ''} '),
//             Text(state.subCategory?.name ?? ''),
//             const Text('Skills - All'),
//           ],
//         );
//       } else if (state.difficultyState == DifficultyState.introductory) {
//         return Row(
//           children: [
//             _horseOrRiderIcon(state: state, size: screenSize * .07),
//             smallGap(),
//             Text('${state.category?.name ?? ''} - '),
//             Text('${state.subCategory?.name ?? ''} - '),
//             const Text('Skills - Introductory'),
//           ],
//         );
//       } else if (state.difficultyState == DifficultyState.intermediate) {
//         return Row(
//           children: [
//             _horseOrRiderIcon(state: state, size: screenSize * .07),
//             smallGap(),
//             Text('${state.category?.name ?? ''} - '),
//             Text('${state.subCategory?.name ?? ''} - '),
//             const Text('Skillls - Intermediate'),
//           ],
//         );
//       } else if (state.difficultyState == DifficultyState.advanced) {
//         return Row(
//           children: [
//             _horseOrRiderIcon(state: state, size: screenSize * .07),
//             smallGap(),
//             Text('${state.category?.name ?? ''} - '),
//             Text('${state.subCategory?.name ?? ''} - '),
//             const Text('Skills - Advanced'),
//           ],
//         );
//       } else {
//         return Row(
//           children: [
//             _horseOrRiderIcon(state: state, size: screenSize * .07),
//             smallGap(),
//             Text('${state.category?.name ?? ''} - '),
//             Text('${state.subCategory?.name ?? ''} - '),
//             const Text('Skills'),
//           ],
//         );
//       }
//     case SkillTreeNavigation.SkillLevel:
//       return Row(
//         children: [
//           _horseOrRiderIcon(state: state, size: screenSize * .07),
//           smallGap(),
//           Text('${state.skill?.skillName ?? ''} - '),
//           const Text('Skill Level'),
//         ],
//       );
//   }
// }

// Widget _horseOrRiderIcon({required HomeState state, double? size}) {
//   if (state.isForRider) {
//     return Icon(
//       HorseAndRiderIcons.riderSkillIcon,
//       size: size,
//     );
//   } else {
//     return Icon(
//       HorseAndRiderIcons.horseSkillIcon,
//       size: size,
//     );
//   }
// }

// FloatingActionButton _floatingActionButton({
//   required HomeState state,
//   required HomeCubit homeCubit,
//   required BuildContext context,
//   required FocusNode skillTreeFocus,
// }) {
//   return FloatingActionButton(
//     onPressed: () {
//       // open the add dialog
//       // asscosiated with the current filter state
//       switch (state.skillTreeNavigation) {
//         case SkillTreeNavigation.Category:
//           showDialog<CreateCategoryDialog>(
//             context: context,
//             builder: (context) => CreateCategoryDialog(
//               isRider: true,
//               isEdit: false,
//               userName: state.usersProfile?.name ?? '',
//               position:
//                   state.categories!.isNotEmpty ? state.categories!.length : 0,
//             ),
//           );
//           break;
//         case SkillTreeNavigation.SubCategory:
//           showDialog<CreateSubCategoryDialog>(
//             context: context,
//             builder: (context) => CreateSubCategoryDialog(
//               skills: state.allSkills ?? [],
//               subCategory: null,
//               isEdit: false,
//               isRider: true,
//               category: state.category,
//               position:
//                   state.subCategories != null && state.subCategories!.isNotEmpty
//                       ? state.subCategories!.length
//                       : 0,
//             ),
//           );
//           break;
//         case SkillTreeNavigation.Skill:
//           // open the add dialog
//           // asscosiated with the current filter state
//           showDialog<CreateSkillDialog>(
//             context: context,
//             builder: (context) => CreateSkillDialog(
//               allSubCategories: state.subCategories ?? [],
//               isRider: true,
//               isEdit: false,
//               userName: state.usersProfile?.name,
//               position: state.allSkills != null && state.allSkills!.isNotEmpty
//                   ? state.allSkills!.length
//                   : 0,
//             ),
//           );
//           break;
//         case SkillTreeNavigation.SkillLevel:
//           skillTreeFocus.requestFocus();
//           homeCubit.search(
//             searchList: state.allResources!.map((e) => e!.name).toList(),
//           );
//       }
//     },
//     tooltip: _toolTipText(state),
//     child: const Icon(Icons.add),
//   );
// }

String _toolTipText(HomeState state) {
  switch (state.skillTreeNavigation) {
    case SkillTreeNavigation.TrainingPathList:
      return 'Add a new Training Path';
    case SkillTreeNavigation.TrainingPath:
      return 'Add a new Training Path';
    case SkillTreeNavigation.SkillList:
      return 'Add a new Skill';
    case SkillTreeNavigation.SkillLevel:
      return '';
  }
}
