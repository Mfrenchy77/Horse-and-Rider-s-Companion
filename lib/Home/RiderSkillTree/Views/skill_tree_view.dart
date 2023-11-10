// // ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars, prefer_int_literals

// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:database_repository/database_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:horseandriderscompanion/CommonWidgets/error_page.dart';
// import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
// import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
// import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/category_create_dialog.dart';
// import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/level_create_dialog.dart';
// import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/skill_create_dialog.dart';
// import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/View/sub_category_create_dialog.dart';
// import 'package:horseandriderscompanion/Theme/theme.dart';
// import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
// import 'package:horseandriderscompanion/shared_prefs.dart';
// import 'package:responsive_framework/responsive_framework.dart';

// //FIXME: there has to be a better way to do this with filters instead of calling new views each time
// class SkillTreeView extends StatelessWidget {
//   const SkillTreeView({
//     super.key,
//     required this.state,
//     required this.isViewing,
//     required this.isForRider,
//     required this.usersProfile,
//     required this.viewingProfile,
//   });
//   final bool isViewing;
//   final HomeState state;
//   final bool isForRider;
//   final RiderProfile usersProfile;
//   final RiderProfile? viewingProfile;

//   @override
//   Widget build(BuildContext context) {
//     debugPrint('State is: $state');
//     if (state.skillTreeStatus == SkillTreeStatus.categories) {
//       return _categoryView(
//         state: state,
//         context: context,
//         usersProfile: usersProfile,
//         viewingProfile: viewingProfile,
//       );
//     } else if (state.skillTreeStatus == SkillTreeStatus.subCategories) {
//       debugPrint('SubCategory state for ${state.category?.name}');
//       return _subCategoryView(
//         state: state,
//         context: context,
//         usersProfile: usersProfile,
//         viewingProfile: viewingProfile,
//       );
//     } else if (state.skillTreeStatus == SkillTreeStatus.skill) {
//       debugPrint('Skill Tree state for ${state.subCategory?.name}');
//       return _skillView(
//         state: state,
//         context: context,
//         usersProfile: usersProfile,
//       );
//     } else if (state.skillTreeStatus == SkillTreeStatus.level) {
//       return _levelView(
//         isForRider: isForRider,
//         state: state,
//         context: context,
//         usersProfile: usersProfile,
//         viewingProfile: viewingProfile,
//       );
//     } else {
//       return const Center(
//         child: ErrorPage(),
//       );
//     }
//   }
// }

// Widget _levelView({
//   required bool isForRider,
//   required HomeState state,
//   required BuildContext context,
//   required RiderProfile usersProfile,
//   required RiderProfile? viewingProfile,
// }) {
//   return Scaffold(
//     appBar: AppBar(
//       leading: IconButton(
//         icon: const Icon(
//           Icons.arrow_back,
//           // color: COLOR_CONST.BLACK,
//         ),
//         onPressed: () {
//           context.read<HomeCubit>().categorySelected(category: state.category);
//         },
//       ),
//       title: Text('Levels for ${state.skill?.skillName}'),
//       actions: [
//         Visibility(
//           visible: usersProfile.editor ?? false,
//           child: Switch(
//             value: state.isSkillTreeEdit,
//             onChanged: (value) {
//               context.read<HomeCubit>().toggleLevelsEdit(
//                     levels: state.levels,
//                     skill: state.skill,
//                     isEdit: value,
//                     category: state.category,
//                     skills: state.skills,
//                   );
//             },
//           ),
//         ),
//       ],
//     ),
//     body: SingleChildScrollView(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     HorseAndRiderIcons.riderSkillIcon,
//                     size: MediaQuery.of(context).size.width *
//                         0.07, // 10% of screen width
//                     color: Theme.of(context).textTheme.bodyLarge?.color,
//                   ),
//                   gap(),
//                   Text(
//                     'Category: ${state.category?.name} - Skill: ${state.skill?.skillName} - Levels',
//                     style: const TextStyle(
//                         // color: COLOR_CONST.WHITE,
//                         // fontSize: 16,
//                         ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           _levelsList(
//             state: state,
//             usersProfile: usersProfile,
//             viewingProfile: viewingProfile,
//           ),
//         ],
//       ),
//     ),
//     floatingActionButton: Visibility(
//       visible: state.isSkillTreeEdit,
//       child: FloatingActionButton(
//         child: const Icon(Icons.add),
//         onPressed: () {
//           showDialog<CreateLevelDialog>(
//             context: context,
//             builder: (context) => CreateLevelDialog(
//               isEdit: false,
//               isForRider: isForRider,
//               skill: state.skill,
//               userName: usersProfile.name,
//               position: state.levels != null && state.levels!.isNotEmpty
//                   ? state.levels!.length
//                   : 0,
//             ),
//           );
//         },
//       ),
//     ),
//   );
// }

// Widget _levelsList({
//   required HomeState state,
//   required RiderProfile usersProfile,
//   required RiderProfile? viewingProfile,
// }) {
//   final levels = state.levels;
//   if (levels != null && levels.isNotEmpty) {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       itemCount: levels.length,
//       itemBuilder: (context, index) {
//         final level = levels[index];
//         return _levelItem(
//           usersProfile: usersProfile,
//           viewingProfile: viewingProfile,
//           context: context,
//           level: level,
//           state: state,
//         );
//       },
//     );
//   } else {
//     return const Center(
//       child: Text('No Levels, add some'),
//     );
//   }
// }

// Widget _levelItem({
//   required BuildContext context,
//   required Level? level,
//   required HomeState state,
//   required RiderProfile usersProfile,
//   required RiderProfile? viewingProfile,
// }) {
//   var isHidden = true;
//   final isDark = SharedPrefs().isDarkMode;

//   return level != null
//       ? InkWell(
//           // onTap: () {
//           //   context.read<HomeCubit>().levelSelected(level);
//           // },
//           child: Card(
//             //color: COLOR_CONST.DEFAULT,
//             elevation: 8,
//             margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//             child: Padding(
//               padding: const EdgeInsets.all(4),
//               child: IntrinsicWidth(
//                 child: StatefulBuilder(
//                   builder: (context, setState) => Column(
//                     children: [
//                       _skillLevelView(
//                         usersProfile: usersProfile,
//                         viewingProfile: viewingProfile,
//                         level: level,
//                         context: context,
//                         state: state,
//                       ),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Expanded(
//                             flex: 4,
//                             child: IconButton(
//                               alignment: Alignment.centerLeft,
//                               onPressed: () => setState(
//                                 () => isHidden = !isHidden,
//                               ),
//                               icon: Icon(
//                                 isHidden
//                                     ? Icons.chevron_right
//                                     : Icons.keyboard_arrow_down,
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             flex: 8,
//                             child: Text(
//                               level.levelName as String,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 20,
//                               ),
//                               textAlign: TextAlign.start,
//                             ),
//                           ),
//                           Visibility(
//                             visible: state.isSkillTreeEdit,
//                             child: IconButton(
//                               onPressed: () {
//                                 showDialog<CreateLevelDialog>(
//                                   context: context,
//                                   builder: (context) => CreateLevelDialog(
//                                     skill: state.skill,
//                                     isForRider: true,
//                                     level: level,
//                                     isEdit: true,
//                                     userName: state.usersProfile?.name,
//                                     position: state.categories!.isNotEmpty
//                                         ? state.categories!.length
//                                         : 0,
//                                   ),
//                                 );
//                               },
//                               icon: const Icon(Icons.edit),
//                             ),
//                           ),
//                         ],
//                       ),
//                       Divider(
//                         color: isDark ? Colors.white : Colors.black,
//                       ),
//                       smallGap(),
//                       Visibility(
//                         visible: !isHidden,
//                         child: Column(
//                           children: [
//                             Text(
//                               '${level.description}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                             gap(),
//                             const Text(
//                               'Learning Description:',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               '${level.learningDescription}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                             gap(),
//                             const Text(
//                               'Complete Description:',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               '${level.completeDescription}',
//                               style: const TextStyle(fontSize: 14),
//                             ),
//                           ],
//                         ),
//                       ),
//                       smallGap(),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         )
//       : const Text('No Level :( ');
// }

// Widget _skillLevelView({
//   required Level level,
//   required BuildContext context,
//   required HomeState state,
//   required RiderProfile usersProfile,
//   required RiderProfile? viewingProfile,
// }) {
//   return Row(
//     // each child need to strech to fill the row
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       Padding(
//         padding: const EdgeInsets.all(8),
//         child: Icon(
//           Icons.check_circle_outline,
//           color: context.read<HomeCubit>().isVerified(
//                 riderProfile: viewingProfile ?? usersProfile,
//                 level: level,
//               ),
//         ),
//       ),
//       InkWell(
//         onTap: () {
//           debugPrint('no progress: ${level.levelName}');
//           context.read<HomeCubit>().levelSelected(
//                 usersProfile: usersProfile,
//                 viewingProfile: viewingProfile,
//                 level: level,
//                 levelState: LevelState.NO_PROGRESS,
//               );
//         },
//         child: state.levelSubmitionStatus == LevelSubmitionStatus.submitting
//             ? const CircularProgressIndicator()
//             : SizedBox(
//                 height: 50,
//                 width: 100,
//                 child: ColoredBox(
//                   color: context.read<HomeCubit>().isLevelUnlocked(
//                         riderProfile: viewingProfile ?? usersProfile,
//                         level: level,
//                         levelState: LevelState.NO_PROGRESS,
//                       ),
//                   child: const Center(child: Text('No Progress')),
//                 ),
//               ),
//       ),
//       InkWell(
//         onTap: () {
//           context.read<HomeCubit>().levelSelected(
//                 usersProfile: usersProfile,
//                 viewingProfile: viewingProfile,
//                 level: level,
//                 levelState: LevelState.LEARNING,
//               );
//           debugPrint('learning: ${level.levelName}');
//         },
//         child: state.levelSubmitionStatus == LevelSubmitionStatus.submitting
//             ? const CircularProgressIndicator()
//             : SizedBox(
//                 height: 50,
//                 width: 100,
//                 child: ColoredBox(
//                   color: context.read<HomeCubit>().isLevelUnlocked(
//                         riderProfile: viewingProfile ?? usersProfile,
//                         level: level,
//                         levelState: LevelState.LEARNING,
//                       ),
//                   child: const Center(child: Text('Learning')),
//                 ),
//               ),
//       ),
//       InkWell(
//         onTap: () {
//           context.read<HomeCubit>().levelSelected(
//                 usersProfile: usersProfile,
//                 viewingProfile: viewingProfile,
//                 level: level,
//                 levelState: LevelState.COMPLETE,
//               );
//           debugPrint('complete: ${level.levelName}');
//         },
//         child: state.levelSubmitionStatus == LevelSubmitionStatus.submitting
//             ? const CircularProgressIndicator()
//             : SizedBox(
//                 height: 50,
//                 width: 100,
//                 child: ColoredBox(
//                   color: context.read<HomeCubit>().isLevelUnlocked(
//                         riderProfile: usersProfile,
//                         level: level,
//                         levelState: LevelState.COMPLETE,
//                       ),
//                   child: const Center(child: Text('Complete')),
//                 ),
//               ),
//       ),
//       Padding(
//         padding: const EdgeInsets.all(8),
//         child: Icon(
//           Icons.check_circle_outline,
//           color: context
//               .read<HomeCubit>()
//               .isVerified(riderProfile: usersProfile, level: level),
//         ),
//       ),
//     ],
//   );
// }

// Widget _skillView({
//   required HomeState state,
//   required BuildContext context,
//   required RiderProfile usersProfile,
// }) {
//   return Scaffold(
//     appBar: AppBar(
//       leading: IconButton(
//         icon: const Icon(
//           Icons.arrow_back,
//         ),
//         onPressed: () {
//           context.read<HomeCubit>().skillTreeNavigationSelected();
//         },
//       ),
//       title: Text('Skills for ${state.category?.name}'),
//       actions: [
//         Visibility(
//           visible: usersProfile.editor ?? true,
//           child: Switch(
//             value: state.isSkillTreeEdit,
//             onChanged: (value) {
//               context.read<HomeCubit>().toggleSkillsEdit(
//                     isEdit: value,
//                     category: state.category,
//                     skills: state.skills,
//                   );
//             },
//           ),
//         ),
//       ],
//     ),
//     body: SingleChildScrollView(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     HorseAndRiderIcons.riderSkillIcon,
//                     size: MediaQuery.of(context).size.width *
//                         0.07, // 10% of screen width
//                     color: Theme.of(context).textTheme.bodyLarge?.color,
//                   ),
//                   gap(),
//                   Text(
//                     'Category: ${state.category?.name} - Skills',
//                     style: const TextStyle(
//                       // color: COLOR_CONST.WHITE,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           _skillsGrid(
//             context: context,
//             state: state,
//             usersProfile: usersProfile,
//           ),
//         ],
//       ),
//     ),
//     floatingActionButton: Visibility(
//       visible: state.isSkillTreeEdit,
//       child: FloatingActionButton(
//         child: const Icon(Icons.add),
//         onPressed: () {
// //we want to have the option of creating a skill for the selected
// //category or a subcategory

//           showDialog<CreateSkillDialog>(
//             context: context,
//             builder: (context) => CreateSkillDialog(
//               isRider: true,
//               isEdit: false,
//               subCategory: state.subCategory,
//               userName: usersProfile.name,
//               position: state.skills != null && state.skills!.isNotEmpty
//                   ? state.skills!.length
//                   : 0,
//             ),
//           );
//         },
//       ),
//     ),
//   );
// }

// // a widget that contains a grid of skills and subcategories
// // that resises based on the screen size and grid size
// Widget _skillsGrid({
//   required BuildContext context,
//   required HomeState state,
//   required RiderProfile usersProfile,
// }) {
//   final skills = state.skills;
//   final screenWidth = MediaQuery.of(context).size.width;
//   final crossAxisCount = screenWidth < 600
//       ? 2
//       : // For small screens, have 2 items in a row.
//       screenWidth < 1000
//           ? 3
//           : // For medium screens, have 3.
//           4; // For large screens, have 4.

// // Calculate the size of each item based on screen width and crossAxisCount.
//   final itemWidth = screenWidth / crossAxisCount;
//   return Center(
//     child: GridView.builder(
//       shrinkWrap: true,
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: crossAxisCount,
//         childAspectRatio:
//             itemWidth / 250, // Adjust the item height relative to item width.
//         mainAxisSpacing: 10, // Adjust as needed.
//         crossAxisSpacing: 10, // Adjust as needed.
//       ),
//       itemCount: skills?.length,
//       itemBuilder: (context, index) {
//         final skill = skills?[index];
//         return _circleSkillItem(
//           usersProfile: usersProfile,
//           state: state,
//           context: context,
//           skill: skill,
//           category: state.category,
//         );
//       },
//     ),
//   );
// }

// // Category item that is a circle
// Widget _circleSkillItem({
//   required BuildContext context,
//   Skill? skill,
//   required Catagorry? category,
//   required HomeState state,
//   required RiderProfile usersProfile,
// }) {
//   if (skill != null) {
//     return InkWell(
//       onTap: () {
//         context.read<HomeCubit>().skillSelected(
//               subCategory: state.subCategory,
//               skill: skill,
//               category: category,
//             );
//       },
//       child: Padding(
//         padding: EdgeInsets.all(
//           ResponsiveValue(
//                 defaultValue: 10.0,
//                 context,
//                 conditionalValues: [
//                   Condition.equals(name: MOBILE, value: 15.0),
//                   Condition.equals(name: TABLET, value: 20.0),
//                   Condition.equals(name: DESKTOP, value: 30.0),
//                 ],
//               ).value ??
//               8,
//         ),
//         child: CircleAvatar(
//           radius: ResponsiveValue(
//             defaultValue: 50.0,
//             context,
//             conditionalValues: [
//               Condition.equals(name: MOBILE, value: 50.0),
//               Condition.equals(name: TABLET, value: 80.0),
//               Condition.equals(name: DESKTOP, value: 100.0),
//             ],
//           ).value,
//           backgroundColor:
//               HorseAndRidersTheme().getTheme().colorScheme.secondary,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               AutoSizeText(
//                 skill.skillName as String,
//                 maxLines: 2,
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.background,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               Visibility(
//                 visible: state.isSkillTreeEdit,
//                 child: InkWell(
//                   onTap: () {
//                     showDialog<CreateSkillDialog>(
//                       context: context,
//                       builder: (context) => CreateSkillDialog(
//                         subCategory: state.subCategory,
//                         isRider: true,
//                         isEdit: true,
//                         skill: skill,
//                         userName: usersProfile.name,
//                         position:
//                             state.skills != null && state.skills!.isNotEmpty
//                                 ? state.skills!.length
//                                 : 0,
//                       ),
//                     );
//                   },
//                   child: const Icon(
//                     Icons.edit,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   } else {
//     return const Text('No Skills :(');
//   }
// }

// /// SubCategory View
// Widget _subCategoryView({
//   required HomeState state,
//   required BuildContext context,
//   required RiderProfile usersProfile,
//   required RiderProfile? viewingProfile,
// }) {
//   return Scaffold(
//     appBar: AppBar(
//       leading: IconButton(
//         icon: const Icon(
//           Icons.arrow_back,
//         ),
//         onPressed: () {
//           context.read<HomeCubit>().skillTreeNavigationSelected();
//         },
//       ),
//       title: Text('SubCategories for ${state.category?.name}'),
//       actions: [
//         Visibility(
//           visible: usersProfile.editor ?? true,
//           child: Switch(
//             value: state.isSkillTreeEdit,
//             onChanged: (value) {
//               context.read<HomeCubit>().toggleSubCategoryEdit(
//                     isEdit: value,
//                     category: state.category,
//                     subCategories: state.subCategories,
//                   );
//             },
//           ),
//         ),
//       ],
//     ),
//     body: SingleChildScrollView(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     HorseAndRiderIcons.riderSkillIcon,
//                     size: MediaQuery.of(context).size.width *
//                         0.07, // 10% of screen width
//                     color: Theme.of(context).textTheme.bodyLarge?.color,
//                   ),
//                   gap(),
//                   Text(
//                     'Category: ${state.category?.name} - SubCategories',
//                     style: const TextStyle(
//                       // color: COLOR_CONST.WHITE,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           _subCategoriesGrid(
//             context: context,
//             state: state,
//             usersProfile: usersProfile,
//             viewingProfile: viewingProfile,
//           ),
//         ],
//       ),
//     ),
//     floatingActionButton: Visibility(
//       visible: state.isSkillTreeEdit,
//       child: FloatingActionButton(
//         child: const Icon(Icons.add),
//         onPressed: () {
//           showDialog<CreateSubCategoryDialog>(
//             context: context,
//             builder: (dialogContext) => CreateSubCategoryDialog(
//               skillTreeContext: context,
//               skills: null,
//               subCategory: null,
//               isEdit: false,
//               isRider: true,
//               category: state.category,
//               userName: usersProfile.name,
//               position:
//                   state.subCategories != null && state.subCategories!.isNotEmpty
//                       ? state.subCategories!.length
//                       : 0,
//             ),
//           );
//         },
//       ),
//     ),
//   );
// }

// Widget _subCategoriesGrid({
//   required BuildContext context,
//   required HomeState state,
//   required RiderProfile usersProfile,
//   required RiderProfile? viewingProfile,
// }) {
//   final subCategories = state.subCategories;
//   final screenWidth = MediaQuery.of(context).size.width;
//   final crossAxisCount = screenWidth < 600
//       ? 2
//       : // For small screens, have 2 items in a row.
//       screenWidth < 1000
//           ? 3
//           : // For medium screens, have 3.
//           4; // For large screens, have 4.

// // Calculate the size of each item based on screen width and crossAxisCount.
//   final itemWidth = screenWidth / crossAxisCount;
//   return Center(
//     child: state.subCategories != null
//         ? GridView.builder(
//             shrinkWrap: true,
//             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: crossAxisCount,
//               childAspectRatio: itemWidth /
//                   250, // Adjust the item height relative to item width.
//               mainAxisSpacing: 10, // Adjust as needed.
//               crossAxisSpacing: 10, // Adjust as needed.
//             ),
//             itemCount: subCategories?.length,
//             itemBuilder: (context, index) {
//               final subCategory = subCategories?[index];
//               return _circleSubCategoryItem(
//                 usersProfile: usersProfile,
//                 state: state,
//                 context: context,
//                 subCategory: subCategory,
//                 category: state.category,
//               );
//             },
//           )
//         : const Text('No SubCategories :('),
//   );
// }

// /// SubCategory item that is a circle
// Widget _circleSubCategoryItem({
//   required BuildContext context,
//   required SubCategory? subCategory,
//   required Catagorry? category,
//   required HomeState state,
//   required RiderProfile usersProfile,
// }) {
//   if (subCategory != null) {
//     return InkWell(
//       onTap: () {
//         context.read<HomeCubit>().subCategorySelected(
//               subCategory: subCategory,
//               category: category,
//             );
//       },
//       child: Padding(
//         padding: EdgeInsets.all(
//           ResponsiveValue(
//                 defaultValue: 10.0,
//                 context,
//                 conditionalValues: [
//                   Condition.equals(name: MOBILE, value: 15.0),
//                   Condition.equals(name: TABLET, value: 20.0),
//                   Condition.equals(name: DESKTOP, value: 30.0),
//                 ],
//               ).value ??
//               8,
//         ),
//         child: CircleAvatar(
//           radius: ResponsiveValue(
//             defaultValue: 50.0,
//             context,
//             conditionalValues: [
//               Condition.equals(name: MOBILE, value: 50.0),
//               Condition.equals(name: TABLET, value: 80.0),
//               Condition.equals(name: DESKTOP, value: 100.0),
//             ],
//           ).value,
//           backgroundColor:
//               HorseAndRidersTheme().getTheme().colorScheme.secondary,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               AutoSizeText(
//                 subCategory.name,
//                 maxLines: 2,
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.background,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               Visibility(
//                 visible: state.isSkillTreeEdit,
//                 child: InkWell(
//                   onTap: () {
//                     showDialog<CreateSubCategoryDialog>(
//                       context: context,
//                       builder: (context) => CreateSubCategoryDialog(
//                         skillTreeContext: context,
//                         skills: state.skills,
//                         subCategory: subCategory,
//                         isEdit: true,
//                         isRider: true,
//                         category: state.category,
//                         userName: usersProfile.name,
//                         position: subCategory.position,
//                       ),
//                     );
//                   },
//                   child: const Icon(
//                     Icons.edit,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   } else {
//     return const Text('No SubCategories :(');
//   }
// }

// Widget _categoryView({
//   required HomeState state,
//   required BuildContext context,
//   required RiderProfile? viewingProfile,
//   required RiderProfile usersProfile,
// }) {
//   return Scaffold(
//     appBar: AppBar(
//       actions: [
//         Visibility(
//           visible: usersProfile.editor ?? true,
//           child: Switch(
//             value: state.isSkillTreeEdit,
//             onChanged: (value) {
//               context.read<HomeCubit>().toggleCategoryEdit(isEdit: value);
//             },
//           ),
//         ),
//       ],
//       title: const Text('Skill Tree: Categories'),
//     ),
//     body: LayoutBuilder(
//       builder: (context, constraints) {
//         return ConstrainedBox(
//           constraints: BoxConstraints(
//             minHeight: constraints.maxHeight,
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(
//                     HorseAndRiderIcons.riderSkillIcon,
//                     size: MediaQuery.of(context).size.width * 0.07,
//                     color: Theme.of(context).textTheme.bodyLarge?.color,
//                   ),
//                   gap(),
//                   const Text(
//                     'Categories',
//                     style: TextStyle(
//                       //color: COLOR_CONST.WHITE,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ],
//               ),
//               Expanded(
//                 child: Center(
//                   child: _baseCategoryListView(
//                     context: context,
//                     riderProfile: usersProfile,
//                     state: state,
//                     categories: state.categories,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     ),
//     floatingActionButton: Visibility(
//       visible: state.isSkillTreeEdit,
//       child: FloatingActionButton(
//         child: const Icon(Icons.add),
//         onPressed: () {
//           showDialog<CreateCategoryDialog>(
//             context: context,
//             builder: (context) => CreateCategoryDialog(
//               isRider: true,
//               isEdit: false,
//               userName: usersProfile.name as String,
//               position:
//                   state.categories!.isNotEmpty ? state.categories!.length : 0,
//             ),
//           );
//         },
//       ),
//     ),
//   );
// }

// ///   List of Base Categories
// Widget _baseCategoryListView({
//   required BuildContext context,
//   required RiderProfile? riderProfile,
//   required List<Catagorry?>? categories,
//   required HomeState state,
// }) {
// //we want a grid view if the screem is wide enough and a list view if not

//   if (categories != null && categories.isNotEmpty) {
//     categories.sort(
//       (a, b) => a!.position.compareTo(b?.position as num),
//     );

//     return ListView.builder(
//       scrollDirection:
//           ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET)
//               ? Axis.vertical
//               : Axis.horizontal,
//       physics: const NeverScrollableScrollPhysics(),
//       shrinkWrap: true,
//       itemCount: categories.length,
//       itemBuilder: (context, index) {
//         final category = categories[index];
//         return _circleCategoryItem(
//           riderProfile: riderProfile,
//           context: context,
//           category: category,
//           state: state,
//         );
//       },
//     );
//   } else {
//     return const Text('No Categories to be had, Try adding one');
//   }
// }

// // Category item that is a circle
// Widget _circleCategoryItem({
//   required BuildContext context,
//   required Catagorry? category,
//   required HomeState state,
//   required RiderProfile? riderProfile,
// }) {
//   if (category != null) {
//     return InkWell(
//       onTap: () {
//         context.read<HomeCubit>().categorySelected(category: category);
//       },
//       child: Padding(
//         padding: EdgeInsets.all(
//           ResponsiveValue(
//                 defaultValue: 10.0,
//                 context,
//                 conditionalValues: [
//                   Condition.equals(name: MOBILE, value: 15.0),
//                   Condition.equals(name: TABLET, value: 20.0),
//                   Condition.equals(name: DESKTOP, value: 30.0),
//                 ],
//               ).value ??
//               8,
//         ),
//         child: CircleAvatar(
//           radius: ResponsiveValue(
//             defaultValue: 50.0,
//             context,
//             conditionalValues: [
//               Condition.equals(name: MOBILE, value: 50.0),
//               Condition.equals(name: TABLET, value: 80.0),
//               Condition.equals(name: DESKTOP, value: 100.0),
//             ],
//           ).value,
//           backgroundColor:
//               HorseAndRidersTheme().getTheme().colorScheme.secondary,
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               AutoSizeText(
//                 category.name,
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.background,
//                   fontSize: 20,
//                 ),
//                 textAlign: TextAlign.start,
//               ),
//               Visibility(
//                 visible: state.isSkillTreeEdit,
//                 child: InkWell(
//                   onTap: () {
//                     showDialog<CreateCategoryDialog>(
//                       context: context,
//                       builder: (context) => CreateCategoryDialog(
//                         isRider: true,
//                         isEdit: true,
//                         category: category,
//                         userName: riderProfile!.name ?? '',
//                         position: category.position,
//                       ),
//                     );
//                   },
//                   child: const Icon(
//                     Icons.edit,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   } else {
//     return const Text('No Category to be had here, Try adding one');
//   }
// }
