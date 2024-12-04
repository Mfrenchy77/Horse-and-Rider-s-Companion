// ignore_for_file: constant_identifier_names

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/onboarding_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/add_log_entry_dialog_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/keys.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';

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
    required this.onBoarding,
    required this.appContext,
  });

  final String name;
  final bool isRider;
  final bool onBoarding;
  final BuildContext appContext;
  final List<BaseListItem>? notes;

  @override
  LogViewDialogState createState() => LogViewDialogState();
}

class LogViewDialogState extends State<LogViewDialog> {
  // Initial sort option
  LogSort _selectedSortOption = LogSort.dateNewest;

  @override
  Widget build(BuildContext context) {
    final notes = widget.notes ?? [];
    if (widget.onBoarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog<Dialog>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return onboardingDialog(
              title: const Text(
                'Log Book',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
              description:
                  'This is the log book. You can view your progress and add new'
                  ' entries here for shows, training, health updates, or'
                  ' anything else you want to track.\n\n There is a log book'
                  ' if you have a horse that can be accessed from thier'
                  ' profile.',
              onNext: () {
                Navigator.of(context).pop(); 
               _logbookShowcase(context: context);
              },
              skipOnboarding: () =>
                  context.read<AppCubit>().completeOnboarding(),
            );
          },
        );
      });
    }
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
              gap(),
              _buildSortOption(),
              gap(),
              Expanded(
                child: _logBookList(
                  notes: notes,
                  isRider: widget.isRider,
                  sortOption: _selectedSortOption,
                ),
              ),
            ],
          ),
        ),
      ),
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
          Showcase(
            key: Keys.addLogEntryKey,
            description: 'Add a new log entry for this profile',
            disposeOnTap: false,
            onTargetClick: () => ShowCaseWidget.of(context).next(),
            onBarrierClick: () => ShowCaseWidget.of(context).next(),
            onToolTipClick: () => ShowCaseWidget.of(context).next(),
            child: const AddLogEntry(
              key: Key('AddLogEntry'),
            ),
          ),
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
          const AddLogEntry(
            key: Key('AddLogEntry'),
          ),
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
        Showcase(
          key: Keys.logSortKey,
          title: 'Sort Log Entries',
          description: 'Sort the log entries by date or tag',
          disposeOnTap: false,
          onTargetClick: () => ShowCaseWidget.of(context).next(),
          onBarrierClick: () => ShowCaseWidget.of(context).next(),
          onToolTipClick: () => ShowCaseWidget.of(context).next(),
          child: DropdownButton<LogSort>(
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
    return const Center(
      child: Text('No Entries in the Log'),
    );
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
      return const Center(
        child: Text('No Entries in the Log for this filter'),
      );
    }
  }
}

class AddLogEntry extends StatelessWidget {
  const AddLogEntry({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Showcase(
          disposeOnTap: false,
          key: Keys.addLogEntryKey,
          title: 'Add Log Entry',
          description: 'Add a new log entry for this profile',
          onTargetClick: () => ShowCaseWidget.of(context).next(),
          onBarrierClick: () => ShowCaseWidget.of(context).next(),
          onToolTipClick: () => ShowCaseWidget.of(context).next(),
          child: FilledButton.icon(
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
          ),
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
        title: Text(
          note.name ?? '',
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy').format(note.date ?? DateTime.now()),
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
    decoration: BoxDecoration(
      color: _logTagColor(tag: tag),
    ),
    child: Text(
      _logTagText(tag: tag),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

/// Enum representing the different log tags
enum LogTag {
  Show,
  Training,
  Health,
  Other,
  Edit,
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

void _logbookShowcase({required BuildContext context}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ShowCaseWidget.of(context).startShowCase([
      Keys.addLogEntryKey,
      Keys.logSortKey,
    ]);
  });
}
