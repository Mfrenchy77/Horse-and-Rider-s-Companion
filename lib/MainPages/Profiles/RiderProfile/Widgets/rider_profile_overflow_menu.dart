import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/add_horse_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/log_view_dialog.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';

class RiderProfileOverFlowMenu extends StatelessWidget {
  const RiderProfileOverFlowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (state.usersProfile != null) {
          return PopupMenuButton<int>(
            itemBuilder: (context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(
                value: 0,
                child: Text('Edit Profile'),
              ),
              const PopupMenuItem<int>(
                value: 3,
                child: Text('Log Book'),
              ),
              const PopupMenuItem<int>(
                value: 4,
                child: Text('Add Horse'),
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Text('Settings'),
              ),
              const PopupMenuItem<int>(
                value: 2,
                child: Text('Log Out'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 0:
                  // Navigate to the edit profile page
                  showDialog<EditRiderProfileDialog>(
                    context: context,
                    builder: (context) => EditRiderProfileDialog(
                      onProfileUpdated: () {},
                      riderProfile: state.usersProfile,
                    ),
                  );
                  break;
                case 1:
                  // Navigate to the settings page
                  context.goNamed(SettingsView.name);
                  break;
                case 2:
                  // Log out
                  break;
                case 3:
                  // Navigate to the log book page
                  showDialog<AlertDialog>(
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
                  );
                  break;
                case 4:
                  // Navigate to the add horse page
                  if (state.usersProfile != null) {
                    showDialog<AddHorseDialog>(
                      context: context,
                      builder: (context) => AddHorseDialog(
                        horseProfile: null,
                        userProfile: state.usersProfile!,
                        editProfile: false,
                      ),
                    );
                  } else {
                    debugPrint('Can not add horse, user profile is null');
                  }
                  break;
              }
            },
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
