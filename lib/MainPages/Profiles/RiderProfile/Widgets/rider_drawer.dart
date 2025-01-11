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
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

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
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Sign out'),
                    onTap: cubit.logOutRequested,
                  ),
                  //Log Book List Tile
                  ListTile(
                    leading: const Icon(HorseAndRiderIcons.riderLogIcon),
                    title: const Text('Log Book'),
                    onTap: () => showDialog<AlertDialog>(
                      context: context,
                      builder: (dialogContext) => LogViewDialog(
                        appContext: context,
                        name: state.viewingProfile?.name ??
                            state.usersProfile!.name,
                        notes: state.viewingProfile?.notes ??
                            state.usersProfile!.notes,
                        isRider: true,
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
                      Navigator.pop(context);
                      //opens the messages page
                      context.goNamed(MessagesPage.name);
                    },
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
