// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/horse_profile_store.dart';
import 'package:database_repository/src/mappers/horse_profile_firestore_mapper.dart';
import 'package:database_repository/src/models/horse_profile.dart';
import 'package:database_repository/src/repository_exception.dart';

///Interface between Horse and Riders and Firebase
class HorseProfileRepository implements HorseProfileStore {
  HorseProfileRepository({FirebaseFirestore? firestore})
      : _horseProfiledatabaseReference =
            (firestore ?? FirebaseFirestore.instance)
                .collection(HORSE_PROFILE)
                .withConverter<HorseProfile>(
                  fromFirestore: HorseProfileFirestoreMapper.fromFirestore,
                  toFirestore: HorseProfileFirestoreMapper.toFirestore,
                );

  static const String HORSE_PROFILE = 'Horse_Profile';

  final CollectionReference<HorseProfile> _horseProfiledatabaseReference;

  ///create or update [horseProfile]
  @override
  Future<void> createOrUpdateHorseProfile({
    required HorseProfile horseProfile,
  }) {
    return guardFirebase(
      () => _horseProfiledatabaseReference
          .doc(horseProfile.id)
          .set(horseProfile, SetOptions(merge: true)),
    );
  }

  ///retrieve all horse profiles for user [ids]
  @override
  Stream<List<HorseProfile>> getAllUsersHorses({required List<String>? ids}) {
    if (ids == null || ids.isEmpty) {
      return Stream.value(<HorseProfile>[]);
    }
    //retrieve horses assigned to a users profile
    return _horseProfiledatabaseReference
        .where('id', whereIn: ids)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// retrieve a horse profile by its [id]
  @override
  Stream<HorseProfile?> getHorseProfileById({required String id}) {
    return _horseProfiledatabaseReference
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }

  ///retrieve all horse profiles for  [name]
  @override
  Stream<List<HorseProfile>> getHorseByName({required String name}) {
    //retrieve horse with name from database

    return _horseProfiledatabaseReference
        .where('name', isGreaterThanOrEqualTo: name)
        .where(
          'name',
          isLessThanOrEqualTo: '$name\uf8ff',
        )
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///retrieve all horse profiles for  [nickName]
  @override
  Stream<List<HorseProfile>> getHorseByNickName({required String nickName}) {
    //retrieve horse with name from database

    return _horseProfiledatabaseReference
        .where('nickname', isGreaterThanOrEqualTo: nickName)
        .where(
          'nickname',
          isLessThanOrEqualTo: '$nickName\uf8ff',
        )
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///Retrieve Horse Profile using it's[id]
  @override
  Stream<HorseProfile?> getHorseProfile({required String? id}) {
    return _horseProfiledatabaseReference
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Retrieve all horse profiles for a zip code
  @override
  Stream<List<HorseProfile>> getHorseByZipCode({required String zipCode}) {
    return _horseProfiledatabaseReference
        .where('zipCode', isEqualTo: zipCode)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///Delete Horse Profile at [id]
  @override
  Future<void> deleteHorseProfile({required String id}) {
    return guardFirebase(() => _horseProfiledatabaseReference.doc(id).delete());
  }
}
