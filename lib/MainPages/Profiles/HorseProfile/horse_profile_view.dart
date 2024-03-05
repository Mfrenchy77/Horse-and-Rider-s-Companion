// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_search_button.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_skills_banner.dart';
import 'package:horseandriderscompanion/CommonWidgets/skills_text_button.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/primary_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/back_button.dart';

class HorseProfileView extends StatelessWidget {
  const HorseProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const ProfileBackButton(
          key: Key('backButton'),
        ),
        actions: const [
          ProfileSearchButton(
            key: Key('HorseSearchButton'),
          ),
          HorseProfileOverFlowMenu(
            key: Key('RiderProfileOverFlowMenu'),
          ),
        ],
        title: const AppTitle(
          key: Key('appTitle'),
        ),
      ),
      body: AdaptiveLayout(
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.large: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => const SingleChildScrollView(
                child: HorseProfilePrimaryView(
                  key: Key('HorseProfilePrimaryView'),
                ),
              ),
            ),
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => ListView(
                children: [
                  const HorseProfilePrimaryView(
                    key: Key('HorseProfilePrimaryView'),
                  ),
                  gap(),
                  const SkillsTextButton(
                    key: Key('SkillsTextButton'),
                  ),
                  gap(),
                  const ProfileSkills(
                    key: Key('ProfileSkills'),
                  ),
                ],
              ),
            ),
            Breakpoints.small: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => ListView(
                children: [
                  const HorseProfilePrimaryView(
                    key: Key('HorseProfilePrimaryView'),
                  ),
                  gap(),
                  const SkillsTextButton(
                    key: Key('SkillsTextButton'),
                  ),
                  gap(),
                  const ProfileSkills(
                    key: Key('ProfileSkills'),
                  ),
                ],
              ),
            ),
          },
        ),
        secondaryBody: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.large: SlotLayout.from(
              key: const Key('secondary'),
              builder: (context) => ListView(
                children: [
                  const ProfileSkillsBanner(
                    key: Key('ProfileSkillsBanner'),
                  ),
                  gap(),
                  const ProfileSkills(
                    key: Key('ProfileSkills'),
                  ),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }
}

// Widget horseProfileView() {
//   return Scaffold(
//     appBar: AppBar(
//       leading: const ProfileBackButton(
//         key: Key('backButton'),
//       ),
//       actions: const [
//         ProfileSearchButton(
//           key: Key('HorseSearchButton'),
//         ),
//         HorseProfileOverFlowMenu(
//           key: Key('RiderProfileOverFlowMenu'),
//         ),
//       ],
//       title: const AppTitle(
//         key: Key('appTitle'),
//       ),
//     ),
//     body: AdaptiveLayout(
//       body: SlotLayout(
//         config: <Breakpoint, SlotLayoutConfig>{
//           Breakpoints.large: SlotLayout.from(
//             key: const Key('primary'),
//             builder: (context) => const SingleChildScrollView(
//               child: HorseProfilePrimaryView(
//                 key: Key('HorseProfilePrimaryView'),
//               ),
//             ),
//           ),
//           Breakpoints.medium: SlotLayout.from(
//             key: const Key('primary'),
//             builder: (context) => ListView(
//               children: [
//                 const HorseProfilePrimaryView(
//                   key: Key('HorseProfilePrimaryView'),
//                 ),
//                 gap(),
//                 const SkillsTextButton(
//                   key: Key('SkillsTextButton'),
//                 ),
//                 gap(),
//                 const ProfileSkills(
//                   key: Key('ProfileSkills'),
//                 ),
//               ],
//             ),
//           ),
//           Breakpoints.small: SlotLayout.from(
//             key: const Key('primary'),
//             builder: (context) => ListView(
//               children: [
//                 const HorseProfilePrimaryView(
//                   key: Key('HorseProfilePrimaryView'),
//                 ),
//                 gap(),
//                 const SkillsTextButton(
//                   key: Key('SkillsTextButton'),
//                 ),
//                 gap(),
//                 const ProfileSkills(
//                   key: Key('ProfileSkills'),
//                 ),
//               ],
//             ),
//           ),
//         },
//       ),
//       secondaryBody: SlotLayout(
//         config: <Breakpoint, SlotLayoutConfig>{
//           Breakpoints.large: SlotLayout.from(
//             key: const Key('secondary'),
//             builder: (context) => ListView(
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ColoredBox(
//                         color: HorseAndRidersTheme()
//                                 .getTheme()
//                                 .appBarTheme
//                                 .backgroundColor ??
//                             Colors.white,
//                         child: const Padding(
//                           padding: EdgeInsets.all(8),
//                           child: Text(
//                             'Skills',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               fontWeight: FontWeight.w200,
//                               fontSize: 30,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 gap(),
//                 const ProfileSkills(
//                   key: Key('ProfileSkills'),
//                 ),
//               ],
//             ),
//           ),
//         },
//       ),
//     ),
//   );
// }

// Widget _primaryView({
//   required BuildContext context,
//   required HomeCubit homeCubit,
//   required HomeState state,
// }) {
//   final horseProfile = state.horseProfile;
//   return Column(
//     children: [
//       Row(
//         children: [
//           Expanded(
//             child: ColoredBox(
//               color: HorseAndRidersTheme()
//                       .getTheme()
//                       .appBarTheme
//                       .backgroundColor ??
//                   Colors.white,
//               child: Column(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.all(8),
//                     child: Container(
//                       padding: const EdgeInsets.all(2),
//                       decoration: const ShapeDecoration(
//                         shape: CircleBorder(),
//                         color: Colors.white,
//                       ),
//                       child: ProfilePhoto(
//                         size: 100,
//                         profilePicUrl: state.horseProfile?.picUrl,
//                       ),
//                     ),
//                   ),
//                   Text(
//                     '${state.horseProfile?.name}',
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w200,
//                       fontSize: 30,
//                       fontStyle: FontStyle.italic,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       Padding(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           children: [
//             _currentOwner(horseProfile: horseProfile, context: context),
//             smallGap(),
//             _horseNickName(horseProfile: horseProfile),
//             smallGap(),
//             _horseLocation(horseProfile: horseProfile),
//             smallGap(),
//             _horseAge(horseProfile: horseProfile),
//             smallGap(),
//             _horseColor(horseProfile: horseProfile),
//             smallGap(),
//             _horseBreed(horseProfile: horseProfile),
//             smallGap(),
//             _horseGender(horseProfile: horseProfile),
//             smallGap(),
//             _horseHeight(horseProfile: horseProfile),
//             smallGap(),
//             _horseDateOfBirth(horseProfile: horseProfile),
//             smallGap(),
//             Visibility(
//               visible: !state.isOwner,
//               child: _requestToBeStudentHorseButton(
//                 context: context,
//                 horseProfile: state.horseProfile!,
//                 isOwner: state.isOwner,
//               ),
//             ),
//             Visibility(
//               visible: state.isOwner,
//               child: _logBookButton(
//                 context: context,
//                 state: state,
//                 homeCubit: homeCubit,
//               ),
//             ),
//           ],
//         ),
//       ),
//     ],
//   );
// }

// Widget _skillsView({
//   required BuildContext context,
//   required HomeCubit homeCubit,
//   required HomeState state,
// }) {
//   if (state.isGuest) {
//     return Column(
//       children: [
//         const Center(
//           child: Text(
//             "This is where your hores's skills will be displayed",
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 18,
//             ),
//           ),
//         ),
//         gap(),
//         Wrap(
//           children: [
//             ...ExampleSkill().getSkillLevels().map(
//                   (e) => SkillLevelCard(skillLevel: e),
//                 ),
//           ],
//         ),
//       ],
//     );
//   } else {
//     return Wrap(
//       spacing: 50,
//       runSpacing: 5,
//       alignment: WrapAlignment.center,
//       children: [
//         ...state.horseProfile?.skillLevels
//                 ?.map(
//                   (e) => SkillLevelCard(skillLevel: e),
//                 )
//                 .toList() ??
//             [const Text('No Skills')],
//       ],
//     );
//   }
// }

// List<Widget> _appBarActions({
//   required bool isOwner,
//   required BuildContext context,
//   required HomeState state,
//   required HomeCubit homeCubit,
// }) {
//   debugPrint('isOwner: $isOwner');
//   return [
//     //Menu
//     Visibility(
//       visible: isOwner,
//       child: PopupMenuButton<String>(
//         itemBuilder: (BuildContext menuContext) => <PopupMenuEntry<String>>[
//           const PopupMenuItem(value: 'Edit', child: Text('Edit')),
//           const PopupMenuItem(value: 'Delete', child: Text('Delete')),
//           const PopupMenuItem(value: 'Transfer', child: Text('Transfer')),
//         ],
//         onSelected: (value) {
//           switch (value) {
//             case 'Edit':
//               homeCubit.openAddHorseDialog(
//                 isEdit: true,
//                 context: context,
//                 horseProfile: state.horseProfile,
//               );
//               break;
//             case 'Transfer':
//               homeCubit.transferHorseProfile();
//               break;
//             case 'Delete':
//               homeCubit.deleteHorseProfileFromUser();
//               break;
//           }
//         },
//       ),
//     ),
//   ];
// }

// Widget _currentOwner({
//   required HorseProfile? horseProfile,
//   required BuildContext context,
// }) {
//   return Row(
//     children: [
//       const Expanded(
//         flex: 5,
//         child: Text('Current Owner: '),
//       ),
//       Expanded(
//         flex: 5,
//         child: InkWell(
//           onTap: horseProfile == null
//               ? null
//               : () => context.read<HomeCubit>().gotoProfilePage(
//                     context: context,
//                     toBeViewedEmail: horseProfile.currentOwnerId,
//                   ),
//           child: Text(
//             horseProfile?.currentOwnerName ?? '',
//             textAlign: TextAlign.start,
//             style: const TextStyle(
//               fontSize: 18,
//               color: Colors.blue,
//               decoration: TextDecoration.underline,
//             ),
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _logBookButton({
//   required BuildContext context,
//   required HomeState state,
//   required HomeCubit homeCubit,
// }) {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       Tooltip(
//         message: 'Open the Log Book',
//         child: FilledButton.icon(
//           onPressed: () {
//             showDialog<AlertDialog>(
//               context: context,
//               builder: (context) => LogV(
//                 context: context,
//                 name: state.horseProfile?.name ?? state.usersProfile!.name,
//                 notes: state.horseProfile?.notes ?? state.usersProfile!.notes,
//                 isRider: false,
//               ),
//             );
//           },
//           icon: const Icon(
//             HorseAndRiderIcons.horseLogIcon,
//           ),
//           label: const Text('Log Book'),
//         ),
//       ),
//       Tooltip(
//         message: 'Add an Entry into the Log',
//         child: IconButton(
//           onPressed: () {
//             showDialog<AddLogEntryDialog>(
//               context: context,
//               builder: (context) => AddLogEntryDialog(
//                 riderProfile: state.viewingProfile ?? state.usersProfile!,
//                 horseProfile: state.horseProfile,
//               ),
//             );
//           },
//           icon: const Icon(
//             Icons.add,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _horseBreed({required HorseProfile? horseProfile}) {
//   return Row(
//     children: [
//       const Expanded(
//         flex: 5,
//         child: Text('Breed: '),
//       ),
//       Expanded(
//         flex: 5,
//         child: Text(
//           '${horseProfile?.breed}',
//           textAlign: TextAlign.start,
//           style: const TextStyle(
//             fontSize: 18,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _horseColor({required HorseProfile? horseProfile}) {
//   return Row(
//     children: [
//       const Expanded(
//         flex: 5,
//         child: Text('Color: '),
//       ),
//       Expanded(
//         flex: 5,
//         child: Text(
//           '${horseProfile?.color}',
//           textAlign: TextAlign.start,
//           style: const TextStyle(
//             fontSize: 18,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _horseGender({required HorseProfile? horseProfile}) {
//   return Row(
//     children: [
//       const Expanded(
//         flex: 5,
//         child: Text('Gender: '),
//       ),
//       Expanded(
//         flex: 5,
//         child: Text(
//           '${horseProfile?.gender}',
//           textAlign: TextAlign.start,
//           style: const TextStyle(
//             fontSize: 18,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _horseDateOfBirth({required HorseProfile? horseProfile}) {
//   return Row(
//     children: [
//       const Expanded(
//         flex: 5,
//         child: Text('Date of Birth: '),
//       ),
//       Expanded(
//         flex: 5,
//         child: Text(
//           DateFormat('MMMM d yyyy').format(
//             horseProfile?.dateOfBirth ?? DateTime.now(),
//           ),
//           textAlign: TextAlign.start,
//           style: const TextStyle(
//             fontSize: 18,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _horseAge({required HorseProfile? horseProfile}) {
//   final today = DateTime.now().year;
//   final dob = horseProfile?.dateOfBirth?.year ?? today;
//   final age = today - dob;
//   return Row(
//     children: [
//       const Expanded(
//         flex: 5,
//         child: Text('Age: '),
//       ),
//       Expanded(
//         flex: 5,
//         child: Text(
//           '$age',
//           textAlign: TextAlign.start,
//           style: const TextStyle(
//             fontSize: 18,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _horseLocation({required HorseProfile? horseProfile}) {
//   return Row(
//     children: [
//       const Expanded(
//         flex: 5,
//         child: Text('Location: '),
//       ),
//       Expanded(
//         flex: 5,
//         child: Text(
//           horseProfile?.locationName ?? 'No Location Specified',
//           textAlign: TextAlign.start,
//           style: const TextStyle(
//             fontSize: 18,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _horseNickName({required HorseProfile? horseProfile}) {
//   return Row(
//     children: [
//       const Expanded(
//         flex: 5,
//         child: Text('NickName: '),
//       ),
//       Expanded(
//         flex: 5,
//         child: Text(
//           '${horseProfile?.nickname}',
//           textAlign: TextAlign.start,
//           style: const TextStyle(
//             fontSize: 18,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// Widget _horseHeight({required HorseProfile? horseProfile}) {
//   return Row(
//     children: [
//       const Expanded(
//         flex: 5,
//         child: Text('Height: '),
//       ),
//       Expanded(
//         flex: 5,
//         child: Text(
//           '${horseProfile?.height}',
//           textAlign: TextAlign.start,
//           style: const TextStyle(
//             fontSize: 18,
//           ),
//         ),
//       ),
//     ],
//   );
// }

// // Widget that allows the user if the horse is
// // notOwned to request to be studenthorse from the owner
// Widget _requestToBeStudentHorseButton({
//   required BuildContext context,
//   required HorseProfile horseProfile,
//   required bool isOwner,
// }) {
//   final isStudentHorse =
//       context.read<HomeCubit>().isStudentHorse(horseProfile: horseProfile);
//   return Visibility(
//     visible: !isOwner,
//     child: ElevatedButton(
//       onPressed: () {
//         context.read<HomeCubit>().requestToBeStudentHorse(
//               isStudentHorse: isStudentHorse,
//               context: context,
//               horseProfile: horseProfile,
//             );
//       },
//       child: Text(
//         isStudentHorse
//             ? 'Remove Horse as Student'
//             : 'Request to be Student Horse',
//       ),
//     ),
//   );
// }
