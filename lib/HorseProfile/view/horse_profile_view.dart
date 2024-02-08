// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/example_skill.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_level_card.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/HorseProfile/view/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:intl/intl.dart';

Widget horseProfileView({
  required BuildContext context,
  required HomeState state,
  required HomeCubit homeCubit,
}) {
  debugPrint('Horse Profile: ${state.horseProfile?.name}');
  if (state.horseProfile != null) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: homeCubit.goBackToUsersProfile,
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
        actions: _appBarActions(
          isOwner: state.isOwner,
          context: context,
          state: state,
          homeCubit: homeCubit,
        ),
        title: appBarTitle(),
      ),
      body: AdaptiveLayout(
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.large: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => _primaryView(
                context: context,
                homeCubit: homeCubit,
                state: state,
              ),
            ),
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => ListView(
                children: [
                  _primaryView(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                  ),
                  const Text(
                    'Skills',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  gap(),
                  _skillsView(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                  ),
                ],
              ),
            ),
            Breakpoints.small: SlotLayout.from(
              key: const Key('primary'),
              builder: (context) => ListView(
                children: [
                  _primaryView(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                  ),
                  const Text(
                    'Skills',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  gap(),
                  _skillsView(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
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
                  Row(
                    children: [
                      Expanded(
                        child: ColoredBox(
                          color: HorseAndRidersTheme()
                                  .getTheme()
                                  .appBarTheme
                                  .backgroundColor ??
                              Colors.white,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Skills',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w200,
                                fontSize: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  gap(),
                  _skillsView(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                  ),
                ],
              ),
            ),
          },
        ),
      ),
      // body: SingleChildScrollView(
      //   child: Padding(
      //     padding: const EdgeInsets.all(8),
      //     child: Center(
      //       child: Column(
      //         children: [
      //           _horsePhoto(horseProfile: state.horseProfile),
      //           smallGap(),
      //           _currentOwner(
      //             horseProfile: state.horseProfile,
      //             context: context,
      //           ),
      //           smallGap(),
      //           _horseNickName(horseProfile: state.horseProfile),
      //           smallGap(),
      //           _horseLocation(horseProfile: state.horseProfile),
      //           smallGap(),
      //           _horseAge(horseProfile: state.horseProfile),
      //           smallGap(),
      //           _horseColor(horseProfile: state.horseProfile),
      //           smallGap(),
      //           _horseBreed(horseProfile: state.horseProfile),
      //           smallGap(),
      //           _horseGender(horseProfile: state.horseProfile),
      //           smallGap(),
      //           _horseHeight(horseProfile: state.horseProfile),
      //           smallGap(),
      //           _horseDateOfBirth(horseProfile: state.horseProfile),
      //           smallGap(),
      //           Visibility(
      //             visible: !state.isOwner,
      //             child: _requestToBeStudentHorseButton(
      //               context: context,
      //               horseProfile: state.horseProfile!,
      //               isOwner: state.isOwner,
      //             ),
      //           ),
      //           // Text("${horseProfile.name}'s Log Book"),
      //           // Divider(
      //           //   color: isDark ? Colors.white : Colors.black,
      //           //   indent: 20,
      //           //   endIndent: 20,
      //           // ),
      //           // _addLogEntryButton(
      //           //   context: context,
      //           //   horseProfile: horseProfile,
      //           //   riderProfile: usersProfile as RiderProfile,
      //           // ),
      //           // gap(),
      //           // _notes(horseProfile: horseProfile)
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
    );
  } else {
    debugPrint('Horse Profile is null, trying to load');
    if (state.horseId != null) {
      homeCubit.horseProfileSelected(id: state.horseId!);
    } else {
      debugPrint('Horse Id is null');
    }
    return const Center(
      child: Logo(
        screenName: 'Loading...',
      ),
    );
  }
}

Widget _primaryView({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  final horseProfile = state.horseProfile;
  return ListView(
    shrinkWrap: true,
    children: [
      Row(
        children: [
          Expanded(
            child: ColoredBox(
              color: HorseAndRidersTheme()
                      .getTheme()
                      .appBarTheme
                      .backgroundColor ??
                  Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const ShapeDecoration(
                        shape: CircleBorder(),
                        color: Colors.white,
                      ),
                      child: profilePhoto(
                        context: context,
                        size: 100,
                        profilePicUrl: state.horseProfile?.picUrl,
                      ),
                    ),
                  ),
                  Text(
                    '${state.horseProfile?.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w200,
                      fontSize: 30,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _currentOwner(horseProfile: horseProfile, context: context),
            smallGap(),
            _horseNickName(horseProfile: horseProfile),
            smallGap(),
            _horseLocation(horseProfile: horseProfile),
            smallGap(),
            _horseAge(horseProfile: horseProfile),
            smallGap(),
            _horseColor(horseProfile: horseProfile),
            smallGap(),
            _horseBreed(horseProfile: horseProfile),
            smallGap(),
            _horseGender(horseProfile: horseProfile),
            smallGap(),
            _horseHeight(horseProfile: horseProfile),
            smallGap(),
            _horseDateOfBirth(horseProfile: horseProfile),
            smallGap(),
            Visibility(
              visible: !state.isOwner,
              child: _requestToBeStudentHorseButton(
                context: context,
                horseProfile: state.horseProfile!,
                isOwner: state.isOwner,
              ),
            ),
            Visibility(
                visible: state.isOwner,
                child: _logBookButton(context: context)),
          ],
        ),
      ),
    ],
  );
}

Widget _skillsView({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  if (state.isGuest) {
    return Column(
      children: [
        const Center(
          child: Text(
            "This is where your hores's skills will be displayed",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),
        gap(),
        Wrap(
          children: [
            ...ExampleSkill().getSkillLevels().map(
                  (e) => skillLevelCard(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                    skillLevel: e,
                  ),
                ),
          ],
        ),
      ],
    );
  } else {
    return Wrap(
      spacing: 50,
      runSpacing: 5,
      alignment: WrapAlignment.center,
      children: [
        ...state.horseProfile?.skillLevels
                ?.map(
                  (e) => skillLevelCard(
                    context: context,
                    homeCubit: homeCubit,
                    state: state,
                    skillLevel: e,
                  ),
                )
                .toList() ??
            [const Text('No Skills')],
      ],
    );
  }
}

List<Widget> _appBarActions({
  required bool isOwner,
  required BuildContext context,
  required HomeState state,
  required HomeCubit homeCubit,
}) {
  debugPrint('isOwner: $isOwner');
  return [
    // Row(
    //   children: [
    //     Tooltip(
    //       message: 'Horse Log Book',
    //       child: IconButton(
    //         onPressed: () {
    //           homeCubit.logNavigationSelected();
    //         },
    //         icon: const Icon(
    //           HorseAndRiderIcons.horseLogIcon,
    //         ),
    //       ),
    //     ),
    //     Visibility(
    //       visible: isOwner,
    //       child: Tooltip(
    //         message: 'Edit Horse Profile',
    //         child: IconButton(
    //           onPressed: () {
    //             homeCubit.openAddHorseDialog(
    //               context: context,
    //               isEdit: true,
    //               horseProfile: state.horseProfile,
    //             );
    //           },
    //           icon: const Icon(
    //             Icons.edit,
    //           ),
    //         ),
    //       ),
    //     ),
    //     Visibility(
    //       visible: isOwner,
    //       child: Tooltip(
    //         message: 'Transfer Horse Profile',
    //         child: IconButton(
    //           onPressed: () {
    //             homeCubit.transferHorseProfile();
    //           },
    //           icon: const Icon(
    //             Icons.transfer_within_a_station,
    //           ),
    //         ),
    //       ),
    //     ),
    //     Visibility(
    //       visible: isOwner,
    //       child: Tooltip(
    //         message: 'Delete Horse Profile',
    //         child: IconButton(
    //           onPressed: () {
    //             homeCubit.deleteHorseProfileFromUser();
    //           },
    //           icon: const Icon(
    //             Icons.delete,
    //           ),
    //         ),
    //       ),
    //     ),
    //   ],
    // ),
    // //Icons

    //Menu
    Visibility(
      visible: isOwner,
      child: PopupMenuButton<String>(
        itemBuilder: (BuildContext menuContext) => <PopupMenuEntry<String>>[
          // const PopupMenuItem(
          //   value: 'Horse Log Book',
          //   child: Text('Horse Log Book'),
          // ),
          const PopupMenuItem(value: 'Edit', child: Text('Edit')),
          const PopupMenuItem(value: 'Delete', child: Text('Delete')),
          const PopupMenuItem(value: 'Transfer', child: Text('Transfer')),
        ],
        onSelected: (value) {
          switch (value) {
            case 'Edit':
              homeCubit.openAddHorseDialog(
                isEdit: true,
                context: context,
                horseProfile: state.horseProfile,
              );
              break;
            case 'Transfer':
              homeCubit.transferHorseProfile();
              break;
            case 'Delete':
              homeCubit.deleteHorseProfileFromUser();
              break;
          }
        },
      ),
    ),
  ];
}

Widget _currentOwner({
  required HorseProfile? horseProfile,
  required BuildContext context,
}) {
  return Row(
    children: [
      const Expanded(
        flex: 5,
        child: Text('Current Owner: '),
      ),
      Expanded(
        flex: 5,
        child: InkWell(
          onTap: horseProfile == null
              ? null
              : () => context.read<HomeCubit>().gotoProfilePage(
                    context: context,
                    toBeViewedEmail: horseProfile.currentOwnerId,
                  ),
          child: Text(
            horseProfile?.currentOwnerName ?? '',
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _logBookButton({required BuildContext context}) {
  return FilledButton.icon(
    onPressed: () {
      context.read<HomeCubit>().openLogBook(context);
    },
    icon: const Icon(
      HorseAndRiderIcons.horseLogIcon,
    ),
    label: const Text('Log Book'),
  );
}

Widget _horseBreed({required HorseProfile? horseProfile}) {
  return Row(
    children: [
      const Expanded(
        flex: 5,
        child: Text('Breed: '),
      ),
      Expanded(
        flex: 5,
        child: Text(
          '${horseProfile?.breed}',
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

Widget _horseColor({required HorseProfile? horseProfile}) {
  return Row(
    children: [
      const Expanded(
        flex: 5,
        child: Text('Color: '),
      ),
      Expanded(
        flex: 5,
        child: Text(
          '${horseProfile?.color}',
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

Widget _horseGender({required HorseProfile? horseProfile}) {
  return Row(
    children: [
      const Expanded(
        flex: 5,
        child: Text('Gender: '),
      ),
      Expanded(
        flex: 5,
        child: Text(
          '${horseProfile?.gender}',
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

Widget _horseDateOfBirth({required HorseProfile? horseProfile}) {
  return Row(
    children: [
      const Expanded(
        flex: 5,
        child: Text('Date of Birth: '),
      ),
      Expanded(
        flex: 5,
        child: Text(
          DateFormat('MMMM d yyyy').format(
            horseProfile?.dateOfBirth ?? DateTime.now(),
          ),
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

Widget _horseAge({required HorseProfile? horseProfile}) {
  final today = DateTime.now().year;
  final dob = horseProfile?.dateOfBirth?.year ?? today;
  final age = today - dob;
  return Row(
    children: [
      const Expanded(
        flex: 5,
        child: Text('Age: '),
      ),
      Expanded(
        flex: 5,
        child: Text(
          '$age',
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

Widget _horsePhoto({required HorseProfile? horseProfile}) {
  debugPrint('Horse photo url: ${horseProfile?.picUrl}');
  final isDark = SharedPrefs().isDarkMode;
  return Row(
    children: [
      //Horse Photo
      Padding(
        padding: const EdgeInsets.all(8),
        child: horseProfile?.picUrl != null && horseProfile!.picUrl!.isNotEmpty
            ? CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey,
                foregroundImage: NetworkImage(horseProfile.picUrl ?? ''),
              )
            : CircleAvatar(
                radius: 40,
                backgroundColor: Colors.transparent,
                foregroundImage: AssetImage(
                  isDark
                      ? 'assets/horse_icon_dark.png'
                      : 'assets/horse_icon_01.png',
                ),
              ),
      ),
      Expanded(
        flex: 6,
        child: Text(
          '${horseProfile?.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            // color: COLOR_CONST.WHITE,
            fontWeight: FontWeight.bold,
            fontSize: 30,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    ],
  );
}

Widget _horseLocation({required HorseProfile? horseProfile}) {
  return Row(
    children: [
      const Expanded(
        flex: 5,
        child: Text('Location: '),
      ),
      Expanded(
        flex: 5,
        child: Text(
          horseProfile?.locationName ?? 'No Location Specified',
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

Widget _horseNickName({required HorseProfile? horseProfile}) {
  return Row(
    children: [
      const Expanded(
        flex: 5,
        child: Text('NickName: '),
      ),
      Expanded(
        flex: 5,
        child: Text(
          '${horseProfile?.nickname}',
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

Widget _horseHeight({required HorseProfile? horseProfile}) {
  return Row(
    children: [
      const Expanded(
        flex: 5,
        child: Text('Height: '),
      ),
      Expanded(
        flex: 5,
        child: Text(
          '${horseProfile?.height}',
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

Widget _addLogEntryButton({
  required BuildContext context,
  required HorseProfile horseProfile,
  required RiderProfile riderProfile,
}) {
  return ElevatedButton(
    onPressed: () {
      showDialog<AddLogEntryDialog>(
        context: context,
        builder: (context) => AddLogEntryDialog(
          riderProfile: riderProfile,
          horseProfile: horseProfile,
        ),
      );
      context.read<HomeCubit>().addLogEntry(context: context);
    },
    child: const Text('Add an Entry into the Log'),
  );
}

Widget _notes({required HorseProfile? horseProfile}) {
  final notes = horseProfile?.notes;

  if (notes != null && notes.isNotEmpty) {
    if (notes.length > 1) {
      notes.sort(
        (a, b) => a.date!.compareTo(b.date as DateTime),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: horseProfile?.notes?.length,
      itemBuilder: (BuildContext context, int index) {
        final note = horseProfile?.notes?[index];
        return _noteItem(note: note);
      },
    );
  } else {
    return const Text('No Entries in the Log');
  }
}

// Widget that allows the user if the horse is
// notOwned to request to be studenthorse from the owner
Widget _requestToBeStudentHorseButton({
  required BuildContext context,
  required HorseProfile horseProfile,
  required bool isOwner,
}) {
  final isStudentHorse =
      context.read<HomeCubit>().isStudentHorse(horseProfile: horseProfile);
  return Visibility(
    visible: !isOwner,
    child: ElevatedButton(
      onPressed: () {
        context.read<HomeCubit>().requestToBeStudentHorse(
              isStudentHorse: isStudentHorse,
              context: context,
              horseProfile: horseProfile,
            );
      },
      child: Text(
        isStudentHorse
            ? 'Remove Horse as Student'
            : 'Request to be Student Horse',
      ),
    ),
  );
}

Widget _noteItem({required BaseListItem? note}) {
  final isDark = SharedPrefs().isDarkMode;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 100,
              child: Center(
                child: Text(
                  DateFormat('MMM\r\nd\r\nyyyy')
                      .format(note?.date ?? DateTime.now()),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            VerticalDivider(
              color: isDark ? Colors.white : Colors.black,
            ),
            Expanded(
              flex: 7,
              child: Text(
                note?.name ?? '',
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
