// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/Cubit/add_log_entry_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:intl/intl.dart';

/// Dialog to view the log of a rider or horse
///
///
class LogViewDialog extends StatelessWidget {
  const LogViewDialog({
    super.key,
    required this.name,
    required this.notes,
    required this.isRider,
  });
  final String name;
  final bool isRider;
  final List<BaseListItem>? notes;
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: _logentryTitle(isRider: isRider, name: name),
          actions: const [
            AddLogEntry(
              key: Key('AddLogEntry'),
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
                  notes: notes,
                  isRider: isRider,
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

Widget logViewDialog({
  required BuildContext context,
  required String name,
  required List<BaseListItem>? notes,
  required bool isRider,
}) {
  return Dialog(
    child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: _logentryTitle(isRider: isRider, name: name),
        actions: const [
          AddLogEntry(
            key: Key('AddLogEntry'),
          ),
          Icon(Icons.person),
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
                notes: notes,
                isRider: isRider,
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

Widget _logentryTitle({required bool isRider, required String name}) {
  return Text(
    "$name's Log",
  );
}

class AddLogEntry extends StatelessWidget {
  const AddLogEntry({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (state.isForRider) {
          return IconButton(
            tooltip: 'Add Log Entry',
            onPressed: () {
              showDialog<AddLogEntryDialog>(
                context: context,
                builder: (context) => AddLogEntryDialog(
                  riderProfile: state.viewingProfile ?? state.usersProfile!,
                  horseProfile: null,
                ),
              );
            },
            icon: const Icon(Icons.add),
          );
        } else {
          return Tooltip(
            message: 'Add Log Entry',
            child: IconButton(
              tooltip: 'Add Log Entry',
              onPressed: () {
                showDialog<AddLogEntryDialog>(
                  context: context,
                  builder: (context) => AddLogEntryDialog(
                    riderProfile: state.usersProfile!,
                    horseProfile: state.horseProfile,
                  ),
                );
              },
              icon: const Icon(Icons.add),
            ),
          );
        }
      },
    );
  }
}

// Widget _addLogEntry({
//   required bool isRider,
// }) {
//   debugPrint('Is Rider: $isRider');
//   if (isRider) {
//     return BlocBuilder<RiderProfileCubit, RiderProfileState>(
//       builder: (context, state) {
//         return IconButton(
//           tooltip: 'Add Log Entry',
//           onPressed: () {
//             showDialog<AddLogEntryDialog>(
//               context: context,
//               builder: (context) => AddLogEntryDialog(
//                 riderProfile: state.viewingProfile ?? state.usersProfile!,
//                 horseProfile: null,
//               ),
//             );
//           },
//           icon: const Icon(Icons.add),
//         );
//       },
//     );
//   } else {
//     // TODO(mfrenchy77): Change this to HorseProfileCubit
//     return BlocBuilder<HomeCubit, HomeState>(
//       builder: (context, state) {
//         return IconButton(
//           tooltip: 'Add Log Entry',
//           onPressed: () {
//             showDialog<AddLogEntryDialog>(
//               context: context,
//               builder: (context) => AddLogEntryDialog(
//                 riderProfile: state.usersProfile!,
//                 horseProfile: state.horseProfile,
//               ),
//             );
//           },
//           icon: const Icon(Icons.add),
//         );
//       },
//     );
//   }
// }

Widget _logBookList({
  required bool isRider,
  required List<BaseListItem>? notes,
}) {
  if (notes != null || notes!.isNotEmpty) {
    notes.sort((a, b) => a.date?.compareTo(b.date as DateTime) ?? 0);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _noteItem(
          note: note,
        );
      },
    );
  } else {
    return const Text('No Entries in the Log');
  }
}

class LogBookListRider extends StatelessWidget {
  const LogBookListRider({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final profile = state.viewingProfile ?? state.usersProfile;
    final notes = profile?.notes;
    if (notes != null || notes!.isNotEmpty) {
      notes.sort((a, b) => a.date?.compareTo(b.date as DateTime) ?? 0);
      return ListView.builder(
        shrinkWrap: true,
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _noteItem(
            note: note,
          );
        },
      );
    } else {
      return const Text('No Entries in the Log');
    }
  }
}

// Widget _logBookListForRider() {
//   return BlocBuilder<RiderProfileCubit, RiderProfileState>(
//     builder: (context, state) {
//       final profile = state.viewingProfile ?? state.usersProfile;
//       final notes = profile?.notes;

//       if (notes != null || notes!.isNotEmpty) {
//         notes.sort((a, b) => a.date?.compareTo(b.date as DateTime) ?? 0);
//         return ListView.builder(
//           shrinkWrap: true,
//           itemCount: notes.length,
//           itemBuilder: (context, index) {
//             final note = notes[index];
//             return _noteItem(
//               note: note,
//             );
//           },
//         );
//       } else {
//         return const Text('No Entries in the Log');
//       }
//     },
//   );
// }

class LogBookListHorse extends StatelessWidget {
  const LogBookListHorse({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeCubit>().state;
    final profile = state.horseProfile;
    final notes = profile?.notes;

    if (notes != null || notes!.isNotEmpty) {
      notes.sort((a, b) => a.date?.compareTo(b.date as DateTime) ?? 0);
      return ListView.builder(
        shrinkWrap: true,
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _noteItem(
            note: note,
          );
        },
      );
    } else {
      return const Text('No Entries in the Log');
    }
  }
}

// Widget _logBookListForHorse() {
//   //TODO: Change this to HorseProfileCubit
//   return BlocBuilder<HomeCubit, HomeState>(
//     builder: (context, state) {
//       final profile = state.horseProfile;
//       final notes = profile?.notes;

//       if (notes != null || notes!.isNotEmpty) {
//         notes.sort((a, b) => a.date?.compareTo(b.date as DateTime) ?? 0);
//         return ListView.builder(
//           shrinkWrap: true,
//           itemCount: notes.length,
//           itemBuilder: (context, index) {
//             final note = notes[index];
//             return _noteItem(
//               note: note,
//             );
//           },
//         );
//       } else {
//         return const Text('No Entries in the Log');
//       }
//     },
//   );
// }

Widget _noteItem({
  required BaseListItem note,
}) {
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
                  _logTagChip(tagString: note.imageUrl),
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
/// return a chip with a color based on the Log Tag
Widget _logTagChip({required String? tagString}) {
  final tag = convertStringToLogTag(tagString);
  return Chip(
    avatar: _logTagIcon(tag: tag),
    label: Text(
      _logTagText(tag: tag),
      style: const TextStyle(color: Colors.white),
    ),
    backgroundColor: _logTagColor(tag: tag),
  );
}

LogTag convertStringToLogTag(String? tag) {
  switch (tag) {
    case 'LogTag.Show':
      return LogTag.Show;
    case 'LogTag.Training':
      return LogTag.Training;
    case 'LogTag.Health':
      return LogTag.Health;
    case 'LogTag.Other':
      return LogTag.Other;
    default:
      return LogTag.Other;
  }
}

/// returns a icon for an avatar based on the Log Tag
Icon _logTagIcon({required LogTag? tag}) {
  switch (tag) {
    case LogTag.Show:
      return const Icon(HorseAndRiderIcons.horseIcon);
    case LogTag.Training:
      return const Icon(HorseAndRiderIcons.horseSkillIcon);
    case LogTag.Health:
      return const Icon(Icons.local_hospital);
    case LogTag.Other:
      return const Icon(Icons.more_horiz);
    case null:
      return const Icon(HorseAndRiderIcons.horseIcon);
  }
}

/// returns text base on Log Tag
String _logTagText({required LogTag? tag}) {
  switch (tag) {
    case LogTag.Show:
      return 'Show';
    case LogTag.Training:
      return 'Training';
    case LogTag.Health:
      return 'Health';
    case LogTag.Other:
      return 'Other';
    case null:
      return 'Other';
  }
}

/// returns a color based on the Log Tag
Color _logTagColor({required LogTag? tag}) {
  switch (tag) {
    case LogTag.Show:
      return Colors.blue;
    case LogTag.Training:
      return Colors.green;
    case LogTag.Health:
      return Colors.red;
    case LogTag.Other:
      return Colors.grey;
    case null:
      return Colors.grey;
  }
}
