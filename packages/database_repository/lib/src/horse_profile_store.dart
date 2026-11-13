import 'package:database_repository/src/models/horse_profile.dart';

/// Backend-neutral interface for horse profile persistence and queries.
abstract interface class HorseProfileStore {
  /// Creates or updates [horseProfile].
  Future<void> createOrUpdateHorseProfile({
    required HorseProfile horseProfile,
  });

  /// Streams all horse profiles matching [ids].
  Stream<List<HorseProfile>> getAllUsersHorses({required List<String>? ids});

  /// Streams the horse profile matching [id].
  Stream<HorseProfile?> getHorseProfileById({required String id});

  /// Streams horse profiles whose name matches the [name] prefix.
  Stream<List<HorseProfile>> getHorseByName({required String name});

  /// Streams horse profiles whose nickname matches the [nickName] prefix.
  Stream<List<HorseProfile>> getHorseByNickName({required String nickName});

  /// Streams the horse profile matching [id].
  Stream<HorseProfile?> getHorseProfile({required String? id});

  /// Streams horse profiles in [zipCode].
  Stream<List<HorseProfile>> getHorseByZipCode({required String zipCode});

  /// Deletes the horse profile with [id].
  Future<void> deleteHorseProfile({required String id});
}
