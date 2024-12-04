import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/seasonal_decoration.dart';
import 'package:horseandriderscompanion/MainPages/About/about_page.dart';
import 'package:horseandriderscompanion/MainPages/Delete/delete_page.dart';
import 'package:horseandriderscompanion/MainPages/Messages/messages_list_page.dart';
import 'package:horseandriderscompanion/MainPages/Privacy%20Policy/privacy_policy_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/ProfileSearchDialog/profile_search_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/log_view_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/support_message_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_list.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/keys.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:showcaseview/showcaseview.dart';

class UserProfileDrawer extends StatelessWidget {
  const UserProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
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
                    color:
                        SharedPrefs().isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                accountEmail: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        state.usersProfile?.email ?? '',
                        style: TextStyle(
                          color: SharedPrefs().isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                    if (SharedPrefs().isSeasonalMode())
                      const SeasonalDecorationWidget()
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              Column(
                children: [
                  ///   Sign Out
                  Showcase(
                    tooltipBackgroundColor: Colors.blue,
                    descTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                    key: Keys.logoutKey,
                    description: 'Click here to sign out of your account',
                    onTargetClick: () => ShowCaseWidget.of(context).next(),
                    onToolTipClick: () => ShowCaseWidget.of(context).next(),
                    onBarrierClick: () => ShowCaseWidget.of(context).next(),
                    disposeOnTap: false,
                    child: ListTile(
                      leading: const Icon(Icons.close),
                      title: const Text('Sign out'),
                      onTap: cubit.logOutRequested,
                    ),
                  ),
                  //Log Book List Tile
                  Showcase(
                    tooltipBackgroundColor: Colors.blue,
                    descTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                    key: Keys.logBookKey,
                    description: 'Here is your log book, which you can use to'
                        ' see changes you have made and also use it to track '
                        "shows, training and more\n\n Let's get opening it up"
                        " and explore what's inside",
                    onTargetClick: () => _showlogBookOnboarding(
                      context: context,
                      state: state,
                    ),
                    onToolTipClick: () => _showlogBookOnboarding(
                      context: context,
                      state: state,
                    ),
                    onBarrierClick: () => _showlogBookOnboarding(
                      context: context,
                      state: state,
                    ),
                    disposeOnTap: true,
                    child: ListTile(
                      leading: const Icon(HorseAndRiderIcons.riderLogIcon),
                      title: const Text('Log Book'),
                      onTap: () => showDialog<AlertDialog>(
                        context: context,
                        builder: (dialogContext) => LogViewDialog(
                          appContext: context,
                          onBoarding: state.showOnboarding,
                          name: state.viewingProfile?.name ??
                              state.usersProfile!.name,
                          notes: state.viewingProfile?.notes ??
                              state.usersProfile!.notes,
                          isRider: true,
                        ),
                      ),
                    ),
                  ),

                  //  saved profile list
                  Visibility(
                    visible:
                        state.usersProfile?.savedProfilesList?.isNotEmpty ??
                            false,
                    child: ExpansionTile(
                      leading: const Icon(Icons.people_alt),
                      title: const Text('Contacts'),
                      children: [
                        ProfileList(
                          list: state.usersProfile?.savedProfilesList ?? [],
                        ),
                      ],
                    ),
                  ),

                  // saved instructor list
                  Visibility(
                    visible:
                        state.usersProfile?.instructors?.isNotEmpty ?? false,
                    child: ExpansionTile(
                      leading: const Icon(Icons.people_alt),
                      title: const Text('Instructors'),
                      children: [
                        ProfileList(
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
                        ProfileList(
                          list: state.usersProfile?.students ?? [],
                        ),
                      ],
                    ),
                  ),

                  Visibility(
                    visible:
                        state.usersProfile?.ownedHorses?.isNotEmpty ?? false,
                    child: ExpansionTile(
                      leading: const Icon(HorseAndRiderIcons.horseIcon),
                      title: const Text('Owned Horses'),
                      children: [
                        ProfileList(
                          list: state.usersProfile?.ownedHorses ?? [],
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible:
                        state.usersProfile?.studentHorses?.isNotEmpty ?? false,
                    child: ExpansionTile(
                      leading: const Icon(HorseAndRiderIcons.horseIcon),
                      title: const Text('Student Horses'),
                      children: [
                        ProfileList(
                          list: state.usersProfile?.studentHorses ?? [],
                        ),
                      ],
                    ),
                  ),

                  Showcase(
                    tooltipBackgroundColor: Colors.blue,
                    descTextStyle: const TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 1),
                    ),
                    disposeOnTap: false,
                    key: Keys.profileSearchKey,
                    description:
                        "Click here to search for a horse or rider's profile",
                    onTargetClick: () {
                      showDialog<AlertDialog>(
                        context: context,
                        builder: (dialogContext) => ProfileSearchDialog(
                          homeContext: context,
                          key: const Key('ProfileSearchDialog'),
                        ),
                      );
                      // ShowCaseWidget.of(context).next();
                    },
                    onToolTipClick: () {
                      showDialog<AlertDialog>(
                        context: context,
                        builder: (dialogContext) => ProfileSearchDialog(
                          homeContext: context,
                          key: const Key('ProfileSearchDialog'),
                        ),
                      );
                      // ShowCaseWidget.of(context).next();
                    },
                    onBarrierClick: () {
                      showDialog<AlertDialog>(
                        context: context,
                        builder: (dialogContext) => ProfileSearchDialog(
                          homeContext: context,
                          key: const Key('ProfileSearchDialog'),
                        ),
                      );
                      // ShowCaseWidget.of(context).next();
                    },
                    child: ListTile(
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
                  ),
                  Showcase(
                    tooltipBackgroundColor: Colors.blue,
                    descTextStyle: const TextStyle(
                      color: Colors.white,
                    ),
                    description: 'Here is where you will find message that you '
                        'have sent or received from other users',
                    key: Keys.messagesKey,
                    onTargetClick: () {
                      context.goNamed(MessagesPage.name);
                      ShowCaseWidget.of(context).next();
                    },
                    onToolTipClick: () {
                      context.goNamed(MessagesPage.name);
                      ShowCaseWidget.of(context).next();
                    },
                    onBarrierClick: () {
                      context.goNamed(MessagesPage.name);
                      ShowCaseWidget.of(context).next();
                    },
                    disposeOnTap: false,
                    child: ListTile(
                      leading: const Icon(Icons.mail),
                      title: const Text('Messages'),
                      onTap: () {
                        //closes the drawer
                        Navigator.pop(context);
                        //opens the messages page
                        context.goNamed(MessagesPage.name);
                      },
                    ),
                  ),

                  Divider(
                    color:
                        SharedPrefs().isDarkMode ? Colors.white : Colors.black,
                    height: 10,
                    thickness: 1,
                  ),

// Settings
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      //closes the drawer
                      Navigator.pop(context);
                      //opens the settings page
                      context.goNamed(SettingsView.name);
                    },
                  ),

                  // About
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    onTap: () {
                      //closes the drawer
                      Navigator.pop(context);
                      //opens the about page
                      context.goNamed(AboutPage.name);
                    },
                  ),
                  smallGap(),

                  // Email Support
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

                      showDialog<SupportMessageDialog>(
                        context: context,
                        builder: (dialogContext) => const SupportMessageDialog(
                          key: Key('SupportMessageDialog'),
                        ),
                      );
                    },
                  ),
                  smallGap(),
                  // Delte Account
                  TextButton(
                    onPressed: () => context.goNamed(DeletePage.name),
                    child: const Text('Delete Account'),
                  ),
                  smallGap(),
                  // Privacy Policy
                  TextButton(
                    onPressed: () {
                      //closes the drawer
                      Navigator.pop(context);
                      //opens the privacy policy page
                      context.goNamed(PrivacyPolicyPage.name);
                    },
                    child: const Text('Privacy Policy'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showlogBookOnboarding({
  required BuildContext context,
  required AppState state,
}) {
  showDialog<AlertDialog>(
    context: context,
    builder: (context) => ShowCaseWidget(
      builder: (dialogContext) => LogViewDialog(
        appContext: context,
        onBoarding: state.showOnboarding,
        name: state.viewingProfile?.name ?? state.usersProfile!.name,
        notes: state.viewingProfile?.notes ?? state.usersProfile!.notes,
        isRider: true,
      ),
    ),
  );
}
