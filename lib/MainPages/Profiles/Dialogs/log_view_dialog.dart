// ignore_for_file: constant_identifier_names

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:intl/intl.dart';

/// Enum representing the different sorting options
enum LogSort {
  dateNewest,
  dateOldest,
  tagEdit,
  tagShow,
  tagHealth,
  tagTraining,
  tagOther,
}

/// Dialog to view the log of a rider or horse with sorting functionality
class LogViewDialog extends StatefulWidget {
  const LogViewDialog({
    super.key,
    required this.name,
    required this.notes,
    required this.isRider,
    required this.appContext,
    this.horseId,
  });

  final String name;
  final bool isRider;
  final String? horseId;
  final BuildContext appContext;
  final List<BaseListItem>? notes;

  @override
  LogViewDialogState createState() => LogViewDialogState();
}

class LogViewDialogState extends State<LogViewDialog> {
  // Initial sort option
  LogSort _selectedSortOption = LogSort.dateNewest;

  String? _historyUid;
  Future<List<BaseListItem>>? _history;

  Future<List<BaseListItem>>? _historyFor(
    BuildContext context,
    AppState state,
  ) {
    final uid = state.isGuest ? null : state.user.id;
    if (_historyUid != uid) {
      _historyUid = uid;
      _history = uid == null || uid.isEmpty || widget.horseId == null
          ? null
          : context.read<ConnectionRepository?>()?.history({
              'action': 'horseHistory',
              'horseId': widget.horseId,
            });
    }
    return _history;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppCubit>().state;
    final horse = state.horseProfile;
    final rider = state.usersProfile;
    final currentHorse = widget.horseId != null && horse?.id == widget.horseId
        ? horse
        : null;
    final notes = [
      ...?(currentHorse == null ? widget.notes : currentHorse.notes),
      if (!state.isGuest &&
          rider != null &&
          currentHorse?.currentOwnerId.toLowerCase() ==
              rider.email.toLowerCase())
        ...?rider.notes?.where(
          (note) => note.riderLog?.horseId == widget.horseId,
        ),
    ];

    return FutureBuilder<List<BaseListItem>>(
      future: _historyFor(context, state),
      builder: (context, snapshot) {
        final shared =
            snapshot.connectionState == ConnectionState.done && !state.isGuest
            ? snapshot.data ?? const <BaseListItem>[]
            : const <BaseListItem>[];
        final ids = shared.map((note) => note.id).toSet();
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _logEntryTitle(
                    isRider: widget.isRider,
                    name: widget.name,
                    context: context,
                  ),
                  if (_history != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _historyUid = null),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh shared history'),
                    ),
                  gap(),
                  _buildSortOption(),
                  gap(),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const LinearProgressIndicator(),
                  if (snapshot.hasError)
                    TextButton(
                      onPressed: () => setState(() {
                        _historyUid = null;
                      }),
                      child: const Text('Shared history unavailable. Retry'),
                    ),
                  Expanded(
                    child: _logBookList(
                      notes: [
                        ...notes.where((note) => !ids.contains(note.id)),
                        ...shared,
                      ],
                      isRider: widget.isRider,
                      sortOption: _selectedSortOption,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _logEntryTitle({
    required bool isRider,
    required String name,
    required BuildContext context,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isSmallScreen = screenWidth <= 600;

    if (isSmallScreen) {
      // Layout for smaller screens - using Column
      return Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Close LogBook',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).textTheme.labelLarge?.color,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    "$name's Log",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const AddLogEntry(key: Key('AddLogEntry')),
        ],
      );
    } else {
      // Layout for larger screens - using Row
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: 'Close LogBook',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).textTheme.labelLarge?.color,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                "$name's Log",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const AddLogEntry(key: Key('AddLogEntry')),
        ],
      );
    }
  }

  Widget _buildSortOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Sort by:'),
        gap(),
        DropdownButton<LogSort>(
          value: _selectedSortOption,
          onChanged: (LogSort? newValue) {
            setState(() {
              _selectedSortOption = newValue!;
            });
          },
          items: LogSort.values.map((LogSort option) {
            return DropdownMenuItem<LogSort>(
              value: option,
              child: Text(_logSortToString(option)),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _logSortToString(LogSort sortOption) {
    switch (sortOption) {
      case LogSort.dateNewest:
        return 'Date (Newest)';
      case LogSort.dateOldest:
        return 'Date (Oldest)';
      case LogSort.tagShow:
        return 'Tag (Show)';
      case LogSort.tagTraining:
        return 'Tag (Training)';
      case LogSort.tagHealth:
        return 'Tag (Health)';
      case LogSort.tagOther:
        return 'Tag (Other)';
      case LogSort.tagEdit:
        return 'Tag (Edit)';
    }
  }
}

Widget _logBookList({
  required bool isRider,
  required List<BaseListItem> notes,
  required LogSort sortOption,
}) {
  if (notes.isEmpty) {
    return const Center(child: Text('No Entries in the Log'));
  } else {
    var sortedNotes = List<BaseListItem>.from(notes);

    // Implement sorting based on selected sort option
    switch (sortOption) {
      case LogSort.dateNewest:
        sortedNotes.sort(
          (a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)),
        );
        break;
      case LogSort.dateOldest:
        sortedNotes.sort(
          (a, b) => (a.date ?? DateTime(0)).compareTo(b.date ?? DateTime(0)),
        );
        break;
      case LogSort.tagShow:
        sortedNotes = sortedNotes
            .where(
              (note) => convertStringToLogTag(note.imageUrl) == LogTag.Show,
            )
            .toList();
        break;
      case LogSort.tagTraining:
        sortedNotes = sortedNotes
            .where(
              (note) => convertStringToLogTag(note.imageUrl) == LogTag.Training,
            )
            .toList();
        break;
      case LogSort.tagHealth:
        sortedNotes = sortedNotes
            .where(
              (note) => convertStringToLogTag(note.imageUrl) == LogTag.Health,
            )
            .toList();
        break;
      case LogSort.tagOther:
        sortedNotes = sortedNotes
            .where(
              (note) => convertStringToLogTag(note.imageUrl) == LogTag.Other,
            )
            .toList();
        break;
      case LogSort.tagEdit:
        sortedNotes = sortedNotes
            .where(
              (note) => convertStringToLogTag(note.imageUrl) == LogTag.Edit,
            )
            .toList();
    }

    if (sortedNotes.isNotEmpty) {
      return ListView.builder(
        itemCount: sortedNotes.length,
        itemBuilder: (context, index) {
          return _noteItem(note: sortedNotes[index]);
        },
      );
    } else {
      return const Center(child: Text('No Entries in the Log for this filter'));
    }
  }
}

class AddLogEntry extends StatelessWidget {
  const AddLogEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (!context.read<AppCubit>().canWriteProfileRecords() ||
            (!state.isForRider && (state.horseProfile?.isArchived ?? false))) {
          return const SizedBox.shrink();
        }
        return FilledButton.icon(
          label: const Text('Add Log Entry'),
          onPressed: () {
            showDialog<AddLogEntryDialog>(
              context: context,
              builder: (context) => AddLogEntryDialog(
                usersProfile: state.usersProfile!,
                horseProfile: state.isForRider ? null : state.horseProfile,
              ),
            );
          },
          icon: const Icon(Icons.add),
        );
      },
    );
  }
}

Widget _noteItem({required BaseListItem note}) {
  final tag = convertStringToLogTag(note.imageUrl);

  return ColoredBox(
    color: _logTagColor(tag: tag),
    child: ColoredBox(
      color: HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
      child: ListTile(
        title: Text(note.name ?? '', style: const TextStyle(fontSize: 16)),
        subtitle: Text(
          [
            DateFormat('MMM dd, yyyy').format(note.date ?? DateTime.now()),
            if (note.extra?.isNotEmpty ?? false) 'Rider: ${note.extra}',
            if (note.riderLog?.authorRole == 'instructor')
              'Added by instructor ${note.message ?? note.parentId ?? ''}',
            if (note.riderLog?.authorRole == 'trainer')
              'Added by trainer ${note.message ?? note.parentId ?? ''}',
          ].join('\n'),
          style: const TextStyle(color: Colors.grey),
        ),
        leading: _logTag(tag: tag),
      ),
    ),
  );
}

Widget _logTag({required LogTag? tag}) {
  return Container(
    width: 60, // Adjust the width as needed
    height: double.infinity,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: _logTagColor(tag: tag)),
    child: Text(
      _logTagText(tag: tag),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    ),
  );
}

/// Enum representing the different log tags
enum LogTag { Show, Training, Health, Other, Edit }

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

/// Returns text based on Log Tag
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

/// Returns a color based on the Log Tag
Color _logTagColor({required LogTag? tag}) {
  switch (tag) {
    case LogTag.Show:
      return Colors.blue;
    case LogTag.Edit:
      return Colors.green;
    case LogTag.Training:
      return Colors.orange;
    case LogTag.Health:
      return Colors.red;
    case LogTag.Other:
      return Colors.grey;
    case null:
      return Colors.grey;
  }
}
