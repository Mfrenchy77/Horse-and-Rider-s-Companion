part of 'add_log_entry_cubit.dart';

class AddLogEntryState extends Equatable {
  const AddLogEntryState({
    required this.date,
    this.status = FormzStatus.pure,
    this.event = const SingleWord.pure(),
  });

  final DateTime date;
  final SingleWord event;
  final FormzStatus status;

  AddLogEntryState copyWith({
    DateTime? date,
    SingleWord? event,
    FormzStatus? status,
  }) {
    return AddLogEntryState(
      date: date ?? this.date,
      event: event ?? this.event,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [
        event,
        date,
        status,
      ];
}
