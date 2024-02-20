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
  Stream<QuerySnapshot> getAllUsersHorses({required List<String>? ids}) {
    //retrieve horses assigned to a users profile
    return _horseProfiledatabaseReference.where('id', whereIn: ids).snapshots();
  }

  /// retrieve a horse profile by its [id]
  Stream<DocumentSnapshot> getHorseProfileById({required String? id}) {
    return _horseProfiledatabaseReference.doc(id).snapshots();
  }

  ///retrieve all horse profiles for  [name]
  Stream<QuerySnapshot> getHorseByName({required String name}) {
    //retrieve horse with name from database

    return _horseProfiledatabaseReference
        .where('name', isGreaterThanOrEqualTo: name)
        .where(
          'name',
          isLessThanOrEqualTo: '$name\uf8ff',
        )
        .snapshots();
  }

  ///retrieve all horse profiles for  [nickName]
  Stream<QuerySnapshot> getHorseByNickName({required String nickName}) {
    //retrieve horse with name from database

    return _horseProfiledatabaseReference
        .where('nickName', isGreaterThanOrEqualTo: nickName)
        .where(
          'nickName',
          isLessThanOrEqualTo: '$nickName\uf8ff',
        )
        .snapshots();
  }

  ///Retrieve Horse Profile using it's[id]
  Stream<DocumentSnapshot> getHorseProfile({required String? id}) {
    return _horseProfiledatabaseReference.doc(id).snapshots();
  }

  /// Retrieve all horse profiles for a zip code
  Stream<QuerySnapshot> getHorseByZipCode({required String zipCode}) {
    return _horseProfiledatabaseReference
        .where('zipCode', isEqualTo: zipCode)
        .snapshots();
  }

  ///Delete Horse Profile at [id]
  void deleteHorseProfile({required String id}) {
    _horseProfiledatabaseReference.doc(id).delete();
  }
}
