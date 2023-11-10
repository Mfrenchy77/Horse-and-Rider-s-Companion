// ignore_for_file: constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/models.dart';
import 'package:database_repository/src/models/rider_profile.dart';

///Interface for Firebase and Rider's Profile
class RiderProfileRepository {
  static const String RIDER_PROFILE = 'Rider_Profile';
  static const String OWNED_HORSES = 'ownedHorses';
  final _riderProfileDatabaseReference =
      FirebaseFirestore.instance.collection(RIDER_PROFILE).withConverter(
            fromFirestore: RiderProfile.fromFirestore,
            toFirestore: (RiderProfile riderProfile, options) =>
                riderProfile.toFirestore(),
          );

  ///create or update [riderProfile] for user

  Future<void> createOrUpdateRiderProfile({
    required RiderProfile riderProfile,
  }) {
    return _riderProfileDatabaseReference
        .doc(_convertEmailToPath(email: riderProfile.email))
        .set(riderProfile);
  }

  Future<void> addOrUpdateOwnedHorse({
    required RiderProfile? riderProfile,
    required String? horseId,
  }) {
    return _riderProfileDatabaseReference
        .doc(_convertEmailToPath(email: riderProfile?.email))
        .update({
      OWNED_HORSES: FieldValue.arrayUnion([horseId]),
    });
  }

  /// Retrieve the user's profile using [email]
  Stream<DocumentSnapshot> getRiderProfile({required String? email}) {
    return _riderProfileDatabaseReference
        .doc(_convertEmailToPath(email: email))
        .snapshots();
  }

  ///Retrive a single profile by [name]
  Stream<DocumentSnapshot> getProfileByName({required String name}) {
    return _riderProfileDatabaseReference
        .where('name', isEqualTo: name)
        .get()
        .asStream()
        .map((event) => event.docs.first);
  }

  /// Retrieve all profile for [name]
  Stream<QuerySnapshot> getProfilesByName({required String name}) {
    return _riderProfileDatabaseReference
        .where('name', isGreaterThanOrEqualTo: name)
        .where(
          'name',
          isLessThanOrEqualTo: '$name\uf8ff',
        )
        .snapshots();
  }

  /// Delete user's RiderProfile at [email]
  void deleteRiderProfile({required String email}) {
    _riderProfileDatabaseReference.doc(_convertEmailToPath(email: email));
  }

  /// converts email to a path
  static String _convertEmailToPath({required String? email}) {
    var convertedEmail = email!.replaceAll('.', '666');
    convertedEmail = convertedEmail.replaceAll('@', '999');
    convertedEmail = convertedEmail.replaceAll('f', '5');
    convertedEmail = convertedEmail.replaceAll('e', '1');
    convertedEmail = convertedEmail.replaceAll('g', '2');
    convertedEmail = convertedEmail.replaceAll('m', '');
    convertedEmail = convertedEmail.replaceAll('a', 'p');
    convertedEmail = convertedEmail.replaceAll('i', 'a');
    convertedEmail = convertedEmail.replaceAll('co', 'l');
    return convertedEmail;
  }
}
