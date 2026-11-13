import 'package:database_repository/database_repository.dart';

/// Backend-neutral repository contract for shared Rider Logbook entries,
/// lesson recording, and horse history lookups.
abstract interface class LogbookConnectionRepository {
  /// Watches shared logbook entries for the rider identified by [uid].
  Stream<List<BaseListItem>> watchJournal(String uid);

  /// Fetches logbook history records matching [data] (e.g. horse history).
  Future<List<BaseListItem>> history(Map<String, Object?> data);

  /// Submits a logbook mutation or query action with backend-neutral [data].
  Future<Map<String, dynamic>> submit(Map<String, Object?> data);
}
