import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Profile/Dialogs/AddLogEntryDialog/Cubit/add_log_entry_cubit.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:intl/intl.dart';

class AddLogEntryDialog extends StatelessWidget {
  const AddLogEntryDialog({
    super.key,
    required this.riderProfile,
    required this.horseProfile,
  });
  final RiderProfile riderProfile;
  final HorseProfile? horseProfile;
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => HorseProfileRepository(),
        ),
        RepositoryProvider(
          create: (context) => RiderProfileRepository(),
        ),
      ],
      child: BlocProvider(
        create: (context) => AddLogEntryCubit(
          riderProfileRepository: context.read<RiderProfileRepository>(),
          horseProfileRepository: context.read<HorseProfileRepository>(),
        ),
        child: BlocBuilder<AddLogEntryCubit, AddLogEntryState>(
          builder: (context, state) {
            if (state.status == FormzStatus.submissionSuccess) {
              Navigator.of(context).pop();
            }
            return AlertDialog(
              titlePadding: const EdgeInsets.all(10),
              title: Text(
                'Add New Log Entry For \n'
                '${horseProfile?.name ?? riderProfile.name}',
                textAlign: TextAlign.center,
              ),
              insetPadding: const EdgeInsets.all(10),
              scrollable: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EventDate(
                    state: state,
                    context: context,
                    horseProfile: horseProfile,
                    addLogEntryCubit: context.read<AddLogEntryCubit>(),
                  ),
                  gap(),
                  _logTag(context: context, state: state),
                  gap(),
                  _logEntry(
                    state: state,
                    context: context,
                    rider: riderProfile,
                    horseProfile: horseProfile,
                  ),
                  gap(),
                  Visibility(
                    visible: state.status.isSubmissionFailure,
                    child: const ColoredBox(
                      color: Colors.red,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Error With Submission'),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                _submitButton(
                  context: context,
                  state: state,
                  riderProfile: riderProfile,
                  horseProfile: horseProfile,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

///   Date the Event Occured
class EventDate extends StatefulWidget {
  const EventDate({
    super.key,
    required this.context,
    required this.state,
    required this.addLogEntryCubit,
    required this.horseProfile,
  });

  final BuildContext context;
  final AddLogEntryState state;
  final AddLogEntryCubit addLogEntryCubit;
  final HorseProfile? horseProfile;

  @override
  EventDateState createState() => EventDateState();
}

class EventDateState extends State<EventDate> {
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    dateController = TextEditingController(
      text: DateFormat('MMMM dd yyyy').format(widget.state.date),
    );
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddLogEntryCubit, AddLogEntryState>(
      builder: (context, state) {
        return TextFormField(
          readOnly: true,
          controller: dateController,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          onTap: () async {
            FocusScope.of(context).requestFocus(FocusNode());
            final pickedDate = await showDatePicker(
              context: context,
              helpText: 'Select the date the Event Happened',
              initialDate: DateTime.now(),
              firstDate: DateTime(1995),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              widget.addLogEntryCubit.dateChanged(entryDate: pickedDate);
              setState(() {
                dateController.text =
                    DateFormat('MMMM dd yyyy').format(pickedDate);
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'Event Date',
            hintText: 'Enter the Date the Event Occured',
            icon: Icon(Icons.date_range),
          ),
        );
      },
    );
  }
}

/// Log Tag
Widget _logTag({
  required BuildContext context,
  required AddLogEntryState state,
}) {
  return DropdownButtonFormField<LogTag>(
    value: state.tag,
    onChanged: (value) =>
        context.read<AddLogEntryCubit>().logTagChanged(tag: value!),
    items: const [
      DropdownMenuItem(
        value: LogTag.Show,
        child: Text('Show'),
      ),
      DropdownMenuItem(
        value: LogTag.Training,
        child: Text('Training'),
      ),
      DropdownMenuItem(
        value: LogTag.Health,
        child: Text('Health'),
      ),
      DropdownMenuItem(
        value: LogTag.Other,
        child: Text('Other'),
      ),
    ],
    decoration: const InputDecoration(
      labelText: 'Log Tag',
      hintText: 'Select the Log Tag',
      icon: Icon(Icons.tag),
    ),
  );
}

///   Log Entry
Widget _logEntry({
  required RiderProfile rider,
  required BuildContext context,
  required AddLogEntryState state,
  required HorseProfile? horseProfile,
}) {
  return TextFormField(
    minLines: 3,
    maxLines: 10,
    onChanged: (value) =>
        context.read<AddLogEntryCubit>().logEntryChanged(value: value),
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.newline,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: 'Log Entry',
      hintText: 'Enter a detailed log entry for '
          '${horseProfile?.name ?? rider.name}',
      icon: horseProfile != null
          ? const Icon(HorseAndRiderIcons.horseLogIcon)
          : const Icon(HorseAndRiderIcons.riderLogIcon),
    ),
  );
}

///   Submit Button
Widget _submitButton({
  required BuildContext context,
  required AddLogEntryState state,
  required RiderProfile riderProfile,
  required HorseProfile? horseProfile,
}) {
  return FilledButton(
    onPressed: state.logEntry.invalid
        ? null
        : () {
            context.read<AddLogEntryCubit>().addLogEntry(
                  riderProfile: riderProfile,
                  horseProfile: horseProfile,
                );
          },
    child: state.status == FormzStatus.submissionInProgress
        ? const CircularProgressIndicator()
        : const Text(
            'Submit Log Entry',
          ),
  );
}
