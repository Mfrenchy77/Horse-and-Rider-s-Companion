// ignore_for_file: cast_nullable_to_non_nullable,

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart'
    as adaptive;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_bloc.dart';
import 'package:horseandriderscompanion/Auth/auth_page.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/example_skill.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_level_card.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/profile_search_dialog.dart';
import 'package:horseandriderscompanion/HorseProfile/view/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/generated/l10n.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:url_launcher/url_launcher.dart';

Widget profileView({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  final usersProfile = state.usersProfile;
  final viewingProfile = state.viewingProfile;
  final isUser = state.viewingProfile == null;
  final isAuthorized = homeCubit.canViewInstructors();
  debugPrint(
    'UsersProfile: ${usersProfile?.name}, ViewingProfile: '
    '${viewingProfile?.name}',
  );
  return Scaffold(
    appBar: AppBar(
      //back if viewing profile
      leading: viewingProfile != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                homeCubit.goBackToUsersProfile(context);
              },
            )
          : null,
      title: appBarTitle(),
      actions: _appBarActions(
        iconSize: 24,
        state: state,
        isUser: isUser,
        isAuthorized: isAuthorized,
        usersProfile: usersProfile,
        homeCubit: homeCubit,
        context: context,
      ),
    ),
    drawer: state.isGuest || viewingProfile != null
        ? null
        : _drawer(
            homeCubit: homeCubit,
            state: state,
            context: context,
          ),
    body: adaptive.AdaptiveLayout(
      secondaryBody: adaptive.SlotLayout(
        config: <adaptive.Breakpoint, adaptive.SlotLayoutConfig>{
          adaptive.Breakpoints.large: adaptive.SlotLayout.from(
            key: const Key('smallProfileSecondaryBody'),
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
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextButton(
                            onPressed: () {
                              // Navigate to the skills page
                              homeCubit.navigateToSkillsList();
                            },
                            child: const Text(
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
                    ),
                  ],
                ),
                gap(),
                _skillsView(
                  context: context,
                  state: state,
                  homeCubit: homeCubit,
                ),
              ],
            ),
          ),
        },
      ),
      body: adaptive.SlotLayout(
        config: <adaptive.Breakpoint, adaptive.SlotLayoutConfig>{
          adaptive.Breakpoints.small: adaptive.SlotLayout.from(
            key: const Key('smallProfilePrimaryBody'),
            builder: (context) => SingleChildScrollView(
              child: Column(
                // needed for scrolling on mobile web
                children: [
                  _profile(
                    state: state,
                    homeCubit: homeCubit,
                    context: context,
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to the skills page
                      homeCubit.navigateToSkillsList();
                    },
                    child: const Text(
                      'Skills',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
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
          ),
          adaptive.Breakpoints.medium: adaptive.SlotLayout.from(
            key: const Key('mediumProfilePrimaryBody'),
            builder: (context) => ListView(
              shrinkWrap: true,
              children: [
                _profile(
                  state: state,
                  homeCubit: homeCubit,
                  context: context,
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
          adaptive.Breakpoints.large: adaptive.SlotLayout.from(
            key: const Key('largeProfilePrimaryBody'),
            builder: (context) => SingleChildScrollView(
              child: _profile(
                state: state,
                homeCubit: homeCubit,
                context: context,
              ),
            ),
          ),
        },
      ),
    ),
  );
}

Widget _name({
  required HomeState state,
  required BuildContext context,
}) {
  if (state.usersProfile != null) {
    return Row(
      children: [
        Expanded(
          child: ColoredBox(
            color:
                HorseAndRidersTheme().getTheme().appBarTheme.backgroundColor ??
                    Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Photo
                Visibility(
                  visible: !state.isGuest,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const ShapeDecoration(
                        color: Colors.white,
                        shape: CircleBorder(),
                      ),
                      child: profilePhoto(
                        context: context,
                        size: 100,
                        profilePicUrl: state.viewingProfile != null
                            ? state.viewingProfile?.picUrl
                            : state.usersProfile?.picUrl,
                      ),
                    ),
                  ),
                ),
                Text(
                  state.viewingProfile?.name ?? state.usersProfile!.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w200,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  } else if (state.viewingProfile != null) {
    return Row(
      children: [
        // Profile Photo
        Visibility(
          visible: !state.isGuest,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const ShapeDecoration(
                color: Colors.white,
                shape: CircleBorder(),
              ),
              child: profilePhoto(
                context: context,
                size: 62,
                profilePicUrl:
                    state.viewingProfile?.picUrl ?? state.usersProfile?.picUrl,
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Viewing: ',
              style: TextStyle(fontSize: 30, color: Colors.white),
            ),
            Text(
              state.viewingProfile!.name,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  } else {
    return Row(
      children: [
        Expanded(
          child: ColoredBox(
            color:
                HorseAndRidersTheme().getTheme().appBarTheme.backgroundColor ??
                    Colors.white,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Welcome, Guest',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w200,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Profile view for the user or viewed profile
/// if userProfile is null then treat this as
/// a guest user and show a welcome message
Widget _profile({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
  return Column(
    children: [
      Center(child: _name(state: state, context: context)),
      smallGap(),
      Visibility(
        visible: state.isGuest,
        child: const Divider(
          indent: 100,
          endIndent: 100,
          color: Colors.black,
          thickness: 1,
        ),
      ),
      Visibility(
        visible: state.isGuest,
        child: Tooltip(
          message: 'Create Account/Login',
          child: MaxWidthBox(
            maxWidth: 200,
            child: FilledButton(
              onPressed: () {
                context.read<AppBloc>().add(AppLogoutRequested());

                Navigator.pushReplacementNamed(
                  context,
                  AuthPage.routeName,
                );
              },
              child: const Text('Create Account/Login'),
            ),
          ),
        ),
      ),
      const Divider(
        indent: 50,
        endIndent: 50,
        color: Colors.black,
        thickness: 1,
      ),
      if (state.isGuest)
        const SingleChildScrollView(
          child: Center(
            child: MaxWidthBox(
              maxWidth: 1000,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  textAlign: TextAlign.center,
                  "Welcome to Horse & Rider's Companion, the definitive"
                  ' platform for riders and horse owners dedicated to enhancing'
                  ' their equestrian skills and knowledge. As a guest, you have'
                  ' the opportunity to explore an array of features designed to'
                  ' support your riding journey. Delve into our comprehensive'
                  ' skill tree to gain insights into various aspects of horse'
                  ' riding and care. Browse through a curated selection of'
                  ' articles and videos, meticulously linked to specific'
                  ' skills, providing you with valuable resources for focused'
                  " learning.\n\n Discover our unique 'Training Paths', "
                  'crafted by experienced trainers and instructors, to '
                  'guide you through structured learning experiences. '
                  "Although you're currently exploring as a guest, a full "
                  'membership offers personalized tracking of your progress, '
                  'the ability to assign instructors for skill validation, and '
                  'a more connected equestrian community experience. We invite '
                  'you to join us and fully immerse yourself in the world of '
                  "Horse & Rider's Companion, where your passion for horse "
                  'riding and care is our utmost priority.',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        )
      else
        Column(
          children: [
            gap(),
            _riderLocation(
              riderProfile: state.viewingProfile ?? state.usersProfile,
            ),
            gap(),
            _riderBio(
              context: context,
              riderProfile: state.viewingProfile ?? state.usersProfile,
            ),
            gap(),
            Center(
              child: _websiteLink(
                context: context,
                riderProfile: state.viewingProfile ?? state.usersProfile,
              ),
            ),
            gap(),
            Visibility(
              visible: state.usersProfile != null,
              child: Center(
                child: Text(
                  state.viewingProfile?.email ??
                      state.usersProfile?.email ??
                      '',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            gap(),
            _lists(
              state: state,
              context: context,
              homeCubit: homeCubit,
            ),
            gap(),
            // Log Book Button
            _logBookButton(
              state: state,
              context: context,
              homeCubit: homeCubit,
            ),
          ],
        ),
    ],
  );
}

Widget _logBookButton({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
  return Visibility(
    visible: homeCubit.canViewInstructors(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: 'Open the Log Book',
          child: FilledButton.icon(
            onPressed: () {
              context.read<HomeCubit>().openLogBook(
                    cubit: homeCubit,
                    context: context,
                  );
            },
            icon: const Icon(
              HorseAndRiderIcons.riderLogIcon,
            ),
            label: const Text('Log Book'),
          ),
        ),
        Tooltip(
          message: 'Add an Entry into the Log',
          child: IconButton(
            onPressed: () {
              showDialog<AddLogEntryDialog>(
                context: context,
                builder: (context) => AddLogEntryDialog(
                  riderProfile: state.viewingProfile ?? state.usersProfile!,
                  horseProfile: null,
                ),
              );
            },
            icon: const Icon(
              Icons.add,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _lists({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
  // show the instructor, student and horse list for the respective profile
  //if screen size is larger than a tablet then show the lists side by side
  // else show them in a column

  return Column(
    children: [
      Visibility(
        visible: state.viewingProfile?.instructors?.isNotEmpty ??
            state.usersProfile?.instructors?.isNotEmpty ??
            false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: Text(
                'Instructors',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            smallGap(),
            Wrap(
              direction: Axis.vertical,
              spacing: 5,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: [
                Column(
                  children: state.viewingProfile != null
                      ? state.viewingProfile?.instructors
                              ?.map(
                                (e) => _profileCard(
                                  context: context,
                                  baseItem: e,
                                  homeCubit: homeCubit,
                                ),
                              )
                              .toList() ??
                          []
                      : state.usersProfile?.instructors
                              ?.map(
                                (e) => _profileCard(
                                  context: context,
                                  baseItem: e,
                                  homeCubit: homeCubit,
                                ),
                              )
                              .toList() ??
                          [],
                ),
              ],
            ),
          ],
        ),
      ),
      gap(),
      Visibility(
        visible: state.viewingProfile?.students?.isNotEmpty ??
            state.usersProfile?.students?.isNotEmpty ??
            false,
        child: Column(
          children: [
            const Text(
              'Students',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            smallGap(),
            Wrap(
              direction: Axis.vertical,
              spacing: 5,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: [
                ...state.viewingProfile?.students
                        ?.map(
                          (e) => _profileCard(
                            context: context,
                            baseItem: e,
                            homeCubit: homeCubit,
                          ),
                        )
                        .toList() ??
                    state.usersProfile?.students
                        ?.map(
                          (e) => _profileCard(
                            context: context,
                            baseItem: e,
                            homeCubit: homeCubit,
                          ),
                        )
                        .toList() ??
                    [],
              ],
            ),
          ],
        ),
      ),
      gap(),
      Visibility(
        visible: state.viewingProfile?.ownedHorses?.isNotEmpty ??
            state.usersProfile?.ownedHorses?.isNotEmpty ??
            false,
        child: Column(
          children: [
            const Text(
              'Owned Horses',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            smallGap(),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: [
                ...state.viewingProfile?.ownedHorses
                        ?.map(
                          (e) => _profileCard(
                            context: context,
                            baseItem: e,
                            homeCubit: homeCubit,
                          ),
                        )
                        .toList() ??
                    state.usersProfile?.ownedHorses
                        ?.map(
                          (e) => _profileCard(
                            context: context,
                            baseItem: e,
                            homeCubit: homeCubit,
                          ),
                        )
                        .toList() ??
                    [],
              ],
            ),
          ],
        ),
      ),
      //student horses
      Visibility(
        visible: state.viewingProfile?.studentHorses?.isNotEmpty ??
            state.usersProfile?.studentHorses?.isNotEmpty ??
            false,
        child: Column(
          children: [
            const Text(
              'Student Horses',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            smallGap(),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: [
                ...state.viewingProfile?.studentHorses
                        ?.map(
                          (e) => _profileCard(
                            context: context,
                            baseItem: e,
                            homeCubit: homeCubit,
                          ),
                        )
                        .toList() ??
                    state.usersProfile?.studentHorses
                        ?.map(
                          (e) => _profileCard(
                            context: context,
                            baseItem: e,
                            homeCubit: homeCubit,
                          ),
                        )
                        .toList() ??
                    [],
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

/// app bar actions
List<Widget>? _appBarActions({
  required double iconSize,
  required HomeState state,
  required bool isUser,
  required bool isAuthorized,
  required RiderProfile? usersProfile,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
  if (usersProfile != null) {
    return [
      //search
      IconButton(
        onPressed: () {
          showDialog<AlertDialog>(
            context: context,
            builder: (dialogContext) => ProfileSearchDialog(
              homeContext: context,
              key: const Key('ProfileSearchDialog'),
            ),
          );

          debugPrint('Search Clicked');
        },
        icon: const Icon(Icons.search),
      ),

      PopupMenuButton<String>(
        itemBuilder: (BuildContext menuContext) => <PopupMenuEntry<String>>[
          const PopupMenuItem(value: 'Edit', child: Text('Edit Profile')),
          const PopupMenuItem(value: 'Log Book', child: Text('Log Book')),
          const PopupMenuItem(value: 'Add Horse', child: Text('Add Horse')),
          const PopupMenuItem(value: 'Settings', child: Text('Settings')),
        ],
        onSelected: (value) {
          switch (value) {
            case 'Edit':
              homeCubit.openEditDialog(context: context);
              break;
            case 'Log Book':
              homeCubit.openLogBook(cubit: homeCubit, context: context);
              break;
            case 'Add Horse':
              homeCubit.openAddHorseDialog(
                context: context,
                horseProfile: null,
                isEdit: false,
              );
              break;
            case 'Settings':
              Navigator.of(context, rootNavigator: true)
                  .restorablePushNamed(SettingsView.routeName);
              break;
          }
        },
      ),
    ];
  } else {
    return null;
  }
}

/// Drawer for the user
Widget? _drawer({
  required BuildContext context,
  required HomeState state,
  required HomeCubit homeCubit,
}) {
  if (state.usersProfile != null) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            // margin: const EdgeInsets.only(top: 8, left: 8),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  SharedPrefs().isDarkMode
                      ? 'assets/horse_logo_and_text_dark.png'
                      : 'assets/horse_logo_and_text_light.png',
                ),
                alignment: Alignment.topLeft,
                scale: 10,
              ),
            ),
            accountName: Text(
              state.usersProfile!.name,
              style: TextStyle(
                color: SharedPrefs().isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            accountEmail: Text(
              state.usersProfile?.email ?? '',
              style: TextStyle(
                color: SharedPrefs().isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),

          ///   Sign Out
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Sign out'),
            onTap: () {
              context.read<AppBloc>().add(AppLogoutRequested());

              Navigator.pushReplacementNamed(context, AuthPage.routeName);
            },
          ),
          //Log Book List Tile
          ListTile(
            leading: const Icon(HorseAndRiderIcons.riderLogIcon),
            title: const Text('Log Book'),
            onTap: () =>
                homeCubit.openLogBook(cubit: homeCubit, context: context),
          ),

          //  saved profile list
          Visibility(
            visible: state.usersProfile?.savedProfilesList?.isNotEmpty ?? false,
            child: ExpansionTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Contacts'),
              children: [
                _savedLists(
                  homeCubit: homeCubit,
                  state: state,
                  context: context,
                  list: state.usersProfile?.savedProfilesList ?? [],
                ),
              ],
            ),
          ),

          // saved instructor list
          Visibility(
            visible: state.usersProfile?.instructors?.isNotEmpty ?? false,
            child: ExpansionTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Instructors'),
              children: [
                _savedLists(
                  homeCubit: homeCubit,
                  state: state,
                  context: context,
                  list: state.usersProfile?.instructors ?? [],
                ),
              ],
            ),
          ),

          // saved student list
          Visibility(
            visible: state.usersProfile?.students?.isNotEmpty ?? false,
            child: ExpansionTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Students'),
              children: [
                _savedLists(
                  homeCubit: homeCubit,
                  state: state,
                  context: context,
                  list: state.usersProfile?.students ?? [],
                ),
              ],
            ),
          ),

          Visibility(
            visible: state.usersProfile?.ownedHorses?.isNotEmpty ?? false,
            child: ExpansionTile(
              leading: const Icon(HorseAndRiderIcons.horseIcon),
              title: const Text('Owned Horses'),
              children: [
                _savedLists(
                  homeCubit: homeCubit,
                  state: state,
                  context: context,
                  list: state.usersProfile?.ownedHorses ?? [],
                ),
              ],
            ),
          ),
          Visibility(
            visible: state.usersProfile?.studentHorses?.isNotEmpty ?? false,
            child: ExpansionTile(
              leading: const Icon(HorseAndRiderIcons.horseIcon),
              title: const Text('Student Horses'),
              children: [
                _savedLists(
                  homeCubit: homeCubit,
                  state: state,
                  context: context,
                  list: state.usersProfile?.studentHorses ?? [],
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person_search),
            title: const Text('Search Horse/Rider'),
            onTap: () {
              showDialog<AlertDialog>(
                context: context,
                builder: (dialogContext) => ProfileSearchDialog(
                  homeContext: context,
                  key: const Key('ProfileSearchDialog'),
                ),
              );

              debugPrint('Search Clicked');
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail),
            title: const Text('Messages'),
            onTap: () {
              //closes the drawer
              debugPrint('Messages');
              Navigator.pop(context);
              homeCubit.openMessages(context: context);
            },
          ),

          Divider(
            color: SharedPrefs().isDarkMode ? Colors.white : Colors.black,
            height: 10,
            thickness: 1,
          ),

          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(S.of(context).settings_text),
            onTap: () => Navigator.of(context, rootNavigator: true)
                .restorablePushNamed(SettingsView.routeName),
          ),

          ListTile(
            leading: const Icon(
              Icons.help,
            ),
            title: const Text(
              'Send Email to Support',
            ),
            onTap: () {
              //closes the drawer
              debugPrint('Send Email to Support');
              Navigator.pop(context);

              context.read<HomeCubit>().openMessageToSupportDialog();
            },
          ),
        ],
      ),
    );
  } else {
    return null;
  }
}

Widget _profileCard({
  required BuildContext context,
  required BaseListItem baseItem,
  required HomeCubit homeCubit,
}) {
  return SizedBox(
    width: 200,
    child: Card(
      elevation: 8,
      child: ListTile(
        leading: profilePhoto(
          context: context,
          size: 45,
          profilePicUrl: baseItem.imageUrl,
        ),
        title: Text(
          baseItem.name ?? '',
          textAlign: TextAlign.center,
        ),
        onTap: () => baseItem.isCollapsed!
            ? homeCubit.gotoProfilePage(
                context: context,
                toBeViewedEmail: baseItem.id ?? '',
              )
            : context.read<HomeCubit>().horseProfileSelected(
                  id: baseItem.id ?? '',
                ),
      ),
    ),
  );
}

Widget _profileTile({
  required BuildContext context,
  required BaseListItem baseItem,
  required HomeCubit homeCubit,
}) {
  return SizedBox(
    width: 200,
    child: ListTile(
      leading: profilePhoto(
        context: context,
        size: 45,
        profilePicUrl: baseItem.imageUrl,
      ),
      title: Text(
        baseItem.name ?? '',
        textAlign: TextAlign.center,
      ),
      onTap: () => baseItem.isCollapsed!
          ? homeCubit.gotoProfilePage(
              context: context,
              toBeViewedEmail: baseItem.id ?? '',
            )
          : context.read<HomeCubit>().horseProfileSelected(
                id: baseItem.id ?? '',
              ),
    ),
  );
}

Widget _riderLocation({required RiderProfile? riderProfile}) {
  return Center(
    child: Text(
      riderProfile?.locationName == null ? '' : '${riderProfile?.locationName}',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

Widget _riderBio({
  required BuildContext context,
  required RiderProfile? riderProfile,
}) {
  return Visibility(
    visible: riderProfile?.bio != null,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: MaxWidthBox(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
        child: Text(
          riderProfile?.bio ?? '',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

Widget _websiteLink({
  required BuildContext context,
  required RiderProfile? riderProfile,
}) {
  return Visibility(
    visible: riderProfile?.homeUrl != null,
    child: InkWell(
      onTap: () => launchUrl(Uri.parse(riderProfile?.homeUrl as String)),
      child: const Text(
        'Website Link',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );
}

//a widget that shows the user the saved profile list

// A list of saved horses
Widget _savedLists({
  required BuildContext context,
  required List<BaseListItem> list,
  required HomeState state,
  required HomeCubit homeCubit,
}) {
  return ListView.builder(
    shrinkWrap: true,
    physics: const AlwaysScrollableScrollPhysics(),
    itemCount: list.length,
    itemBuilder: (context, index) {
      final baseItem = list[index];
      return Center(
        child: _profileTile(
          context: context,
          baseItem: baseItem,
          homeCubit: homeCubit,
        ),
      );
    },
  );
}

Widget _skillsView({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  // a list of the skills in the users skilllevels showing the level of progress
  final skillLevels = state.viewingProfile != null
      ? state.viewingProfile?.skillLevels
      : state.usersProfile?.skillLevels;

  if (state.isGuest) {
    return Column(
      children: [
        const Center(
          child: Text(
            'This is where the skills that you are working on and '
            'proficent in will be displayed.  If a trainer or instructor has '
            'verified the skill, it will marked as such and in yellow.',
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
                    skillLevel: e,
                    state: state,
                  ),
                ),
          ],
        ),
      ],
    );
  } else {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      alignment: WrapAlignment.center,
      children: [
        ...skillLevels
                ?.map(
                  (e) => skillLevelCard(
                    state: state,
                    context: context,
                    skillLevel: e,
                    homeCubit: homeCubit,
                  ),
                )
                .toList() ??
            [const Text('No Skills')],
      ],
    );
  }
}
