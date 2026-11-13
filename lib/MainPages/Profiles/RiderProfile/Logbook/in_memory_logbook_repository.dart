import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_failure.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/logbook_connection_repository.dart';

/// In-memory implementation of [LogbookConnectionRepository] for testing
/// backend independence without Firebase.
class InMemoryLogbookConnectionRepository
    implements LogbookConnectionRepository {
  InMemoryLogbookConnectionRepository({
    this.defaultUid = 'rider-uid',
    Map<String, List<BaseListItem>>? initialJournals,
    Map<String, List<Map<String, String>>>? horseOptionsByConnectionId,
    Map<String, List<BaseListItem>>? horseHistoryByHorseId,
    this.riderProfileRepository,
    this.autoVerifySkillOnRecord = true,
  }) : _journalsByUid = {
         if (initialJournals != null)
           for (final entry in initialJournals.entries)
             entry.key: List<BaseListItem>.of(entry.value),
       },
       _horseOptionsByConnectionId = {
         if (horseOptionsByConnectionId != null)
           for (final entry in horseOptionsByConnectionId.entries)
             entry.key: List<Map<String, String>>.of(entry.value),
       },
       _horseHistoryByHorseId = {
         if (horseHistoryByHorseId != null)
           for (final entry in horseHistoryByHorseId.entries)
             entry.key: List<BaseListItem>.of(entry.value),
       };

  final String defaultUid;
  final Map<String, List<BaseListItem>> _journalsByUid;
  final Map<String, List<Map<String, String>>> _horseOptionsByConnectionId;
  final Map<String, List<BaseListItem>> _horseHistoryByHorseId;
  final InMemoryLogbookRiderProfileRepository? riderProfileRepository;
  final bool autoVerifySkillOnRecord;

  final Map<String, StreamController<List<BaseListItem>>> _controllers = {};

  /// Optional error thrown by the next [submit] call (cleared once thrown).
  Exception? nextSubmitError;

  /// Recorded payloads passed to [submit] for test assertions.
  final List<Map<String, Object?>> submittedPayloads = [];

  List<BaseListItem> entriesFor(String uid) =>
      List<BaseListItem>.unmodifiable(_journalsByUid[uid] ?? const []);

  StreamController<List<BaseListItem>> _controllerFor(String uid) {
    return _controllers.putIfAbsent(
      uid,
      StreamController<List<BaseListItem>>.broadcast,
    );
  }

  void _emit(String uid) {
    final controller = _controllers[uid];
    if (controller != null && !controller.isClosed) {
      controller.add(entriesFor(uid));
    }
  }

  /// Replaces the journal entries for [uid] and notifies active listeners.
  void seedJournal(String uid, List<BaseListItem> entries) {
    _journalsByUid[uid] = List<BaseListItem>.of(entries);
    _emit(uid);
  }

  @override
  Stream<List<BaseListItem>> watchJournal(String uid) {
    final controller = _controllerFor(uid);
    return Stream<List<BaseListItem>>.multi((multi) {
      multi.add(entriesFor(uid));
      final sub = controller.stream.listen(
        multi.add,
        onError: multi.addError,
        onDone: multi.close,
      );
      multi.onCancel = sub.cancel;
    });
  }

  @override
  Future<List<BaseListItem>> history(Map<String, Object?> data) async {
    final result = await submit(data);
    final rawEntries = result['entries'] as List<Object?>? ?? const [];
    return [
      for (final item in rawEntries)
        if (item is BaseListItem)
          item
        else if (item is Map)
          BaseListItem.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<Map<String, dynamic>> submit(Map<String, Object?> data) async {
    submittedPayloads.add(Map<String, Object?>.of(data));
    final error = nextSubmitError;
    if (error != null) {
      nextSubmitError = null;
      throw error;
    }

    final action = data['action'] as String?;
    switch (action) {
      case 'saveJournal':
        final uid = (data['uid'] as String?) ?? defaultUid;
        final id = data['id'] as String? ?? 'entry-${submittedPayloads.length}';
        final isEdit = data['isEdit'] == true;
        final dateStr = data['date'] as String?;
        final parsedDate = dateStr == null ? null : DateTime.tryParse(dateStr);
        final item = BaseListItem(
          id: id,
          name: data['notes'] as String?,
          date: parsedDate,
          extra: data['riderName'] as String?,
          isSelected: true,
          riderLog: RiderLogDetails.fromMap({
            ...data,
            'type': data['type'] ?? 'other',
            'shared': data['shared'] == true,
          }),
        );
        final list = _journalsByUid.putIfAbsent(uid, () => <BaseListItem>[]);
        final idx = list.indexWhere((e) => e.id == id);
        if (isEdit && idx >= 0) {
          list[idx] = item;
        } else if (idx >= 0) {
          list[idx] = item;
        } else {
          list.add(item);
        }
        _emit(uid);
        return {'ok': true, 'id': id};

      case 'record':
      case 'editLesson':
        final uid = (data['uid'] as String?) ?? defaultUid;
        final id =
            (data['entryId'] as String?) ??
            (data['recordId'] as String?) ??
            'lesson-${submittedPayloads.length}';
        final dateStr = data['date'] as String?;
        final parsedDate = dateStr == null ? null : DateTime.tryParse(dateStr);
        final item = BaseListItem(
          id: id,
          name: data['notes'] as String?,
          date: parsedDate,
          isSelected: true,
          riderLog: RiderLogDetails(
            type: RiderLogType.lesson,
            shared: true,
            title: data['title'] as String?,
            horseId: data['horseId'] as String?,
            horse: data['horse'] as String?,
            focus: data['focus'] as String?,
            nextSteps: data['nextSteps'] as String?,
          ),
        );
        final list = _journalsByUid.putIfAbsent(uid, () => <BaseListItem>[]);
        final idx = list.indexWhere((e) => e.id == id);
        if (idx >= 0) {
          list[idx] = item;
        } else {
          list.add(item);
        }
        if (action == 'record' &&
            autoVerifySkillOnRecord &&
            data['skillId'] is String &&
            riderProfileRepository != null) {
          final skillId = data['skillId']! as String;
          final levelName = (data['level'] as String?) ?? 'LEARNING';
          final levelState = LevelState.values.firstWhere(
            (e) => e.name == levelName,
            orElse: () => LevelState.LEARNING,
          );
          riderProfileRepository!.recordVerifiedSkill(
            skillId: skillId,
            levelState: levelState,
          );
        }
        _emit(uid);
        return {'ok': true, 'id': id};

      case 'deleteJournal':
        final id = data['id'] as String?;
        var removed = false;
        for (final entry in _journalsByUid.entries) {
          final before = entry.value.length;
          entry.value.removeWhere((item) => item.id == id);
          if (entry.value.length != before) {
            removed = true;
            _emit(entry.key);
          }
        }
        if (!removed) {
          throw const ConnectionFailure('Entry not found.');
        }
        return {'ok': true};

      case 'horseOptions':
        final connectionId = data['id'] as String? ?? '';
        return {
          'horses': _horseOptionsByConnectionId[connectionId] ?? const [],
        };

      case 'horseHistory':
        final horseId = data['horseId'] as String? ?? '';
        final explicit = _horseHistoryByHorseId[horseId];
        if (explicit != null) {
          return {'entries': explicit};
        }
        final matching = <BaseListItem>[
          for (final entries in _journalsByUid.values)
            for (final item in entries)
              if (item.riderLog?.horseId == horseId) item,
        ];
        return {'entries': matching};

      default:
        return {'ok': true};
    }
  }

  /// Closes all stream controllers created by this repository.
  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
  }
}

/// In-memory implementation of [LogbookRiderProfileRepository] for testing
/// backend independence without Firestore.
class InMemoryLogbookRiderProfileRepository
    implements LogbookRiderProfileRepository {
  InMemoryLogbookRiderProfileRepository({
    Map<String, RiderProfile>? initialProfiles,
  }) : _profilesByEmail = {
         if (initialProfiles != null)
           for (final entry in initialProfiles.entries)
             entry.key.toLowerCase(): entry.value,
       };

  final Map<String, RiderProfile> _profilesByEmail;

  /// Optional error thrown by the next [saveRiderLogEntry] call.
  Exception? nextSaveError;

  RiderProfile? profileFor(String email) =>
      _profilesByEmail[email.toLowerCase()];

  void putProfile(RiderProfile profile) {
    _profilesByEmail[profile.email.toLowerCase()] = profile;
  }

  /// Helper used by [InMemoryLogbookConnectionRepository] when recording a
  /// verified lesson skill in tests.
  void recordVerifiedSkill({
    required String skillId,
    required LevelState levelState,
    String coachEmail = 'coach@example.com',
  }) {
    for (final key in _profilesByEmail.keys.toList()) {
      final profile = _profilesByEmail[key]!;
      final updated = List<SkillLevel>.of(profile.skillLevels ?? const [])
        ..removeWhere((s) => s.skillId == skillId)
        ..add(
          SkillLevel(
            skillId: skillId,
            skillName: skillId,
            levelState: levelState,
            verified: true,
            lastEditBy: coachEmail,
            lastEditDate: DateTime.now(),
          ),
        );
      _profilesByEmail[key] = profile.copyWith(skillLevels: updated);
    }
  }

  @override
  Future<RiderProfile?> getRiderProfileByEmail({
    required String email,
    bool serverOnly = false,
  }) async {
    return _profilesByEmail[email.toLowerCase()];
  }

  @override
  Future<void> saveRiderLogEntry({
    required String email,
    required BaseListItem entry,
    required bool isEdit,
  }) async {
    final error = nextSaveError;
    if (error != null) {
      nextSaveError = null;
      throw error;
    }
    if (!entry.canEditRiderLog(email) || entry.riderLog == null) {
      throw ArgumentError('A rider can only save their own journal entries.');
    }
    final key = email.toLowerCase();
    final existing = _profilesByEmail[key];
    if (existing == null) {
      throw StateError('Profile not found.');
    }
    final notes = List<BaseListItem>.of(existing.notes ?? const []);
    if (!isEdit) {
      notes.add(entry);
    } else {
      final idx = notes.indexWhere((item) => item.id == entry.id);
      if (idx < 0) throw StateError('This log entry no longer exists.');
      if (!notes[idx].canEditRiderLog(email)) {
        throw StateError('This log entry cannot be edited.');
      }
      notes[idx] = entry;
    }
    _profilesByEmail[key] = existing.copyWith(notes: notes);
  }
}
