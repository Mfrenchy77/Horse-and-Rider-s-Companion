import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/seasonal_decoration.dart';
import 'package:horseandriderscompanion/MainPages/About/about_page.dart';
import 'package:horseandriderscompanion/MainPages/Delete/delete_page.dart';
import 'package:horseandriderscompanion/MainPages/Privacy%20Policy/privacy_policy_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/ProfileSearchDialog/profile_search_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/support_message_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/profile_list.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class UserProfileDrawer extends StatelessWidget {
  const UserProfileDrawer({super.key, this.onClose, this.iconAnimation});

  final VoidCallback? onClose;
  final Animation<double>? iconAnimation;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final email = state.usersProfile?.email ?? '';
        final content = ListView(
            children: [
              Stack(
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
                        color: SharedPrefs().isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    accountEmail: Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: email,
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        if (SharedPrefs().isSeasonalMode())
                          const Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: 8,
                              end: 12,
                            ),
                            child: SeasonalDecorationWidget(),
                          ),
                      ],
                    ),
                  ),
                  // Positioned close button in the top-right of the header
                  Positioned(
                    right: 8,
                    top: 8,
                    child: SafeArea(
                      child: Hero(
                        tag: 'drawer-hamburger-x',
                        flightShuttleBuilder:
                            (
                              BuildContext flightContext,
                              Animation<double> animation,
                              HeroFlightDirection flightDirection,
                              BuildContext fromHeroContext,
                              BuildContext toHeroContext,
                            ) {
                              final iconSize =
                                  IconTheme.of(flightContext).size ?? 24.0;
                              final iconColor = IconTheme.of(
                                flightContext,
                              ).color;
                              return Center(
                                child: IconTheme(
                                  data: IconThemeData(
                                    size: iconSize,
                                    color: iconColor,
                                  ),
                                  child: AnimatedIcon(
                                    icon: AnimatedIcons.menu_close,
                                    progress: animation,
                                  ),
                                ),
                              );
                            },
                        child: IconButton(
                          icon: AnimatedIcon(
                            icon: AnimatedIcons.menu_close,
                            progress:
                                iconAnimation ??
                                const AlwaysStoppedAnimation(1),
                          ),
                          tooltip: 'Close drawer',
                          onPressed:
                              onClose ??
                              () => Scaffold.maybeOf(context)?.closeDrawer(),
                        ),
                      ),
                    ),
                  ),
                ],
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
                    onTap: () => RiderLogbookPage.open(context),
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
                        ProfileList(list: state.usersProfile?.students ?? []),
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
                      showAppGlassDialog<void>(
                        context: context,
                        builder: (dialogContext) => ProfileSearchDialog(
                          homeContext: context,
                          key: const Key('ProfileSearchDialog'),
                        ),
                      );

                      debugPrint('Search Clicked');
                    },
                  ),
                  Divider(
                    color: SharedPrefs().isDarkMode
                        ? Colors.white
                        : Colors.black,
                    height: 10,
                    thickness: 1,
                  ),

                  // Settings
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      onClose?.call();
                      context.goNamed(SettingsView.name);
                    },
                  ),

                  // Tutorial (Onboarding)
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text('Tutorial'),
                    onTap: () {
                      onClose?.call();
                      context.read<AppCubit>().showOnboardingNow();
                    },
                  ),

                  // About
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    onTap: () {
                      onClose?.call();
                      context.goNamed(AboutPage.name);
                    },
                  ),
                  smallGap(),

                  // Email Support
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Send Email to Support'),
                    onTap: () {
                      debugPrint('Send Email to Support');
                      onClose?.call();

                      showAppGlassDialog<SupportMessageDialog>(
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
                    onPressed: () {
                      onClose?.call();
                      context.goNamed(DeletePage.name);
                    },
                    child: const Text('Delete Account'),
                  ),
                  smallGap(),
                  // Privacy Policy
                  TextButton(
                    onPressed: () {
                      onClose?.call();
                      context.goNamed(PrivacyPolicyPage.name);
                    },
                    child: const Text('Privacy Policy'),
                  ),
                ],
              ),
            ],
          );
        final gradients = Theme.of(context).extension<SurfaceGradients>();
        return Drawer(
          child: gradients != null
              ? Ink(
                  decoration: BoxDecoration(gradient: gradients.surface),
                  child: content,
                )
              : content,
        );
      },
    );
  }
}
