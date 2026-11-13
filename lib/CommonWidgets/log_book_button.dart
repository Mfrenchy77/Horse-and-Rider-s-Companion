import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/log_view_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/rider_logbook_page.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

///{@template log_book_button}
///LogBookButton widget displays the buttons to open the
///log book and add an entry
///{@endtemplate}
class LogBookButton extends StatelessWidget {
  ///{@macro log_book_button}
  ///Displays the buttons to open the log book and add an entry
  ///{@macro key}
  const LogBookButton({
    super.key,
    required this.profile,
    required this.horseProfile,
  });
  final RiderProfile? profile;
  final HorseProfile? horseProfile;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.isGuest != current.isGuest ||
          previous.usersProfile != current.usersProfile ||
          previous.viewingProfile != current.viewingProfile ||
          previous.horseProfile != current.horseProfile ||
          previous.isViewing != current.isViewing ||
          previous.isForRider != current.isForRider,
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        if (horseProfile == null) {
          return !state.isGuest &&
                  profile?.email == state.usersProfile?.email &&
                  state.usersProfile != null
              ? FilledButton.tonalIcon(
                  onPressed: () => RiderLogbookPage.open(context),
                  icon: const Icon(HorseAndRiderIcons.riderLogIcon),
                  label: const Text("Rider's Log Book"),
                )
              : const SizedBox.shrink();
        }

        return !cubit.isAuthorized() || state.isGuest
            ? const SizedBox.shrink()
            : Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tooltip(
                    message: 'Open the Log Book',
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        showAppDialog<Dialog>(
                          context: context,
                          builder: (dialogContext) => LogViewDialog(
                            appContext: context,
                            name: horseProfile!.name,
                            horseId: horseProfile!.id,
                            notes: horseProfile!.notes,
                            isRider: false,
                          ),
                        );
                      },
                      icon: const Icon(HorseAndRiderIcons.riderLogIcon),
                      label: const Text("Horse's Log Book"),
                    ),
                  ),
                  if (!horseProfile!.isArchived &&
                      cubit.canWriteProfileRecords())
                    IconButton(
                      tooltip: 'Add an Entry into the Log',
                      onPressed: () {
                        showAppDialog<AddLogEntryDialog>(
                          context: context,
                          builder: (context) => AddLogEntryDialog(
                            usersProfile: cubit.state.usersProfile!,
                            horseProfile: horseProfile,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                    ),
                ],
              );
      },
    );
  }
}
