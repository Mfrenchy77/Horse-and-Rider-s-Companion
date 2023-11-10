/* // ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars, prefer_int_literals

import 'package:auto_size_text/auto_size_text.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/category_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/level_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/skill_create_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/sub_category_create_dialog.dart';
import 'package:horseandriderscompanion/HorseProfile/cubit/horse_profile_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:responsive_framework/responsive_framework.dart';

class HorseSkillTreeView extends StatelessWidget {
  const HorseSkillTreeView({
    required this.state,
    super.key,
    required this.riderProfile,
    required this.isForRider,
  });
  final HorseHomeState state;
  final RiderProfile? riderProfile;
  final bool isForRider;

  @override
  Widget build(BuildContext context) {
    if (state.horseProfile != null) {
      if (state.status == SkillTreeStatus.categories) {
        return _categoryView(
          state: state,
          context: context,
          riderProfile: riderProfile,
        );
      } else if (state.status == SkillTreeStatus.subCategories) {
        return _subCategoryView(
          category: state.category,
          state: state,
          context: context,
          riderProfile: riderProfile,
        );
      } else if (state.status == SkillTreeStatus.skill) {
        return _skillView(
          state: state,
          context: context,
          riderProfile: riderProfile,
        );
      } else if (state.status == SkillTreeStatus.level) {
        return _levelView(
          isForRider: isForRider,
          state: state,
          context: context,
          horseProfile: state.horseProfile as HorseProfile,
        );
      } else {
        return const Center(
          child: Logo(
            screenName: 'screenName: Loading: SkillTree...',
          ),
        );
      }
    } else {
      return const Center(
        child: Logo(
          screenName: 'SkillTree Loading...',
        ),
      );
    }
  }
}

Widget _levelView({
  required bool isForRider,
  required HorseHomeState state,
  required BuildContext context,
  required HorseProfile horseProfile,
}) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          // color: COLOR_CONST.BLACK,
        ),
        onPressed: () {
          context
              .read<HorseHomeCubit>()
              .categorySelected(category: state.category);
        },
      ),
      title: Text('Levels for ${state.skill?.skillName}'),
      actions: [
        Visibility(
          visible: state.usersProfile?.editor ?? true,
          child: Switch(
            value: state.isEditState,
            onChanged: (value) {
              context.read<HorseHomeCubit>().toggleLevelsEdit(
                    levels: state.levels,
                    skill: state.skill,
                    isEdit: value,
                    category: state.category,
                    skills: state.skills,
                  );
            },
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Category: ${state.category?.name} - Skill: ${state.skill?.skillName} - Levels',
                style: const TextStyle(
                  // color: COLOR_CONST.WHITE,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          _levelsList(state: state, horseProfile: horseProfile),
        ],
      ),
    ),
    floatingActionButton: Visibility(
      visible: state.isEditState,
      child: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog<CreateLevelDialog>(
            context: context,
            builder: (context) => CreateLevelDialog(
              isEdit: false,
              isForRider: isForRider,
              skill: state.skill,
              userName: state.usersProfile?.name,
              position: state.levels != null && state.levels!.isNotEmpty
                  ? state.levels!.length
                  : 0,
            ),
          );
        },
      ),
    ),
  );
}

Widget _levelsList({
  required HorseHomeState state,
  required HorseProfile horseProfile,
}) {
  final levels = state.levels;
  if (levels != null && levels.isNotEmpty) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        return _levelItem(
          horseProfile: horseProfile,
          context: context,
          level: level,
          state: state,
        );
      },
    );
  } else {
    return const Center(
      child: Text('No Levels, add some'),
    );
  }
}

Widget _levelItem({
  required BuildContext context,
  required Level? level,
  required HorseHomeState state,
  required HorseProfile horseProfile,
}) {
  var isHidden = true;
  final isDark = SharedPrefs().isDarkMode;
  return level != null
      ? InkWell(
          // onTap: () {
          //   context.read<HomeCubit>().levelSelected(level);
          // },
          child: Card(
            //color: COLOR_CONST.DEFAULT,
            elevation: 8,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: IntrinsicWidth(
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    children: [
                      _skillLevelView(
                        horseProfile: horseProfile,
                        level: level,
                        context: context,
                        state: state,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 4,
                            child: IconButton(
                              alignment: Alignment.centerLeft,
                              onPressed: () => setState(
                                () => isHidden = !isHidden,
                              ),
                              icon: Icon(
                                isHidden
                                    ? Icons.chevron_right
                                    : Icons.keyboard_arrow_down,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 8,
                            child: Text(
                              level.levelName as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          Visibility(
                            visible: state.isEditState,
                            child: IconButton(
                              onPressed: () {
                                showDialog<CreateLevelDialog>(
                                  context: context,
                                  builder: (context) => CreateLevelDialog(
                                    skill: state.skill,
                                    isForRider: true,
                                    level: level,
                                    isEdit: true,
                                    userName: state.usersProfile?.name,
                                    position: state.categories!.isNotEmpty
                                        ? state.categories!.length
                                        : 0,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      smallGap(),
                      Visibility(
                        visible: !isHidden,
                        child: Column(
                          children: [
                            Text(
                              '${level.description}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            gap(),
                            const Text(
                              'Learning Description:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${level.learningDescription}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            gap(),
                            const Text(
                              'Complete Description:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${level.completeDescription}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      smallGap(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
      : const Text('No Level :( ');
}

Widget _skillLevelView({
  required Level level,
  required BuildContext context,
  required HorseHomeState state,
  required HorseProfile horseProfile,
}) {
  return Row(
    // each child need to strech to fill the row
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.check_circle_outline,
          color: context
              .read<HorseHomeCubit>()
              .isVerified(horseProfile: horseProfile, level: level),
        ),
      ),
      InkWell(
        onTap: () {
          debugPrint('no progress: ${level.levelName}');
          context
              .read<HorseHomeCubit>()
              .levelSelected(level: level, levelState: LevelState.NO_PROGRESS);
        },
        child: state.levelSubmitionStatus == LevelSubmitionStatus.submitting
            ? const CircularProgressIndicator()
            : SizedBox(
                height: 50,
                width: 100,
                child: ColoredBox(
                  color: context.read<HorseHomeCubit>().isLevelUnlocked(
                        horseProfile: horseProfile,
                        level: level,
                        levelState: LevelState.NO_PROGRESS,
                      ),
                  child: const Center(child: Text('No Progress')),
                ),
              ),
      ),
      InkWell(
        onTap: () {
          context
              .read<HorseHomeCubit>()
              .levelSelected(level: level, levelState: LevelState.LEARNING);
          debugPrint('learning: ${level.levelName}');
        },
        child: state.levelSubmitionStatus == LevelSubmitionStatus.submitting
            ? const CircularProgressIndicator()
            : SizedBox(
                height: 50,
                width: 100,
                child: ColoredBox(
                  color: context.read<HorseHomeCubit>().isLevelUnlocked(
                        horseProfile: horseProfile,
                        level: level,
                        levelState: LevelState.LEARNING,
                      ),
                  child: const Center(child: Text('Learning')),
                ),
              ),
      ),
      InkWell(
        onTap: () {
          context
              .read<HorseHomeCubit>()
              .levelSelected(level: level, levelState: LevelState.COMPLETE);
          debugPrint('complete: ${level.levelName}');
        },
        child: state.levelSubmitionStatus == LevelSubmitionStatus.submitting
            ? const CircularProgressIndicator()
            : SizedBox(
                height: 50,
                width: 100,
                child: ColoredBox(
                  color: context.read<HorseHomeCubit>().isLevelUnlocked(
                        horseProfile: horseProfile,
                        level: level,
                        levelState: LevelState.COMPLETE,
                      ),
                  child: const Center(child: Text('Complete')),
                ),
              ),
      ),
      Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.check_circle_outline,
          color: context
              .read<HorseHomeCubit>()
              .isVerified(horseProfile: horseProfile, level: level),
        ),
      ),
    ],
  );
}

Widget _skillView({
  required HorseHomeState state,
  required BuildContext context,
  required RiderProfile? riderProfile,
}) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          // color: COLOR_CONST.BLACK,
        ),
        onPressed: () {
          context.read<HorseHomeCubit>().skillTreeSelected();
        },
      ),
      title: Text('Skills for ${state.category?.name}'),
      actions: [
        Visibility(
          visible: riderProfile?.editor ?? true,
          child: Switch(
            value: state.isEditState,
            onChanged: (value) {
              context.read<HorseHomeCubit>().toggleSkillsEdit(
                    isEdit: value,
                    category: state.category,
                    skills: state.skills,
                  );
            },
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: [
                  Icon(
                    HorseAndRiderIcons.horseSkillIcon,
                    size: MediaQuery.of(context).size.width *
                        0.07, // 10% of screen width
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  gap(),
                  Text(
                    'Category: ${state.category?.name} - Skills',
                    style: const TextStyle(
                      // color: COLOR_CONST.WHITE,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _skillsGrid(
            context: context,
            state: state,
            usersProfile: riderProfile as RiderProfile,
          ),
        ],
      ),
    ),
    floatingActionButton: Visibility(
      visible: state.isEditState,
      child: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog<CreateSkillDialog>(
            context: context,
            builder: (context) => CreateSkillDialog(
              isRider: false,
              isEdit: false,
              subCategory: state.subCategory,
              userName: riderProfile.name,
              position: state.skills != null && state.skills!.isNotEmpty
                  ? state.skills!.length
                  : 0,
            ),
          );
        },
      ),
    ),
  );
}

// a widget that contains a grid of skills and subcategories
// that resises based on the screen size and grid size
Widget _skillsGrid({
  required BuildContext context,
  required HorseHomeState state,
  required RiderProfile usersProfile,
}) {
  final skills = state.skills;
  final screenWidth = MediaQuery.of(context).size.width;
  final crossAxisCount = screenWidth < 600
      ? 2
      : // For small screens, have 2 items in a row.
      screenWidth < 1000
          ? 3
          : // For medium screens, have 3.
          4; // For large screens, have 4.

// Calculate the size of each item based on screen width and crossAxisCount.
  final itemWidth = screenWidth / crossAxisCount;
  return Center(
    child: GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio:
            itemWidth / 250, // Adjust the item height relative to item width.
        mainAxisSpacing: 10, // Adjust as needed.
        crossAxisSpacing: 10, // Adjust as needed.
      ),
      itemCount: skills?.length,
      itemBuilder: (context, index) {
        final skillItem = skills?[index];
        return _circleSkillItem(
          subCategory: state.subCategory,
          usersProfile: usersProfile,
          state: state,
          context: context,
          skillItem: skillItem,
          category: state.category,
        );
      },
    ),
  );
}

Widget _circleSkillItem({
  required BuildContext context,
  Skill? skillItem,
  required Catagorry? category,
  required SubCategory? subCategory,
  required HorseHomeState state,
  required RiderProfile usersProfile,
}) {
  //determine if item is a skill or a category and open the correct view
  if (skillItem != null) {
    return InkWell(
      onTap: () {
        context.read<HorseHomeCubit>().skillSelected(
              subCategory: subCategory,
              skills: state.skills,
              skill: skillItem,
              category: category,
            );
      },
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveValue(
                defaultValue: 10.0,
                context,
                conditionalValues: [
                  Condition.equals(name: MOBILE, value: 15.0),
                  Condition.equals(name: TABLET, value: 20.0),
                  Condition.equals(name: DESKTOP, value: 30.0),
                ],
              ).value ??
              8,
        ),
        child: CircleAvatar(
          radius: ResponsiveValue(
            defaultValue: 50.0,
            context,
            conditionalValues: [
              Condition.equals(name: MOBILE, value: 50.0),
              Condition.equals(name: TABLET, value: 80.0),
              Condition.equals(name: DESKTOP, value: 100.0),
            ],
          ).value,
          backgroundColor:
              HorseAndRidersTheme().getTheme().colorScheme.secondary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                skillItem.skillName as String,
                maxLines: 2,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.background,
                ),
                textAlign: TextAlign.center,
              ),
              Visibility(
                visible: state.isEditState,
                child: IconButton(
                  onPressed: () {
                    showDialog<CreateSkillDialog>(
                      context: context,
                      builder: (context) => CreateSkillDialog(
                        isRider: false,
                        isEdit: true,
                        subCategory: subCategory,
                        userName: usersProfile.name,
                        position: state.skills != null &&
                                state.skills!.isNotEmpty &&
                                state.skills!.contains(skillItem)
                            ? state.skills!.indexOf(skillItem)
                            : 0,
                        skill: skillItem,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    return const Text('No Skills :(');
  }
}

Widget _subCategoryView({
  required BuildContext context,
  required HorseHomeState state,
  required RiderProfile? riderProfile,
  required Catagorry? category,
}) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          // color: COLOR_CONST.BLACK,
        ),
        onPressed: () {
          context.read<HorseHomeCubit>().categorySelected(category: category);
        },
      ),
      title: Text('SubCategories for ${category?.name}'),
      actions: [
        Visibility(
          visible: riderProfile?.editor ?? true,
          child: Switch(
            value: state.isEditState,
            onChanged: (value) {
              context.read<HorseHomeCubit>().toogleSubCategoryEdit(
                    isEdit: value,
                  );
            },
          ),
        ),
      ],
    ),
    body: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: [
                  Icon(
                    HorseAndRiderIcons.horseSkillIcon,
                    size: MediaQuery.of(context).size.width *
                        0.07, // 10% of screen width
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  gap(),
                  Text(
                    'Category: ${category?.name} - SubCategories',
                    style: const TextStyle(
                      // color: COLOR_CONST.WHITE,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _subCategoriesGrid(
            context: context,
            state: state,
            usersProfile: riderProfile as RiderProfile,
          ),
        ],
      ),
    ),
    floatingActionButton: Visibility(
      visible: state.isEditState,
      child: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog<CreateSubCategoryDialog>(
            context: context,
            builder: (context) => CreateSubCategoryDialog(
              skills: state.skills,
              subCategory: null,
              isEdit: false,
              isRider: false,
              category: category,
              userName: riderProfile.name,
              position:
                  state.subCategories != null && state.subCategories!.isNotEmpty
                      ? state.subCategories!.length
                      : 0,
            ),
          );
        },
      ),
    ),
  );
}

Widget _subCategoriesGrid({
  required BuildContext context,
  required HorseHomeState state,
  required RiderProfile usersProfile,
}) {
  final subCategories = state.subCategories;
  final screenWidth = MediaQuery.of(context).size.width;
  final crossAxisCount = screenWidth < 600
      ? 2
      : // For small screens, have 2 items in a row.
      screenWidth < 1000
          ? 3
          : // For medium screens, have 3.
          4; // For large screens, have 4.

// Calculate the size of each item based on screen width and crossAxisCount.
  final itemWidth = screenWidth / crossAxisCount;
  return Center(
    child: GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio:
            itemWidth / 250, // Adjust the item height relative to item width.
        mainAxisSpacing: 10, // Adjust as needed.
        crossAxisSpacing: 10, // Adjust as needed.
      ),
      itemCount: subCategories?.length,
      itemBuilder: (context, index) {
        final subCategoryItem = subCategories?[index];
        return _circleSubCategoryItem(
          usersProfile: usersProfile,
          state: state,
          context: context,
          subCategoryItem: subCategoryItem,
          category: state.category,
        );
      },
    ),
  );
}

Widget _circleSubCategoryItem({
  required BuildContext context,
  SubCategory? subCategoryItem,
  required Catagorry? category,
  required HorseHomeState state,
  required RiderProfile usersProfile,
}) {
  if (subCategoryItem != null) {
    return InkWell(
      onTap: () {
        context.read<HorseHomeCubit>().subCategorySelected(
              subCategory: subCategoryItem,
            );
      },
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveValue(
                defaultValue: 10.0,
                context,
                conditionalValues: [
                  Condition.equals(name: MOBILE, value: 15.0),
                  Condition.equals(name: TABLET, value: 20.0),
                  Condition.equals(name: DESKTOP, value: 30.0),
                ],
              ).value ??
              8,
        ),
        child: CircleAvatar(
          radius: ResponsiveValue(
            defaultValue: 50.0,
            context,
            conditionalValues: [
              Condition.equals(name: MOBILE, value: 50.0),
              Condition.equals(name: TABLET, value: 80.0),
              Condition.equals(name: DESKTOP, value: 100.0),
            ],
          ).value,
          backgroundColor:
              HorseAndRidersTheme().getTheme().colorScheme.secondary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                subCategoryItem.name,
                maxLines: 2,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.background,
                ),
                textAlign: TextAlign.center,
              ),
              Visibility(
                visible: state.isEditState,
                child: IconButton(
                  onPressed: () {
                    showDialog<CreateSubCategoryDialog>(
                      context: context,
                      builder: (context) => CreateSubCategoryDialog(
                        skills: state.skills,
                        subCategory: subCategoryItem,
                        isEdit: true,
                        isRider: false,
                        category: category,
                        userName: usersProfile.name,
                        position: state.subCategories != null &&
                                state.subCategories!.isNotEmpty &&
                                state.subCategories!.contains(subCategoryItem)
                            ? state.subCategories!.indexOf(subCategoryItem)
                            : 0,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    return const Text('No SubCategories :(');
  }
}

Widget _categoryView({
  required HorseHomeState state,
  required BuildContext context,
  required RiderProfile? riderProfile,
}) {
  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
        ),
        onPressed: () {
          context.read<HorseHomeCubit>().horseProfileSelected();
        },
      ),
      actions: [
        Visibility(
          visible: riderProfile?.editor ?? true,
          child: Switch(
            value: state.isEditState,
            onChanged: (value) {
              context.read<HorseHomeCubit>().toggleCategoryEdit(isEdit: value);
            },
          ),
        ),
      ],
      title: const Text('Skill Tree: Categories'),
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    HorseAndRiderIcons.horseSkillIcon,
                    size: MediaQuery.of(context).size.width * 0.07,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  gap(),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      //color: COLOR_CONST.WHITE,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: _baseCategoryListView(
                    context: context,
                    riderProfile: riderProfile,
                    state: state,
                    categories: state.categories,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
    floatingActionButton: Visibility(
      visible: state.isEditState,
      child: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showDialog<CreateCategoryDialog>(
            context: context,
            builder: (context) => CreateCategoryDialog(
              isRider: false,
              isEdit: false,
              userName: riderProfile?.name ?? '',
              position:
                  state.categories!.isNotEmpty ? state.categories!.length : 0,
            ),
          );
        },
      ),
    ),
  );
}

///   List of Base Categories
Widget _baseCategoryListView({
  required BuildContext context,
  required RiderProfile? riderProfile,
  required List<Catagorry?>? categories,
  required HorseHomeState state,
}) {
  if (categories != null && categories.isNotEmpty) {
    categories.sort(
      (a, b) => a!.position.compareTo(b?.position as num),
    );

    return ListView.builder(
      scrollDirection:
          ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET)
              ? Axis.vertical
              : Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _circleCategoryItem(
          riderProfile: riderProfile,
          context: context,
          category: category,
          state: state,
        );
      },
    );
  } else {
    return const Text('No Categories to be had, Try adding one');
  }
}

// Category item that is a circle
Widget _circleCategoryItem({
  required BuildContext context,
  required Catagorry? category,
  required HorseHomeState state,
  required RiderProfile? riderProfile,
}) {
  if (category != null) {
    return InkWell(
      onTap: () {
        context.read<HorseHomeCubit>().categorySelected(category: category);
      },
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveValue(
                defaultValue: 10.0,
                context,
                conditionalValues: [
                  Condition.equals(name: MOBILE, value: 15.0),
                  Condition.equals(name: TABLET, value: 20.0),
                  Condition.equals(name: DESKTOP, value: 30.0),
                ],
              ).value ??
              8,
        ),
        child: CircleAvatar(
          radius: ResponsiveValue(
            defaultValue: 50.0,
            context,
            conditionalValues: [
              Condition.equals(name: MOBILE, value: 50.0),
              Condition.equals(name: TABLET, value: 80.0),
              Condition.equals(name: DESKTOP, value: 100.0),
            ],
          ).value,
          backgroundColor:
              HorseAndRidersTheme().getTheme().colorScheme.secondary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                category.name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.background,
                  fontSize: 20,
                ),
                textAlign: TextAlign.start,
              ),
              Visibility(
                visible: state.isEditState,
                child: IconButton(
                  onPressed: () {
                    showDialog<CreateCategoryDialog>(
                      context: context,
                      builder: (context) => CreateCategoryDialog(
                        isRider: false,
                        isEdit: true,
                        category: category,
                        userName: riderProfile?.name ?? '',
                        position: state.categories!.isNotEmpty
                            ? state.categories!.length
                            : 0,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } else {
    return const Text('No Category to be had here, Try adding one');
  }
}
 */