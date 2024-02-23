// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/HorseProfile/view/add_log_entry_dialog_view.dart';
import 'package:intl/intl.dart';

class LogView extends StatelessWidget {
  const LogView({
    super.key,
    required this.state,
    required this.cubit,
    required this.isRider,
  });

  final bool isRider;
  final HomeState state;
  final HomeCubit cubit;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            isRider
                ? "${state.viewingProfile?.name ?? state.usersProfile?.name}'s "
                    'Log'
                : "${state.horseProfile?.name}'s Log",
          ),
          actions: [
            Row(
              children: [
                Tooltip(
                  message: 'Add Log Entry',
                  child: IconButton(
                    tooltip: 'Add Log Entry',
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
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _logBookList(
                  cubit: cubit,
                  horseProfile: state.horseProfile,
                  isRider: isRider,
                  context: context,
                  profile: state.viewingProfile ?? state.usersProfile!,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _logBookList({
  required bool isRider,
  required HomeCubit cubit,
  required BuildContext context,
  required RiderProfile? profile,
  required HorseProfile? horseProfile,
}) {
  final notes = isRider ? profile?.notes : horseProfile?.notes;

  if (notes != null || notes!.isNotEmpty) {
    notes.sort((a, b) => a.date?.compareTo(b.date as DateTime) ?? 0);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _noteItem(
          cubit: cubit,
          note: note,
        );
      },
    );
  } else {
    return const Text('No Entries in the Log');
  }
}

Widget _noteItem({
  required HomeCubit cubit,
  required BaseListItem note,
}) {
  debugPrint('Message length: ${note.name?.length}');
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                DateFormat('MM/dd/yy').format(note.date ?? DateTime.now()),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cubit.logTagChip(tagString: note.imageUrl),
                  const SizedBox(height: 8),
                  Text(
                    note.name ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const Divider(
        thickness: 1,
        color: Colors.black,
      ),
    ],
  );
}

//   return Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       IntrinsicHeight(
//         child: Row(
//           children: [
//             Expanded(
//               flex: 2,
//               child: Center(
//                 child: Text(
//                   DateFormat('MM/dd/yy').format(note.date ?? DateTime.now()),
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               ),
//             ),
//             VerticalDivider(
//               thickness: 2,
//               color: isDark ? Colors.white : Colors.black,
//             ),
//             Expanded(
//               flex: 7,
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Row(
//                   children: [
//                     cubit.logTagChip(tagString: note.imageUrl),
//                     smallGap(),
//                     Expanded(
//                       child: Text(
//                         note.name ?? '',
//                         textAlign: TextAlign.start,
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ],
//   );
// }
