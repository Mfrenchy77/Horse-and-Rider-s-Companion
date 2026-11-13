import 'package:database_repository/database_repository.dart';

/// Backend-neutral repository contract for Rider Logbook profile operations.
abstract interface class LogbookRiderProfileRepository {
  /// Saves a new or edited rider-authored logbook entry for [email].
  Future<void> saveRiderLogEntry({
    required String email,
    required BaseListItem entry,
    required bool isEdit,
  });

  /// Retrieves a rider profile by [email], optionally bypassing local cache.
  Future<RiderProfile?> getRiderProfileByEmail({
    required String email,
    bool serverOnly = false,
  });
}
