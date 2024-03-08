import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/log_view_dialog.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

///{@template log_book_button}
///LogBookButton widget displays the buttons to open the
///log book and add an entry
///{@endtemplate}
class LogBookButton extends StatelessWidget {
  ///{@macro log_book_button}
  ///Displays the buttons to open the log book and add an entry
  ///{@macro key}
  const LogBookButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return Visibility(
          visible: !state.isGuest,
          child: Visibility(
            visible: cubit.isAuthorized(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Open the Log Book',
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog<AlertDialog>(
                        context: context,
                        builder: (context) => LogViewDialog(
                          name: state.isForRider
                              ? state.viewingProfile?.name ??
                                  state.usersProfile!.name
                              : state.horseProfile?.name ?? '',
                          notes: state.isForRider
                              ? state.viewingProfile?.notes ??
                                  state.usersProfile!.notes
                              : state.horseProfile?.notes,
                          isRider: state.isForRider,
                        ),
                      );
                    },
                    icon: const Icon(
                      HorseAndRiderIcons.riderLogIcon,
                    ),
                    label: Text(
                      state.isForRider
                          ? "Rider's Log Book"
                          : "Horse's Log Book",
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add an Entry into the Log',
                  onPressed: () {
                    showDialog<AddLogEntryDialog>(
                      context: context,
                      builder: (context) => AddLogEntryDialog(
                        riderProfile:
                            state.viewingProfile ?? state.usersProfile!,
                        horseProfile: state.horseProfile,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
