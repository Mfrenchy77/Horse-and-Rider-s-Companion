import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/HorseProfile/cubit/add_log_entry_cubit.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:intl/intl.dart';

class AddLogEntryDialog extends StatelessWidget {
  const AddLogEntryDialog({
    super.key,
    required this.riderProfile,
    required this.horseProfile,
  });
  final RiderProfile riderProfile;
  final HorseProfile horseProfile;
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => HorseProfileRepository(),
      child: BlocProvider(
        create: (context) => AddLogEntryCubit(
          horseProfileRepository: context.read<HorseProfileRepository>(),
        ),
        child: BlocBuilder<AddLogEntryCubit, AddLogEntryState>(
          builder: (context, state) {
            if (state.status == FormzStatus.submissionSuccess) {
              Navigator.of(context).pop();
            }
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text('Add New Log Entry'),
              ),
              body: AlertDialog(
                insetPadding: const EdgeInsets.all(10),
                scrollable: true,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EventDate(
                      addLogEntryCubit: context.read<AddLogEntryCubit>(),
                      state: state,
                      context: context,
                      horseProfile: horseProfile,
                    ),
                    gap(),
                    _event(
                      context: context,
                      state: state,
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
                    _submitButton(
                      horseProfile: horseProfile,
                      riderProfile: riderProfile,
                      context: context,
                      state: state,
                    ),
                  ],
                ),
              ),
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

// class _EventDate extends StatefulWidget {
//   const _EventDate({
//     required this.context,
//     required this.state,
//     required this.horseProfile,
//   });
//   final BuildContext context;
//   final AddLogEntryState state;
//   final HorseProfile? horseProfile;
//   @override
//   State<_EventDate> createState() => _EventDateState();
// }

// class _EventDateState extends State<_EventDate> {
//   late TextEditingController dateText;
//   @override
//   void initState() {
//     super.initState();
//     dateText = TextEditingController(
//       text: DateFormat('MMMM dd yyyy').format(DateTime.now()),
//     );
//   }

//   @override
//   void dispose() {
//     dateText.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       readOnly: true,
//       controller: dateText,
//       keyboardType: TextInputType.datetime,
//       textInputAction: TextInputAction.next,
//       onTap: () async {
//         FocusScope.of(context).requestFocus(FocusNode());
//         await showDatePicker(
//           context: context,
//           helpText: 'Select the date the Event Happened',
//           initialDate: DateTime.now(),
//           firstDate: DateTime(1995),
//           lastDate: DateTime(2100),
//         ).then((value) {
//           if (value != null) {
//             widget.context
//                 .read<AddLogEntryCubit>()
//                 .dateChanged(entryDate: value);

//             dateText.text = DateFormat('MM-dd-yyyy').format(value);
//           }
//         });
//       },
//       decoration: const InputDecoration(
//         labelText: 'Event Date',
//         hintText: 'Enter the Date the Event Occured',
//         icon: Icon(Icons.date_range),
//       ),
//     );
//   }
// }

///   Text of what the event is for
Widget _event({
  required BuildContext context,
  required AddLogEntryState state,
  required HorseProfile? horseProfile,
}) {
  return TextFormField(
    onChanged: (value) =>
        context.read<AddLogEntryCubit>().entryChanged(value: value),
    keyboardType: TextInputType.multiline,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: 'Log Entry',
      hintText:
          'Enter a description of the Log event for ${horseProfile?.name}',
      icon: const Icon(HorseAndRiderIcons.horseIcon),
    ),
  );
}

///   Submit Button

Widget _submitButton({
  required HorseProfile horseProfile,
  required RiderProfile riderProfile,
  required BuildContext context,
  required AddLogEntryState state,
}) {
  return ElevatedButton(
    onPressed: state.event.invalid
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


///(Advanced) Notification if Repeating
