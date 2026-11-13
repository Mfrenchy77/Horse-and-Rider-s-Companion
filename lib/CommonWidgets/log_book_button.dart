import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
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
    this.studentConnection,
    this.saving = false,
  });
  final RiderProfile? profile;
  final HorseProfile? horseProfile;
  final CoachingConnection? studentConnection;
  final bool saving;
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
          final rider = state.usersProfile;
          final target = profile;
          if (state.isGuest || rider == null || target == null) {
            return const SizedBox.shrink();
          }
          final student = studentConnection;
          final ownProfile = target.email == rider.email;
          if (!ownProfile &&
              (student == null ||
                  student.kind != 'rider' ||
                  student.status != 'accepted' ||
                  student.learner != target.email.toLowerCase() ||
                  student.coach != rider.email.toLowerCase())) {
            return const SizedBox.shrink();
          }

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: ownProfile
                    ? () => RiderLogbookPage.open(context)
                    : () => ConnectionPanel.openHistory(context, student!),
                icon: const Icon(HorseAndRiderIcons.riderLogIcon),
                label: Text(
                  ownProfile ? "Rider's Log Book" : 'Student logbook',
                ),
              ),
              FilledButton.icon(
                onPressed: saving
                    ? null
                    : ownProfile
                    ? () => RiderLogbookPage.addEntry(context)
                    : () => RiderLogbookPage.addLessonFor(context, student!),
                icon: const Icon(Icons.add),
                label: Text(ownProfile ? 'Add entry' : 'Add lesson record'),
              ),
            ],
          );
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
                        Navigator.of(context, rootNavigator: true).push<void>(
                          MaterialPageRoute(
                            builder: (_) => LogViewDialog(
                              name: horseProfile!.name,
                              horseId: horseProfile!.id,
                              horseProfile: horseProfile,
                              notes: horseProfile!.notes,
                              isRider: false,
                              appContext: context,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(HorseAndRiderIcons.riderLogIcon),
                      label: const Text("Horse's Log Book"),
                    ),
                  ),
                  if (!horseProfile!.isArchived &&
                      cubit.canWriteProfileRecords())
                    FilledButton.icon(
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
                      label: const Text('Add entry'),
                    ),
                ],
              );
      },
    );
  }
}
