// import 'package:database_repository/database_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
// import 'package:horseandriderscompanion/CommonWidgets/information_dialog.dart';
// import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
// import 'package:horseandriderscompanion/Home/Resources/resource_item.dart';
// import 'package:responsive_framework/max_width_box.dart';

// Widget skillLevel({
//   required HomeCubit homeCubit,
//   required HomeState state,
//   required BuildContext context,
// }) {
//   return state.skill == null
//       ? const Center(
//           child: Text('No Skill Selected'),
//         )
//       : Stack(
//           children: [
//             SingleChildScrollView(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const SizedBox(
//                     height: 50,
//                   ),
//                   Visibility(
//                     visible: state.isGuest,
//                     child: const Text(
//                       'This is where you will be able to track your '
//                       'progress for this skill. There will be information '
//                       'for each skill that explains what is expected for '
//                       '"Learning" and "Proficient"',
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   Text(
//                     state.skill?.skillName ?? '',
//                     style: Theme.of(context).textTheme.headline4,
//                   ),
//                   gap(),
//                   Text(
//                     homeCubit.getLevelProgressDescription(),
//                     textAlign: TextAlign.center,
//                   ),
//                   const Padding(
//                     padding: EdgeInsets.only(left: 20, right: 20),
//                     child: Divider(),
//                   ),
//                   smallGap(),
//                   Text(state.skill?.description ?? ''),
//                   smallGap(),
//                   const Padding(
//                     padding: EdgeInsets.only(left: 20, right: 20),
//                     child: Divider(),
//                   ),
//                   const Text(
//                     'Resources',
//                     style: TextStyle(fontSize: 20),
//                   ),
//                   const Padding(
//                     padding: EdgeInsets.only(left: 20, right: 20),
//                     child: Divider(),
//                   ),
//                   smallGap(),
//                   _skillResourcesList(state: state),
//                   smallGap(),
//                   const SizedBox(
//                     height: 50,
//                   ),
//                 ],
//               ),
//             ),

//             // ProgressBar at the top

//             // hide the progress bar if the
//             Visibility(
//               visible: state.skill != null,
//               child: Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 child: _skillLevelProgressBar(
//                   homeCubit: homeCubit,
//                   state: state,
//                   context: context,
//                 ),
//               ),
//             ),
//           ],
//         );
// }

// /// List of Resources for the selected skill shown in a wrap and resourceItem
// Widget _skillResourcesList({required HomeState state}) {
//   if (state.allResources?.isNotEmpty ?? false) {
//     // Filter the resources based on skillTreeIds containing the skill id
//     final filteredResources = state.allResources!
//         .where(
//           (element) =>
//               element?.skillTreeIds?.contains(state.skill?.id) ?? false,
//         )
//         .toList();

//     // Check if the filtered list is not empty
//     if (filteredResources.isNotEmpty) {
//       return Wrap(
//         alignment: WrapAlignment.center,
//         runSpacing: 4,
//         children: filteredResources
//             .map(
//               (e) => resourceItem(
//                 resource: e!,
//                 isResourceList: false,
//                 usersWhoRated: e.usersWhoRated,
//               ),
//             )
//             .toList(),
//       );
//     } else {
//       return const Text('No Resources Found');
//     }
//   } else {
//     return const Text('No Resources Found');
//   }
// }

// /// This will display the progress bar for the skill level
// Widget _skillLevelProgressBar({
//   required HomeCubit homeCubit,
//   required HomeState state,
//   required BuildContext context,
// }) {
//   debugPrint('Skill for rider: ${state.skill?.rider}');
//   debugPrint('Horse Profile: ${state.horseProfile}');
//   final isConflict = state.horseProfile == null && state.skill?.rider == false;
//   debugPrint('Is Conflict: $isConflict');
//   return MaxWidthBox(
//     maxWidth: 1000,
//     child: Row(
//       children: [
//         // Learning
//         Expanded(
//           child: InkWell(
//             onTap: state.isGuest || isConflict
//                 ? null
//                 : () {
//                     showDialog<AlertDialog>(
//                       context: context,
//                       builder: (context) => _skillLevelSelectedConfirmation(
//                         context: context,
//                         state: state,
//                         homeCubit: homeCubit,
//                         levelState: LevelState.LEARNING,
//                       ),
//                     );
//                   },
//             child: ColoredBox(
//               color: homeCubit.levelColor(
//                 skill: state.skill!,
//                 levelState: LevelState.LEARNING,
//               ),
//               child: Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Row(
//                     children: [
//                       const Expanded(
//                         child: Text(
//                           'Learning',
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                       GestureDetector(
//                         onTapDown: (details) {
//                           InformationDialog.show(
//                             context,
//                             const Text(
//                               'Learning: This stage indicates that the '
//                               'individual should be actively engaged in '
//                               'acquiring the skill. They should be in the '
//                               'process of understanding and practicing the '
//                               'basic concepts and techniques. Mistakes are '
//                               'common at this level, but they provide '
//                               'valuable learning experiences. The '
//                               'individual should be developing their '
//                               'abilities but not yet mastered the skill.',
//                             ),
//                             details.globalPosition,
//                           );
//                         },
//                         child: const Icon(
//                           Icons.info_outline_rounded,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         // Proficient
//         Expanded(
//           child: InkWell(
//             onTap: state.isGuest || isConflict
//                 ? null
//                 : () {
//                     showDialog<AlertDialog>(
//                       context: context,
//                       builder: (context) => _skillLevelSelectedConfirmation(
//                         context: context,
//                         state: state,
//                         homeCubit: homeCubit,
//                         levelState: LevelState.PROFICIENT,
//                       ),
//                     );
//                   },
//             child: ColoredBox(
//               color: homeCubit.levelColor(
//                 skill: state.skill! ,
//                 levelState: LevelState.PROFICIENT,
//               ),
//               child: Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Row(
//                     children: [
//                       const Expanded(
//                         child: Text('Proficient', textAlign: TextAlign.center),
//                       ),
//                       GestureDetector(
//                         onTapDown: (details) {
//                           InformationDialog.show(
//                             context,
//                             const Text(
//                               'Proficient: At this level, the individual '
//                               'should have achieved a significant degree '
//                               'of competence in the skill. They should '
//                               'demonstrate consistent and effective '
//                               'application of the skill in relevant '
//                               'situations. Proficiency implies that the '
//                               'individual can perform the skill '
//                               'independently and reliably, with a good '
//                               'understanding of advanced concepts and '
//                               'techniques.',
//                             ),
//                             details.globalPosition,
//                           );
//                         },
//                         child: const Icon(
//                           Icons.info_outline_rounded,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//         // Resource list
//       ],
//     ),
//   );
// }

// Widget _skillLevelSelectedConfirmation({
//   required HomeCubit homeCubit,
//   required LevelState levelState,
//   required BuildContext context,
//   required HomeState state,
// }) {
//   return AlertDialog(
//     title: const Text('Confirm Skill Level'),
//     content: Text('Are you sure you want to set ${state.skill?.skillName} '
//         'level to ${levelState.name}${!state.isForRider ? ' for '
//             '${state.horseProfile?.name}' : state.isViewing ? ' '
//             'for ${state.viewingProfile?.name}' : ''} ?'),
//     actions: [
//       OutlinedButton(
//         onPressed: () {
//           Navigator.of(context).pop();
//         },
//         child: const Text('No'),
//       ),
//       FilledButton(
//         onPressed: () {
//           homeCubit.levelSelected(
//             levelState: levelState,
//           );
//           Navigator.of(context).pop();
//         },
//         child: const Text('Yes'),
//       ),
//     ],
//   );
// }

// // Widget _addResourceButton({
// //   required HomeState state,
// //   required HomeCubit homeCubit,
// //   required BuildContext context,
// //   required FocusNode skillTreeFocus,
// // }) {
// //   return Padding(
// //     padding: const EdgeInsets.all(8),
// //     child: ElevatedButton(
// //       onPressed: () {
// //         skillTreeFocus.requestFocus();
// //         homeCubit.search(
// //           searchList: state.allResources!.map((e) => e!.name).toList(),
// //         );
// //       },
// //       child: const Text('Add Resource'),
// //     ),
// //   );
// // }

// /// Add a resource Dialog that shows all the resources
// /// and has a search bar that can sort them by name
// /// and a button to add a new resource
// // Widget _addResourceDialog({
// //   required BuildContext context,
// //   required HomeState state,
// //   required HomeCubit homeCubit,
// // }) {
// //   final focus = FocusNode();
// //   return AlertDialog(
// //     title: const Text('Add Resource'),
// //     content: SizedBox(
// //       width: 1000,
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           // Search Bar
// //           SearchField<String>(
// //             inputType: TextInputType.name,
// //             hint: 'Search Resources',
// //             focusNode: focus,
// //             onSearchTextChanged: (query) {
// //               homeCubit.resourceSearchQueryChanged(searchQuery: query);

// //               return state.searchList
// //                       ?.map(
// //                         (e) => SearchFieldListItem<String>(
// //                           e ?? '',
// //                           child: Padding(
// //                             padding: const EdgeInsets.all(4),
// //                             child: Text(e!),
// //                           ),
// //                         ),
// //                       )
// //                       .toList() ??
// //                   [];
// //             },
// //             searchInputDecoration: InputDecoration(
// //               filled: true,
// //               iconColor: HorseAndRidersTheme().getTheme().iconTheme.color,
// //               fillColor:
// //                   HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
// //               prefixIcon: IconButton(
// //                 onPressed: () => Navigator.of(context).pop(),
// //                 icon: const Icon(Icons.arrow_back_ios),
// //               ),
// //               hintText: 'Search Resources',
// //               border: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(40),
// //               ),
// //             ),
// //             suggestions: state.searchList
// //                     ?.map(
// //                       (e) => SearchFieldListItem<String>(
// //                         e ?? '',
// //                         child: Padding(
// //                           padding: const EdgeInsets.all(4),
// //                           child: Text(e!),
// //                         ),
// //                       ),
// //                     )
// //                     .toList() ??
// //                 [],
// //             onSuggestionTap: (value) {
// //               final selectedResource = state.allResources!.firstWhere(
// //                 (resource) => resource?.name == value.searchKey,
// //               )!;
// //               debugPrint('Suggestion Tap Value: ${value.searchKey}');
// //               if (state.skill != null) {
// //                 homeCubit.addResourceToSkill(
// //                   skill: state.skill,
// //                   resource: selectedResource,
// //                 );
// //               }
// //             },
// //             textInputAction: TextInputAction.search,
// //             textCapitalization: TextCapitalization.words,
// //             onSubmit: (p0) {
// //               debugPrint('Submit Value: $p0');
// //             },
// //           ),
// //           // Resource List
// //           Wrap(
// //             children: state.searchList
// //                     ?.map(
// //                       (e) => InkWell(
// //                         onTap: () => homeCubit.addResourceToSkill(
// //                           skill: state.skill,
// //                           resource: state.allResources!.firstWhere(
// //                             (resource) => resource?.name == e,
// //                           ),
// //                         ),
// //                         child: ListTile(
// //                           title: Text(e!),
// //                         ),
// //                       ),
// //                     )
// //                     .toList() ??
// //                 [const Text('No Resources Found')],
// //           ),
// //         ],
// //       ),
// //     ),
// //     actions: [
// //       TextButton(
// //         onPressed: () {
// //           Navigator.of(context).pop();
// //         },
// //         child: const Text('Cancel'),
// //       ),
// //     ],
// //   );
// // }
