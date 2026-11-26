import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Administration/administration_page.dart';
import 'package:horseandriderscompanion/MainPages/Invitations/invite_share_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Invitations/manage_invitations_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/profile_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/add_horse_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';

class RiderProfileOverFlowMenu extends StatelessWidget {
  const RiderProfileOverFlowMenu({super.key, this.menuController});

  final MenuController? menuController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (state.usersProfile == null) {
          return const SizedBox();
        }
        return ValueListenableBuilder<bool>(
          valueListenable: ProfileSpotlightTour.isTourActive,
          builder: (context, tourActive, _) => MenuAnchor(
            controller: menuController,
            menuChildren: [
              MenuItemButton(
                key: tourActive
                    ? ProfileSpotlightTour.editProfileMenuItemKey
                    : const Key('overflowEditProfileItem'),
                onPressed: () {
                  if (tourActive) return;
                  showAppGlassDialog<EditRiderProfileDialog>(
                    context: context,
                    builder: (context) => EditRiderProfileDialog(
                      onProfileUpdated: () {},
                      riderProfile: state.usersProfile,
                    ),
                  );
                },
                child: const Text('Edit Profile'),
              ),
              MenuItemButton(
                onPressed: () {
                  if (tourActive) return;
                  RiderLogbookPage.open(context);
                },
                child: const Text('Log Book'),
              ),
              MenuItemButton(
                onPressed: () {
                  if (tourActive) return;
                  if (state.usersProfile != null) {
                    showAppGlassDialog<AddHorseDialog>(
                      context: context,
                      builder: (context) => AddHorseDialog(
                        horseProfile: null,
                        userProfile: state.usersProfile!,
                        editProfile: false,
                      ),
                    );
                  } else {
                    AppLogger.warning(
                      LogCategory.profile,
                      'Cannot add horse: user profile is null',
                    );
                  }
                },
                child: const Text('Add Horse'),
              ),
              if (state.usersProfile?.isTrainer ?? false)
                MenuItemButton(
                  key: const Key('overflowInviteStudentItem'),
                  onPressed: () {
                    if (tourActive) return;
                    InviteShareDialog.show(
                      context,
                      initialType: InvitationType.studentConnection,
                    );
                  },
                  child: const Text('Invite Student'),
                ),
              MenuItemButton(
                key: const Key('overflowInviteSomeoneItem'),
                onPressed: () {
                  if (tourActive) return;
                  InviteShareDialog.show(context);
                },
                child: const Text('Invite Someone'),
              ),
              MenuItemButton(
                key: const Key('overflowManageInvitationsItem'),
                onPressed: () {
                  if (tourActive) return;
                  ManageInvitationsDialog.show(context);
                },
                child: const Text('Manage Invitations'),
              ),
              if (state.canAccessAdministration)
                MenuItemButton(
                  key: const Key('overflowAdministrationItem'),
                  onPressed: () {
                    if (tourActive) return;
                    if (state.canAccessAdministration) {
                      context.goNamed(AdministrationPage.name);
                    }
                  },
                  child: const Text('Administration'),
                ),
              MenuItemButton(
                onPressed: () {
                  if (tourActive) return;
                  context.goNamed(SettingsView.name);
                },
                child: const Text('Settings'),
              ),
              MenuItemButton(
                onPressed: () {
                  if (tourActive) return;
                  context.read<AppCubit>().logOutRequested();
                },
                child: const Text('Log Out'),
              ),
            ],
            builder: (context, controller, child) => IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
            ),
          ),
        );
      },
    );
  }
}
