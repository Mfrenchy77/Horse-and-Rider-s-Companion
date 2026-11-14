import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';

part 'add_log_entry_state.dart';

class AddLogEntryCubit extends Cubit<AddLogEntryState> {
  AddLogEntryCubit({
    required this._horseProfileRepository,
    required this._riderProfileRepository,
    required this.usersProfile,
  }) : super(AddLogEntryState(date: DateTime.now()));

  final HorseProfileStore _horseProfileRepository;
  final RiderProfileStore _riderProfileRepository;
  final RiderProfile usersProfile;

  /// Changed the log entry value
  void logEntryChanged({required String value}) {
    final logEntry = SingleWord.dirty(value);
    emit(state.copyWith(logEntry: logEntry));
  }

  /// Changed the Log Tag
  void logTagChanged({required LogTag tag}) {
    emit(state.copyWith(tag: tag));
  }

  /// Changed the date value
  void dateChanged({required DateTime entryDate}) {
    emit(state.copyWith(date: entryDate));
  }

  /// Process the log entry and persist it to the database
  Future<void> addLogEntry({required HorseProfile? horseProfile}) async {
    if (!state.logEntry.isValid) {
      emit(state.copyWith(status: FormStatus.failure));
      return;
    }
    final riderProfile = usersProfile;
    emit(state.copyWith(status: FormStatus.submitting));
    if (horseProfile != null) {
      // add the log entry for the horse
      debugPrint('Adding log entry for horse');
      final logEntry = BaseListItem(
        date: state.date,
        name: state.logEntry.value,
        parentId: riderProfile.email,
        id: DateTime.now().toString(),
        imageUrl: state.tag.toString(),
      );
      final updatedHorse = horseProfile.copyWith(
        notes: [...?horseProfile.notes, logEntry],
      );

      try {
        await _horseProfileRepository.createOrUpdateHorseProfile(
          horseProfile: updatedHorse,
        );
        emit(state.copyWith(status: FormStatus.success));
      } catch (e) {
        emit(state.copyWith(status: FormStatus.failure));
      }
    } else {
      // add the log entry for the rider
      debugPrint('Adding log entry for rider');
      final logEntry = BaseListItem(
        date: state.date,
        name: state.logEntry.value,
        parentId: riderProfile.email,
        id: DateTime.now().toString(),
        imageUrl: state.tag.toString(),
      );
      final updatedRider = riderProfile.copyWith(
        notes: [...?riderProfile.notes, logEntry],
      );
      try {
        await _riderProfileRepository.createOrUpdateRiderProfile(
          riderProfile: updatedRider,
        );
        emit(state.copyWith(status: FormStatus.success));
      } catch (e) {
        emit(state.copyWith(status: FormStatus.failure));
      }
    }
  }
}
