// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
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
    return Scaffold(
      backgroundColor: Colors.transparent,
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
        child: Center(
          child: MaxWidthBox(
            maxWidth: 800,
            child: Card(
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
        ),
      ),
    );
  }
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
                  usersProfile: state.usersProfile!,
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
                    usersProfile: state.usersProfile!,
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

Widget _logBookList({
  required bool isRider,
  required List<BaseListItem>? notes,
}) {
  if (notes != null || notes!.isNotEmpty) {
    notes.sort((a, b) => b.date!.compareTo(a.date!));
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
    final notes = profile!.notes
      ?..sort((a, b) => a.date?.compareTo(b.date as DateTime) ?? 0);
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

class LogBookListHorse extends StatelessWidget {
  const LogBookListHorse({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final profile = state.horseProfile;
        final notes = profile!.notes
          ?..sort((a, b) => a.date?.compareTo(b.date as DateTime) ?? 0);

        if (notes != null || notes!.isNotEmpty) {
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
      },
    );
  }
}

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

/// return a chip with a color based on the Log Tag
Widget _logTagChip({required String? tagString}) {
  final tag = convertStringToLogTag(tagString);
  return Chip(
    avatar: _logTagIcon(tag: tag),
    label: Text(
      _logTagText(tag: tag),
      style: TextStyle(
        color: tag == LogTag.Training ? Colors.black54 : Colors.white,
      ),
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
    case 'LogTag.Edit':
      return LogTag.Edit;
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
    case LogTag.Edit:
      return const Icon(Icons.edit);
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
    case LogTag.Edit:
      return 'Edit';
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
    case LogTag.Edit:
      return Colors.green;
    case LogTag.Training:
      return Colors.yellow;
    case LogTag.Health:
      return Colors.red;
    case LogTag.Other:
      return Colors.grey;
    case null:
      return Colors.grey;
  }
}
