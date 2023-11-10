// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:authentication_repository/authentication_repository.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/notification_icon.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_header.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/CommonWidgets/responsive_appbar.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/Login/view/login_page.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/generated/l10n.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.user,
    required this.state,
    required this.isViewing,
    required this.buildContext,
    required this.viewingProfile,
    required this.usersProfile,
    required this.homeCubit,
  });
  final User user;
  final bool isViewing;
  final HomeCubit homeCubit;
  final HomeState state;
  final BuildContext buildContext;
  final RiderProfile? viewingProfile;
  // if usersProfile is null then treat this as
  // a guest user
  final RiderProfile? usersProfile;
  @override
  Widget build(BuildContext context) {
    final scaler = ResponsiveScaler();
    // Get responsive text size and icon size
    final textSize = scaler.responsiveTextSize(
      context,
      16,
    ); // where 16.0 is your base text size
    final iconSize = scaler.responsiveIconSize(
      context,
      24,
    ); // where 24.0 is your base icon size
// where 24.0 is your base icon size

    //final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(DESKTOP);
    final isUser = viewingProfile == null;
    final isDark = SharedPrefs().isDarkMode;
    final isAuthorized = homeCubit.isAuthtorized();
    debugPrint('isViewing: $isViewing');
    debugPrint(
      'UsersProfile: ${usersProfile?.name}, ViewingProfile: ${viewingProfile?.name}',
    );
    return Scaffold(
      drawer: isUser
          ? _drawer(
              homeCubit: homeCubit,
              state: state,
              context: context,
            )
          : null,
      body: CustomScrollView(
        slivers: [
          _sliverAppBar(
            state: state,
            context: context,
            isUser: isUser,
            isAuthorized: isAuthorized,
            usersProfile: usersProfile,
            homeCubit: homeCubit,
          ),
          _profile(
            homeCubit: homeCubit,
            state: state,
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _transitionalAppBar({required HomeState state}) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: ProfileHeader(
        imageUrl: state.viewingProfile?.picUrl ?? state.usersProfile?.picUrl,
        title: _appBarTitleString(state: state),
      ),
    );
  }

  /// scrollable and pinned SliverApp bar to replace the app bar
  ///
  Widget _sliverAppBar({
    required HomeState state,
    required BuildContext context,
    required bool isUser,
    required bool isAuthorized,
    required RiderProfile? usersProfile,
    required HomeCubit homeCubit,
  }) {
    const expandedHeight = 400.0;
    const collapsedHeight = 60.0;
    return SliverAppBar(

    //  actionsIconTheme: HorseAndRidersTheme().getTheme().iconTheme,
      // height should scale with screen size
      floating: true,
      pinned: true,
      snap: true,
     // backgroundColor: HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
      // show the user's profile pic if they have one or else 'assets/horse_icon_circle_dark.png'
      // if viewingProfile is not null then show viewingProfile.picUrl if they have one
      // else show 'assets/horse_icon_circle_dark.png'
      // if both are null then show 'assets/horse_icon_circle_dark.png'
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        collapseMode: CollapseMode.pin,
        title: _appbarTitle(state: state),
        
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
            //profile photo
            Positioned(
              bottom: collapsedHeight + 30,
              left: MediaQuery.of(context).size.width / 2 - 50,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: ShapeDecoration(
                  color:
                      HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
                  shape: const CircleBorder(),
                ),
                child: profilePhoto(
                  size: 150,
                  profilePicUrl: state.viewingProfile?.picUrl ??
                      state.usersProfile?.picUrl,
                ),
              ),
            ),
          ],
        ),
      ),
      collapsedHeight: collapsedHeight,
      expandedHeight: expandedHeight,
      leading: state.viewingProfile != null
          ? IconButton(
              onPressed: homeCubit.goBackToUsersProfile,
              icon: const Icon(Icons.arrow_back),
            )
          : null,
      // title: _appbarTitle(state: state),
      actions: _appBarActions(
        iconSize: 24,
        state: state,
        isUser: isUser,
        isAuthorized: isAuthorized,
        usersProfile: usersProfile,
        homeCubit: homeCubit,
        context: context,
      ),
      
    );
  }

  String _appBarTitleString({required HomeState state}) {
    if (state.usersProfile != null) {
      return state.usersProfile!.name!;
    } else if (state.viewingProfile != null) {
      return 'Viewing: ${state.viewingProfile!.name!}';
    } else {
      return "Horse & Rider's Companion";
    }
  }

  Widget _appbarTitle({
    required HomeState state,
  }) {
    //if riderProfile is null --  Horse & Rider's Companion
    // if riderProfile is not null -- riderProfile.name
    // if viewingProfile is not null -- Viewing: viewingProfile.name

    if (state.usersProfile != null) {
      return AutoSizeText(state.usersProfile!.name!);
    } else if (state.viewingProfile != null) {
      return AutoSizeText('Viewing: ${state.viewingProfile!.name!}');
    } else {
      return const AutoSizeText("Horse & Rider's Companion");
    }
  }

  Widget _appBarBackground({
    required HomeState state,
  }) {
    return Container(
      alignment: AlignmentDirectional.bottomStart,
      margin: const EdgeInsets.only(top: 60),
      decoration: BoxDecoration(
        color: HorseAndRidersTheme().getTheme().appBarTheme.backgroundColor,
        image: const DecorationImage(
          image: AssetImage(
            'assets/horse_background.png',
          ),
          fit: BoxFit.fitHeight,
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
    final isGuest = state.usersProfile == null && state.viewingProfile == null;
    return SliverToBoxAdapter(
      child: isGuest
          ? SizedBox(
              height: MediaQuery.of(context).size.height,
              child: const Center(
                child: Text(
                  "Welcome to Horse & Rider's Companion",
                  style: TextStyle(
                    fontSize: 50,
                  ),
                ),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  gap(),
                  _riderLocation(
                    riderProfile: state.viewingProfile ?? state.usersProfile!,
                  ),
                  gap(),
                  _riderBio(
                    context: context,
                    riderProfile: state.viewingProfile ?? state.usersProfile!,
                  ),
                  gap(),
                  Center(
                    child: _websiteLink(
                      context: context,
                      riderProfile: state.viewingProfile ?? state.usersProfile!,
                    ),
                  ),
                  gap(),
                  Visibility(
                    visible: state.usersProfile != null,
                    child: Center(
                      child: _trainerQuestion(
                        context: context,
                        usersProfile: state.usersProfile!,
                        homeCubit: homeCubit,
                      ),
                    ),
                  ),
                  gap(),
                  Visibility(
                    visible: state.usersProfile != null,
                    child: Center(
                      child: Text(
                        state.usersProfile!.email.toString(),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  gap(),
                  _lists(
                    homeCubit: homeCubit,
                    context: context,
                    state: state,
                  ),
                  gap(),
                  // Log Book Button
                  Visibility(
                    visible: homeCubit.isAuthtorized(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(100, 0, 100, 0),
                      child: MaxWidthBox(
                        maxWidth: 350,
                        child: ElevatedButton(
                          onPressed: () => homeCubit.openLogBook(context),
                          child: Text(
                            S.of(context).log_book_text,
                          ),
                        ),
                      ),
                    ),
                  ),
                  gap(),
                ],
              ),
            ),
    );
  }

  Widget _lists({
    required HomeCubit homeCubit,
    required BuildContext context,
    required HomeState state,
  }) {
    // show the instuctor, student and horse list for the respective profile
    //if screen size is larget than a tablet then show the lists side by side
    // else show them in a column
    final isSmallScreen =
        ResponsiveBreakpoints.of(context).smallerThan(DESKTOP);
    if (isSmallScreen) {
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
                  child: AutoSizeText(
                    minFontSize: 20,
                    maxFontSize: 30,
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
                const AutoSizeText(
                  minFontSize: 20,
                  maxFontSize: 30,
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
                const AutoSizeText(
                  minFontSize: 20,
                  maxFontSize: 30,
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
                const AutoSizeText(
                  minFontSize: 20,
                  maxFontSize: 30,
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
    } else {
//large screen show the lists in a row
      return Row(
        children: [
          Visibility(
            visible: state.viewingProfile?.instructors?.isNotEmpty ??
                state.usersProfile!.instructors?.isNotEmpty ??
                false,
            child: Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: AutoSizeText(
                      minFontSize: 20,
                      maxFontSize: 30,
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
          ),
          smallGap(),
          //students
          Visibility(
            visible: state.viewingProfile?.students?.isNotEmpty ??
                state.usersProfile!.students?.isNotEmpty ??
                false,
            child: Expanded(
              child: Column(
                children: [
                  const AutoSizeText(
                    minFontSize: 20,
                    maxFontSize: 30,
                    'Students',
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
          ),
          gap(),
          Visibility(
            visible: state.viewingProfile?.ownedHorses?.isNotEmpty ??
                state.usersProfile!.ownedHorses?.isNotEmpty ??
                false,
            child: Expanded(
              child: Column(
                children: [
                  const AutoSizeText(
                    minFontSize: 20,
                    maxFontSize: 30,
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
          ),
          //student horses
          Visibility(
            visible: state.viewingProfile?.studentHorses?.isNotEmpty ??
                state.usersProfile!.studentHorses?.isNotEmpty ??
                false,
            child: Expanded(
              child: Column(
                children: [
                  const AutoSizeText(
                    minFontSize: 20,
                    maxFontSize: 30,
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
          ),
        ],
      );
    }
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
              onPressed: () => homeCubit.openAddHorseDialog(context: context),
              icon: const Icon(HorseAndRiderIcons.horseIconAdd),
            ),
          ),
          gap(),
        ],
        if (isUser &&
            ResponsiveBreakpoints.of(context).smallerOrEqualTo(TABLET))
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
                  homeCubit.openAddHorseDialog(context: context);
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
      debugPrint('Drawer: ${state.usersProfile!.name}');
      return Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              // margin: const EdgeInsets.only(top: 8, left: 8),
              decoration: BoxDecoration(
                color: HorseAndRidersTheme().getTheme().colorScheme.primary,
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
                state.usersProfile!.name ?? 'Guest',
              ),
              accountEmail: Text(
                state.usersProfile?.email ?? '',
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
              visible:
                  state.usersProfile?.savedProfilesList?.isNotEmpty ?? false,
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
                title: const Text('Owned Horeses'),
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
                title: const Text('Student Horeses'),
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
                context.read<HomeCubit>().searchClicked();
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
              title: const AutoSizeText(
                'Send Email to Support',
                maxFontSize: 20,
                minFontSize: 16,
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
          leading: profilePhoto(size: 45, profilePicUrl: baseItem.imageUrl),
          title: AutoSizeText(
            minFontSize: 16,
            maxFontSize: 20,
            baseItem.name ?? '',
            textAlign: TextAlign.center,
          ),
          onTap: () => baseItem.isCollapsed!
              ? homeCubit.gotoProfilePage(
                  context: context,
                  toBeViewedEmail: baseItem.id ?? '',
                )
              : context.read<HomeCubit>().horseSelected(
                    context: context,
                    // Otherwise we are selecting a horse
                    horseProfileId: baseItem.id ?? '',
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
        leading: profilePhoto(size: 45, profilePicUrl: baseItem.imageUrl),
        title: AutoSizeText(
          minFontSize: 16,
          maxFontSize: 20,
          baseItem.name ?? '',
          textAlign: TextAlign.center,
        ),
        onTap: () => baseItem.isCollapsed!
            ? homeCubit.gotoProfilePage(
                context: context,
                toBeViewedEmail: baseItem.id ?? '',
              )
            : context.read<HomeCubit>().horseSelected(
                  context: context,
                  // Otherwise we are selecting a horse
                  horseProfileId: baseItem.id ?? '',
                ),
      ),
    );
  }

  Widget _riderLocation({required RiderProfile riderProfile}) {
    return Center(
      child: AutoSizeText(
        riderProfile.locationName == null ? '' : '${riderProfile.locationName}',
        textAlign: TextAlign.center,
        maxFontSize: 30,
        minFontSize: 20,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _riderBio({
    required BuildContext context,
    required RiderProfile riderProfile,
  }) {
    return Visibility(
      visible: riderProfile.bio != null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: MaxWidthBox(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          child: AutoSizeText(
            maxFontSize: 30,
            minFontSize: 16,
            riderProfile.bio ?? '',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _websiteLink({
    required BuildContext context,
    required RiderProfile riderProfile,
  }) {
    return Visibility(
      visible: riderProfile.homeUrl != null,
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(riderProfile.homeUrl as String)),
        child: const AutoSizeText(
          'Website Link',
          maxFontSize: 30,
          minFontSize: 16,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _contactRequestButtons({
    required BuildContext context,
    required bool isUser,
    required HomeState state,
    required HomeCubit homeCubit,
  }) {
    final user = state.usersProfile;
    final riderProfile = state.viewingProfile;
    if (riderProfile != null) {
      final isStudent =
          user?.students?.any((element) => element.id == riderProfile.email) ??
              false;
      final isInstructor = user?.instructors
              ?.any((element) => element.id == riderProfile.email) ??
          false;

      var isContact = user?.savedProfilesList
              ?.any((element) => element.id == riderProfile.email) ??
          false;

      return Visibility(
        visible: !isUser,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) => Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () {
                          isStudent
                              ? homeCubit.removeStudent(
                                  studentProfile: riderProfile,
                                  context: context,
                                )
                              : homeCubit.createStudentRequest(
                                  studentProfile: riderProfile,
                                  context: context,
                                );
                        },
                        child: Text(
                          isStudent
                              ? 'Remove as a Student'
                              : 'Add as a Student',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () => setState(
                          () {
                            isContact
                                ? homeCubit.removeFromContacts(
                                    riderProfile: riderProfile,
                                    context: context,
                                  )
                                : homeCubit.addToContact(
                                    riderProfile: riderProfile,
                                    context: context,
                                  );
                            isContact = !isContact;
                            isContact = homeCubit.isContact();
                          },
                        ),
                        child: Text(
                          isContact ? 'Remove Contact' : 'Add To Contacts',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () {
                          isInstructor
                              ? homeCubit.removeInstructor(
                                  instructor: riderProfile,
                                  context: context,
                                )
                              : homeCubit.createInstructorRequest(
                                  instructorProfile: riderProfile,
                                  context: context,
                                );
                        },
                        child: Text(
                          isInstructor
                              ? 'Remove as an Instructor'
                              : 'Add as an Instructor',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox();
    }
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
    required RiderProfile usersProfile,
    required HomeCubit homeCubit,
  }) {
    bool showIsTrainer;
    if (usersProfile.isTrainer == null) {
      showIsTrainer = true;
    } else if (usersProfile.isTrainer == false) {
      showIsTrainer = false;
    } else {
      showIsTrainer = false;
    }

    return Visibility(
      visible: showIsTrainer,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Row(
          children: [
            const Expanded(
              flex: 6,
              child: AutoSizeText(
                'Are you a Trainer/Instructor?',
                maxFontSize: 30,
                minFontSize: 20,
              ),
            ),
            const AutoSizeText(
              'Yes',
              minFontSize: 20,
              maxFontSize: 30,
            ),
            Checkbox(
              value: false,
              onChanged: (value) => homeCubit.toggleIsTrainerState(
                isTrainer: true,
                context: context,
              ),
            ),
            const AutoSizeText(
              'No',
              minFontSize: 20,
              maxFontSize: 30,
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
}
