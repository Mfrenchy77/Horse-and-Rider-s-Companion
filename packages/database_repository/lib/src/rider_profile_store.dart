import 'package:database_repository/src/logbook_rider_profile_repository.dart';
import 'package:database_repository/src/models/models.dart';

/// Backend-neutral interface for rider profile persistence and queries.
abstract interface class RiderProfileStore
    implements LogbookRiderProfileRepository {
  /// Creates or updates [riderProfile].
  Future<void> createOrUpdateRiderProfile({
    required RiderProfile riderProfile,
  });

  /// Associates [horseId] with [riderProfile]'s owned horses.
  Future<void> addOrUpdateOwnedHorse({
    required RiderProfile? riderProfile,
    required String? horseId,
  });

  /// Adds or removes [contact] from the rider's saved contacts.
  Future<void> saveContact({
    required String email,
    required BaseListItem contact,
    required bool add,
  });

  /// Streams the rider profile for [email].
  Stream<RiderProfile?> getRiderProfile({required String email});

  /// Streams the first rider profile matching [name].
  Stream<RiderProfile?> getProfileByName({required String name});

  /// Streams rider profiles whose name matches the [name] prefix.
  Stream<List<RiderProfile>> getProfilesByName({required String name});

  /// Streams rider profiles in [zipcode].
  Stream<List<RiderProfile>> getProfilesByZipcode({required String zipcode});

  /// Deletes the rider profile for [email].
  Future<void> deleteRiderProfile({required String email});
}
