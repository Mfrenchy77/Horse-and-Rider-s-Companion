// ignore_for_file: constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/horse_profile.dart';

///Interface between Horse and Riders and Firebase
class HorseProfileRepository {
  static const String HORSE_PROFILE = 'Horse_Profile';

  final _horseProfiledatabaseReference = FirebaseFirestore.instance
      .collection(HORSE_PROFILE)
      .withConverter<HorseProfile>(
        fromFirestore: HorseProfile.fromFirestore,
        toFirestore: (HorseProfile horseProfile, options) =>
            horseProfile.toFirestore(),
      );

  ///create or update [horseProfile]
  Future<void> createOrUpdateHorseProfile({
    required HorseProfile horseProfile,
  }) {
    return _horseProfiledatabaseReference
        .doc(horseProfile.id)
        .set(horseProfile, SetOptions(merge: true));
  }

  ///retrieve all horse profiles for user [ids]
  Stream<List<HorseProfile>> getAllUsersHorses({required List<String>? ids}) {
    //retrieve horses assigned to a users profile
    return _horseProfiledatabaseReference
        .where('id', whereIn: ids)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// retrieve a horse profile by its [id]
  Stream<HorseProfile?> getHorseProfileById({required String id}) {
    return _horseProfiledatabaseReference
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }

  ///retrieve all horse profiles for  [name]
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
  Stream<List<HorseProfile>> getHorseByNickName({required String nickName}) {
    //retrieve horse with name from database

    return _horseProfiledatabaseReference
        .where('nickName', isGreaterThanOrEqualTo: nickName)
        .where(
          'nickName',
          isLessThanOrEqualTo: '$nickName\uf8ff',
        )
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///Retrieve Horse Profile using it's[id]
  Stream<HorseProfile?> getHorseProfile({required String? id}) {
    return _horseProfiledatabaseReference
        .doc(id)
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Retrieve all horse profiles for a zip code
  Stream<List<HorseProfile>> getHorseByZipCode({required String zipCode}) {
    return _horseProfiledatabaseReference
        .where('zipCode', isEqualTo: zipCode)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  ///Delete Horse Profile at [id]
  void deleteHorseProfile({required String id}) {
    _horseProfiledatabaseReference.doc(id).delete();
  }
}
