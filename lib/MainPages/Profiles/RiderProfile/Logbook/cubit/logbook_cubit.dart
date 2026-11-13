import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';

/// Side-effects for the Rider Logbook feature.
///
/// UI should gather user input (forms/dialogs), then call a single cubit method.
/// This avoids UI `setState` racing with network updates and makes the feature
/// unit-testable.
class LogbookCubit extends Cubit<LogbookState> {
  LogbookCubit({
    required this._connectionRepository,
    required this._riderProfileRepository,
  }) : super(const LogbookState());

  final LogbookConnectionRepository? _connectionRepository;
  final LogbookRiderProfileRepository? _riderProfileRepository;

  bool get _busy => state.actionInProgress;

  void clearFeedback() => emit(state.copyWith(clearFeedback: true));

  Future<String> deleteEntry(BaseListItem entry) async {
    if (_busy) {
      throw const ConnectionFailure('Another request is in progress.');
    }
    final repo = _connectionRepository;
    if (repo == null) {
      throw const ConnectionFailure('Shared logbook unavailable.');
    }
    emit(state.copyWith(actionInProgress: true, clearFeedback: true));
    try {
      await repo.submit({
        'action': 'deleteJournal',
        'id': entry.id,
        'shared': entry.riderLog?.shared ?? false,
      });
      emit(state.copyWith(actionInProgress: false, feedback: 'Entry deleted.'));
      return 'Entry deleted.';
    } on ConnectionFailure catch (e) {
      emit(state.copyWith(actionInProgress: false, feedback: e.message));
      rethrow;
    } catch (_) {
      const msg = 'Could not delete the entry.';
      emit(state.copyWith(actionInProgress: false, feedback: msg));
      throw const ConnectionFailure(msg);
    }
  }

  Future<Map<String, String>> fetchStudentHorseOptions(
    CoachingConnection student, {
    String? preserveHorseId,
    String? preserveHorseName,
  }) async {
    if (_busy) {
      throw const ConnectionFailure('Another request is in progress.');
    }
    final repo = _connectionRepository;
    if (repo == null) {
      throw const ConnectionFailure('Shared logbook unavailable.');
    }
    emit(state.copyWith(actionInProgress: true, clearFeedback: true));
    try {
      final result = await repo.submit({
        'action': 'horseOptions',
        'id': student.id,
        'version': student.version,
      });
      final horses = <String, String>{
        for (final horse in (result['horses'] as List? ?? const []))
          'horse:${(horse as Map)['id']}': horse['name'] as String,
      };
      if (preserveHorseId != null) {
        horses.putIfAbsent(
          'horse:$preserveHorseId',
          () => preserveHorseName ?? preserveHorseId,
        );
      }
      emit(state.copyWith(actionInProgress: false));
      return horses;
    } on ConnectionFailure catch (e) {
      emit(state.copyWith(actionInProgress: false, feedback: e.message));
      rethrow;
    } catch (_) {
      const msg = 'Could not load the student’s horses.';
      emit(state.copyWith(actionInProgress: false, feedback: msg));
      throw const ConnectionFailure(msg);
    }
  }

  Future<String> saveStudentLesson({
    required CoachingConnection student,
    required String recordId,
    required String notes,
    required bool isEdit,
    String? entryId,
    String? horseId,
    String? horse,
    DateTime? date,
    String? title,
    String? focus,
    String? nextSteps,
    String? skillId,
    String level = 'LEARNING',
  }) async {
    if (_busy) {
      throw const ConnectionFailure('Another request is in progress.');
    }
    final repo = _connectionRepository;
    if (repo == null) {
      throw const ConnectionFailure('Shared logbook unavailable.');
    }
    emit(state.copyWith(actionInProgress: true, clearFeedback: true));
    try {
      await repo.submit({
        'action': isEdit ? 'editLesson' : 'record',
        if (entryId != null) 'entryId': entryId,
        'id': student.id,
        'version': student.version,
        'recordId': recordId,
        'notes': notes,
        'horseId': horseId,
        'horse': horse,
        'date': date?.toUtc().toIso8601String(),
        'title': title,
        'focus': focus,
        'nextSteps': nextSteps,
        'skillId': skillId,
        'level': level,
      });
      if (!isEdit && skillId != null) {
        final riderRepo = _riderProfileRepository;
        final profile = riderRepo == null
            ? null
            : await riderRepo.getRiderProfileByEmail(
                email: student.learner,
                serverOnly: true,
              );
        final confirmed = profile?.skillLevels?.any(
          (entry) =>
              entry.skillId == skillId &&
              entry.verified &&
              entry.levelState.name == level &&
              entry.lastEditBy?.toLowerCase() == student.coach,
        );
        if (!(confirmed ?? false)) {
          throw const ConnectionFailure(
            'The lesson was saved, but Firebase did not confirm the skill '
            'verification. Check the coaching service before retrying.',
          );
        }
      }
      final msg = !isEdit && skillId != null
          ? 'Skill verified and saved to the student’s logbook.'
          : 'Saved to the student’s logbook.';
      emit(state.copyWith(actionInProgress: false, feedback: msg));
      return msg;
    } on ConnectionFailure catch (e) {
      emit(state.copyWith(actionInProgress: false, feedback: e.message));
      rethrow;
    } catch (_) {
      const msg = 'Could not save. Try again.';
      emit(state.copyWith(actionInProgress: false, feedback: msg));
      throw const ConnectionFailure(msg);
    }
  }

  Future<String> saveSharedJournalEntry({
    required String id,
    required bool isEdit,
    required bool shared,
    required DateTime? date,
    required String notes,
    required RiderLogDetails details,
  }) async {
    if (_busy) {
      throw const ConnectionFailure('Another request is in progress.');
    }
    final repo = _connectionRepository;
    if (repo == null) {
      throw const ConnectionFailure('Shared logbook unavailable.');
    }
    emit(state.copyWith(actionInProgress: true, clearFeedback: true));
    try {
      await repo.submit({
        'action': 'saveJournal',
        'id': id,
        'isEdit': isEdit,
        'shared': shared,
        'date': date?.toUtc().toIso8601String(),
        'notes': notes,
        ...details.toMap(),
      });
      const msg = 'Saved.';
      emit(state.copyWith(actionInProgress: false, feedback: msg));
      return msg;
    } on ConnectionFailure catch (e) {
      emit(state.copyWith(actionInProgress: false, feedback: e.message));
      rethrow;
    } catch (_) {
      const msg = 'Could not save. Try again.';
      emit(state.copyWith(actionInProgress: false, feedback: msg));
      throw const ConnectionFailure(msg);
    }
  }

  Future<String> saveLocalEntry({
    required RiderProfile rider,
    required bool isEdit,
    required BaseListItem entry,
  }) async {
    if (_busy) {
      throw const ConnectionFailure('Another request is in progress.');
    }
    final repo = _riderProfileRepository;
    if (repo == null) {
      throw const ConnectionFailure(
        'Could not save the entry. Your draft is still here.',
      );
    }
    emit(state.copyWith(actionInProgress: true, clearFeedback: true));
    try {
      await repo.saveRiderLogEntry(
        email: rider.email,
        isEdit: isEdit,
        entry: entry,
      );
      const msg = 'Saved.';
      emit(state.copyWith(actionInProgress: false, feedback: msg));
      return msg;
    } catch (error) {
      if (error is StateError) {
        emit(state.copyWith(actionInProgress: false, feedback: error.message));
        rethrow;
      }
      const msg = 'Could not save the entry. Your draft is still here.';
      emit(state.copyWith(actionInProgress: false, feedback: msg));
      throw const ConnectionFailure(msg);
    }
  }
}

class LogbookState extends Equatable {
  const LogbookState({this.actionInProgress = false, this.feedback});

  final bool actionInProgress;
  final String? feedback;

  LogbookState copyWith({
    bool? actionInProgress,
    String? feedback,
    bool clearFeedback = false,
  }) {
    return LogbookState(
      actionInProgress: actionInProgress ?? this.actionInProgress,
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
    );
  }

  @override
  List<Object?> get props => [actionInProgress, feedback];
}
