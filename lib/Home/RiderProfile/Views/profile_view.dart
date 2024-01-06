// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart'
    as adaptive;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/notification_icon.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/search_dialog.dart';
import 'package:horseandriderscompanion/Login/view/login_page.dart';
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
  final isAuthorized = homeCubit.isAuthtorized();
  debugPrint(
    'UsersProfile: ${usersProfile?.name}, ViewingProfile: ${viewingProfile?.name}',
  );
  return Scaffold(
    appBar: AppBar(
      title: _largeScreenAppBarTitle(state: state, context: context),
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
    drawer: isUser && MediaQuery.of(context).size.width < 800
        ? _drawer(
            homeCubit: homeCubit,
            state: state,
            context: context,
          )
        : null,
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
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Skills',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                gap(),
                secondaryView(
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
            builder: (context) => ListView(
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
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                gap(),
                secondaryView(
                  context: context,
                  homeCubit: homeCubit,
                  state: state,
                ),
              ],
            ),
          ),
          adaptive.Breakpoints.medium: adaptive.SlotLayout.from(
            key: const Key('mediumProfilePrimaryBody'),
            builder: (context) => ListView(
              children: [
                _profile(
                  state: state,
                  homeCubit: homeCubit,
                  context: context,
                ),
                secondaryView(
                  context: context,
                  homeCubit: homeCubit,
                  state: state,
                ),
              ],
            ),
          ),
          adaptive.Breakpoints.large: adaptive.SlotLayout.from(
            key: const Key('largeProfilePrimaryBody'),
            builder: (context) => _profile(
              state: state,
              homeCubit: homeCubit,
              context: context,
            ),
          ),
        },
      ),
    ),

    // _profile(state: state, homeCubit: homeCubit, context: context),
    // body: CustomScrollView(
    //   slivers: [
    //     _sliverAppBar(
    //       state: state,
    //       context: context,
    //       isUser: isUser,
    //       isAuthorized: isAuthorized,
    //       usersProfile: usersProfile,
    //       homeCubit: homeCubit,
    //     ),
    //     _profile(
    //       homeCubit: homeCubit,
    //       state: state,
    //       context: context,
    //     ),
    //   ],
    // ),
  );
}

// Widget _transitionalAppBar({required HomeState state}) {
//   return SliverPersistentHeader(
//     pinned: true,
//     delegate: ProfileHeader(
//       imageUrl: state.viewingProfile?.picUrl ?? state.usersProfile?.picUrl,
//       title: _appBarTitleString(state: state),
//     ),
//   );
// }

/// scrollable and pinned SliverApp bar to replace the app bar
Widget _sliverAppBar({
  required HomeState state,
  required BuildContext context,
  required bool isUser,
  required bool isAuthorized,
  required RiderProfile? usersProfile,
  required HomeCubit homeCubit,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isLargeScreen = screenWidth > 800;

  return SliverAppBar(
    floating: true,
    pinned: true,
    snap: true,
    expandedHeight:
        isLargeScreen ? 60 : 400.0, // Adjust height for large screens
    collapsedHeight: 60,
    // leading: state.viewingProfile != null
    //     ? IconButton(
    //         onPressed: homeCubit.goBackToUsersProfile,
    //         icon: const Icon(Icons.arrow_back),
    //       )
    //     : null,
    title: isLargeScreen
        ? _largeScreenAppBarTitle(state: state, context: context)
        : null,
    // actions: _appBarActions(
    //   iconSize: 24,
    //   state: state,
    //   isUser: isUser,
    //   isAuthorized: isAuthorized,
    //   usersProfile: usersProfile,
    //   homeCubit: homeCubit,
    //   context: context,
    // ),
    flexibleSpace: isLargeScreen
        ? null
        : _defaultFlexibleSpaceBar(
            state: state,
            context: context,
          ),
  );
}

Widget _largeScreenAppBarTitle({
  required HomeState state,
  required BuildContext context,
}) {
  return Row(
    children: [
      // Logo
      // const Image(
      //   color: Colors.white,
      //   fit: BoxFit.contain,
      //   image: AssetImage('assets/horse_logo.png'),
      //   height: 40,
      // ),
      gap(),
      const Expanded(
        flex: 8,
        child: Image(
          color: Colors.white,
          image: AssetImage(
            'assets/horse_text.png',
          ),
          height: 25,
        ),
      ),
      gap(),

      // Title
      // Center(child: _appbarTitle(state: state)),
    ],
  );
}

Widget _defaultFlexibleSpaceBar({
  required HomeState state,
  required BuildContext context,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isLargeScreen = screenWidth > 800;
  final expandedHeight =
      isLargeScreen ? 100.0 : 400.0; // Smaller height for large screens
  const collapsedHeight = 60.0;
  return FlexibleSpaceBar(
    centerTitle: true,
    collapseMode: CollapseMode.pin,
    title: _name(state: state, context: context),
    background: Stack(
      children: [
        //background image
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: expandedHeight - collapsedHeight - 80,
            child: _appBarBackground(state: state),
          ),
        ),
        Visibility(
          visible: !state.isGuest,
          child: Positioned(
            //profile photo
            bottom: collapsedHeight + 10,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: ShapeDecoration(
                color: HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
                shape: const CircleBorder(),
              ),
              child: profilePhoto(
                context: context,
                size: 150,
                profilePicUrl:
                    state.viewingProfile?.picUrl ?? state.usersProfile?.picUrl,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _name({
  required HomeState state,
  required BuildContext context,
}) {
  //if riderProfile is null --  Horse & Rider's Companion
  // if riderProfile is not null -- riderProfile.name
  // if viewingProfile is not null -- Viewing: viewingProfile.name

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
                        profilePicUrl: state.viewingProfile?.picUrl ??
                            state.usersProfile?.picUrl,
                      ),
                    ),
                  ),
                ),
                Text(
                  state.usersProfile!.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
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
        Text(
          'Viewing: ${state.viewingProfile!.name}',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
        ),
      ],
    );
  } else {
    return const Text(
      'Welcome, Guest',
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300),
    );
  }
}

Widget _appBarBackground({
  required HomeState state,
}) {
  return Padding(
    padding: const EdgeInsets.all(10),
    child: Container(
      alignment: AlignmentDirectional.bottomStart,
      margin: const EdgeInsets.only(top: 24),
      decoration: BoxDecoration(
        color: HorseAndRidersTheme().getTheme().appBarTheme.backgroundColor,
        image: const DecorationImage(
          image: AssetImage(
            'assets/horse_logo_and_text_dark.png',
          ),
          fit: BoxFit.fitHeight,
        ),
      ),
    ),
  );
}

/// Profile view for the user or viewed profile
/// if userProfile is null then treat this as
/// a guest user and show a welcome message
Widget _profile({
  required HomeState state,
  required HomeCubit homeCubit,
  required BuildContext context,
}) {
  return ListView(
    shrinkWrap: true,
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
                  LoginPage.routeName,
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
                  "Welcome to Horse & Rider's Companion, the definitive platform "
                  'for riders and horse owners dedicated to enhancing their equestrian skills and knowledge. '
                  'As a guest, you have the opportunity to explore an array of features designed to support your '
                  'riding journey. Delve into our comprehensive skill tree to gain insights into various aspects '
                  'of horse riding and care. Browse through a curated selection of articles and videos, meticulously '
                  'linked to specific skills, providing you with valuable resources for focused learning.\n\n'
                  "Discover our unique 'Training Paths', crafted by experienced trainers and instructors, to guide "
                  "you through structured learning experiences. Although you're currently exploring as a guest, a full "
                  'membership offers personalized tracking of your progress, the ability to assign instructors for skill '
                  'validation, and a more connected equestrian community experience. We invite you to join us and fully '
                  "immerse yourself in the world of Horse & Rider's Companion, where your passion for horse riding and care "
                  'is our utmost priority.',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        )
      else
        ListView(
          shrinkWrap: true,
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
            // TODO(mfrenchy77): Move this to edit profile
            // Visibility(
            //   visible: state.usersProfile != null,
            //   child: Center(
            //     child: _trainerQuestion(
            //       context: context,
            //       usersProfile: state.usersProfile,
            //       homeCubit: homeCubit,
            //     ),
            //   ),
            // ),
            gap(),
            Visibility(
              visible: state.usersProfile != null,
              child: Center(
                child: Text(
                  state.usersProfile!.email,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            gap(),
            _lists(context: context, state: state, homeCubit: homeCubit),
            gap(),
            // Log Book Button
            Visibility(
              visible: homeCubit.isAuthtorized(),
              child: MaxWidthBox(
                maxWidth: 200,
                child: FilledButton.icon(
                  label: Text(
                    S.of(context).log_book_text,
                  ),
                  icon: const Icon(HorseAndRiderIcons.riderLogIcon),
                  onPressed: () => homeCubit.openLogBook(context),
                ),
              ),
            ),
            gap(),
          ],
        ),
    ],
  );
}

Widget _lists({
  required BuildContext context,
  required HomeState state,
  required HomeCubit homeCubit,
}) {
  // show the instructor, student and horse list for the respective profile
  //if screen size is larger than a tablet then show the lists side by side
  // else show them in a column

  return Column(
    children: [
      Visibility(
        visible: state.viewingProfile?.instructors?.isNotEmpty ??
            state.usersProfile!.instructors?.isNotEmpty ??
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
                ...state.viewingProfile?.instructors
                        ?.map(
                          (e) => _profileCard(
                            context: context,
                            baseItem: e,
                            homeCubit: homeCubit,
                          ),
                        )
                        .toList() ??
                    state.usersProfile!.instructors
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
        visible: state.viewingProfile?.students?.isNotEmpty ??
            state.usersProfile!.students?.isNotEmpty ??
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
                    state.usersProfile!.students
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
            state.usersProfile!.ownedHorses?.isNotEmpty ??
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
                    state.usersProfile!.ownedHorses
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
            state.usersProfile!.studentHorses?.isNotEmpty ??
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
                    state.usersProfile!.studentHorses
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
      if (isUser)
        Tooltip(
          message: 'Messages',
          child: NotificationIcon(
            iconData: Icons.mail,
            notificationCount: state.unreadMessages,
            onTap: () => homeCubit.openMessages(context: context),
          ),
        ),
      if (isUser &&
          ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP)) ...[
        gap(),
        Visibility(
          visible: usersProfile.editor ?? false,
          child: Tooltip(
            message: 'Edit Profile',
            child: IconButton(
              iconSize: iconSize,
              onPressed: () => showDialog<EditRiderProfileDialog>(
                context: context,
                builder: (context) => EditRiderProfileDialog(
                  riderProfile: usersProfile,
                ),
              ),
              icon: const Icon(Icons.edit),
            ),
          ),
        ),
      ],
      if (isAuthorized &&
          ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP)) ...[
        gap(),
        Tooltip(
          message: 'Log Book',
          child: IconButton(
            iconSize: iconSize,
            onPressed: () => homeCubit.openLogBook(context),
            icon: const Icon(HorseAndRiderIcons.riderLogIcon),
          ),
        ),
      ],
      if (ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP)) ...[
        gap(),
        Tooltip(
          message: 'Settings',
          child: IconButton(
            iconSize: iconSize,
            onPressed: () => Navigator.of(context, rootNavigator: true)
                .restorablePushNamed(SettingsView.routeName),
            icon: const Icon(Icons.settings),
          ),
        ),
      ],
      if (isUser &&
          ResponsiveBreakpoints.of(context).largerOrEqualTo(DESKTOP)) ...[
        gap(),
        Tooltip(
          message: 'Add Horse',
          child: IconButton(
            iconSize: iconSize,
            onPressed: () => homeCubit.openAddHorseDialog(
              context: context,
              horseProfile: null,
              isEdit: false,
            ),
            icon: const Icon(HorseAndRiderIcons.horseIconAdd),
          ),
        ),
        gap(),
      ],
      if (isUser && ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET))
        PopupMenuButton<String>(
          itemBuilder: (BuildContext menuContext) => <PopupMenuEntry<String>>[
            const PopupMenuItem(value: 'Edit', child: Text('Edit')),
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
                homeCubit.openLogBook(context);
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
              default:
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

              Navigator.pushReplacementNamed(context, LoginPage.routeName);
            },
          ),
          //Log Book List Tile
          ListTile(
            leading: const Icon(HorseAndRiderIcons.riderLogIcon),
            title: const Text('Log Book'),
            onTap: () => homeCubit.openLogBook(context),
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
                builder: (dialogContext) => AlertDialog(
                  title: Text(
                    state.searchState == SearchState.email
                        ? 'Search for Contact By Email'
                        : state.searchState == SearchState.name
                            ? 'Search for Contact By Name'
                            : state.searchState == SearchState.horse
                                ? 'Search for Horse By Official Name'
                                : 'Search for Horse By NickName',
                    textAlign: TextAlign.center,
                  ),
                  content: SearchDialog(userProfile: state.usersProfile!),
                  actions: [
                    Visibility(
                      visible: state.searchResult.isNotEmpty ||
                          state.horseSearchResult.isNotEmpty,
                      child: TextButton(
                        onPressed: homeCubit.clearSearchResults,
                        child: const Text('Clear Search'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        homeCubit.closeSearchForHorsesOrRiders();
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ).then(
                (value) => homeCubit.closeSearchForHorsesOrRiders(),
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

Widget _trainerQuestion({
  required BuildContext context,
  required RiderProfile? usersProfile,
  required HomeCubit homeCubit,
}) {
  bool showIsTrainer;
  if (usersProfile?.isTrainer == null) {
    showIsTrainer = true;
  } else if (usersProfile?.isTrainer == false) {
    showIsTrainer = false;
  } else {
    showIsTrainer = true;
  }

  return Visibility(
    visible: showIsTrainer,
    child: Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Row(
        children: [
          const Expanded(
            flex: 6,
            child: Text(
              'Are you a Trainer/Instructor?',
            ),
          ),
          const Text(
            'Yes',
          ),
          Checkbox(
            value: false,
            onChanged: (value) => homeCubit.toggleIsTrainerState(
              isTrainer: true,
              context: context,
            ),
          ),
          const Text(
            'No',
          ),
          Checkbox(
            value: false,
            onChanged: (value) => homeCubit.toggleIsTrainerState(
              isTrainer: false,
              context: context,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget secondaryView({
  required BuildContext context,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  // a list of the skills in the users skilllevels showing the level of progress

  return Wrap(
    spacing: 5,
    runSpacing: 5,
    alignment: WrapAlignment.center,
    children: [
      ...state.usersProfile?.skillLevels
              ?.map(
                (e) => _skillLevelCard(
                  state: state,
                  context: context,
                  skillLevel: e,
                  homeCubit: homeCubit,
                ),
              )
              .toList() ??
          [],
    ],
  );
}

Widget _skillLevelCard({
  required BuildContext context,
  required SkillLevel skillLevel,
  required HomeCubit homeCubit,
  required HomeState state,
}) {
  final skill = state.allSkills
      ?.firstWhere((element) => element?.id == skillLevel.skillId) as Skill;
  // a card that shows the skill name and the visual representation of the Level State, by
  // having the background be half filled if the level state in in Progress filled if the level state is complete
  // and yellow if the level state is verified
  return SizedBox(
    width: 200,
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: skillLevel.levelState == LevelState.PROFICIENT
              ? homeCubit.levelColor(
                  levelState: skillLevel.levelState,
                  skill: skill,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          gradient: skillLevel.levelState == LevelState.LEARNING
              ? LinearGradient(
                  stops: const [0.5, 0.5],
                  colors: [
                    homeCubit.levelColor(
                      levelState: skillLevel.levelState,
                      skill: skill,
                    ),
                    Colors.transparent,
                  ],
                )
              : null,
        ),
        child: ListTile(
          title: Text(
            skill?.skillName ?? '',
            textAlign: TextAlign.center,
          ),
          subtitle: Text(
            skillLevel.levelState.toString().split('.').last,
            textAlign: TextAlign.center,
          ),
          onTap: () => homeCubit.navigateToSkillLevel(
            isSplitScreen: MediaQuery.of(context).size.width > 1200,
            skill: skill,
          ),
        ),
      ),
    ),
  );
}
