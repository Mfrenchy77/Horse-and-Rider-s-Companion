import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
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
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        debugPrint('Is Authorized to view Log Book: '
            '${context.read<AppCubit>().isAuthorized()}');
        return !cubit.isAuthorized() || state.isGuest
            ? const SizedBox.shrink()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Open the Log Book',
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        showDialog<Dialog>(
                          
                          context: context,
                          builder: (context) => LogViewDialog(
                            name: horseProfile?.name ?? profile?.name ?? '',
                            notes: horseProfile?.notes ?? profile?.notes,
                            isRider: horseProfile == null,
                          ),
                        );
                      },
                      icon: const Icon(
                        HorseAndRiderIcons.riderLogIcon,
                      ),
                      label: Text(
                        horseProfile == null
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
                          usersProfile: cubit.state.usersProfile!,
                          horseProfile: horseProfile,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                    ),
                  ),
                ],
              );
      },
    );
  }
}
