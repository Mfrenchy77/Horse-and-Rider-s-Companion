import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';

part 'add_log_entry_state.dart';

class AddLogEntryCubit extends Cubit<AddLogEntryState> {
  AddLogEntryCubit({required HorseProfileRepository horseProfileRepository})
      : _horseProfileRepository = horseProfileRepository,
        super( AddLogEntryState(date: DateTime.now()));

  final HorseProfileRepository _horseProfileRepository;

  void entryChanged({required String value}) {
    final entry = SingleWord.dirty(value);
    emit(state.copyWith(event: entry, status: Formz.validate([entry])));
  }

  void dateChanged({required DateTime entryDate}) {
    emit(state.copyWith(date: entryDate));
  }

  void addLogEntry({
    required RiderProfile riderProfile,
    required HorseProfile horseProfile,
  }) {
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    final logEntry = BaseListItem(
      id: DateTime.now().toString(),
      name: state.event.value,
      date: state.date,
      parentId: riderProfile.email,
    );

    horseProfile.notes ??= [];
    horseProfile.notes?.add(logEntry);

    try {
      _horseProfileRepository.createOrUpdateHorseProfile(
        horseProfile: horseProfile,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } catch (e) {
      emit(state.copyWith(status: FormzStatus.submissionFailure));
    }
  }
}
