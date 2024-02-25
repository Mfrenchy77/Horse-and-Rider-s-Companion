part of 'add_log_entry_cubit.dart';

// ignore: constant_identifier_names
enum LogTag { Show, Training, Health, Other }

class AddLogEntryState extends Equatable {
  const AddLogEntryState({
    this.tag = LogTag.Other,
    required this.date,
    this.status = FormzStatus.pure,
    this.logEntry = const SingleWord.pure(),
  });

  final LogTag tag;
  final DateTime date;
  final FormzStatus status;
  final SingleWord logEntry;

  AddLogEntryState copyWith({
    LogTag? tag,
    DateTime? date,
    FormzStatus? status,
    SingleWord? logEntry,
  }) {
    return AddLogEntryState(
      tag: tag ?? this.tag,
      date: date ?? this.date,
      status: status ?? this.status,
      logEntry: logEntry ?? this.logEntry,
    );
  }

  @override
  List<Object> get props => [
        tag,
        date,
        status,
        logEntry,
      ];
}
