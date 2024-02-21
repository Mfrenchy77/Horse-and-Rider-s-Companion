// ignore_for_file: constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/models.dart';
import 'package:database_repository/src/models/rider_profile.dart';
import 'package:flutter/foundation.dart';

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
  }) async {
    try {
      await _riderProfileDatabaseReference
          .doc(_convertEmailToPath(email: riderProfile.email))
          .set(riderProfile);
    } on FirebaseException catch (e) {
      handleFirebaseException(e);
    }
  }

  Future<void> addOrUpdateOwnedHorse({
    required RiderProfile? riderProfile,
    required String? horseId,
  }) async {
    try {
      await _riderProfileDatabaseReference
          .doc(_convertEmailToPath(email: riderProfile?.email))
          .update({
        OWNED_HORSES: FieldValue.arrayUnion([horseId]),
      });
    } on FirebaseException catch (e) {
      handleFirebaseException(e);
    }
  }

  /// Retrieve the user's profile using [email]
  Stream<DocumentSnapshot> getRiderProfile({required String email}) {
    return _riderProfileDatabaseReference
        .doc(_convertEmailToPath(email: email))
        .snapshots()
        .handleError((Object error) {
      if (error is FirebaseException) {
        handleFirebaseException(error);
      } else {
        debugPrint('An unknown error occurred in getRiderProfile: $error');
      }
    });
  }

  ///Retrive a single profile by [name]
  Stream<DocumentSnapshot> getProfileByName({required String name}) {
    return _riderProfileDatabaseReference
        .where('name', isEqualTo: name)
        .get()
        .asStream()
        .map((event) => event.docs.first)
        .handleError((Object error) {
      if (error is FirebaseException) {
        handleFirebaseException(error);
      } else {
        debugPrint('An unknown error occurred in getProfileByName: $error');
      }
    });
  }

  /// Retrieve all profile for [name]
  Stream<QuerySnapshot> getProfilesByName({required String name}) {
    return _riderProfileDatabaseReference
        .where('name', isGreaterThanOrEqualTo: name)
        .where(
          'name',
          isLessThanOrEqualTo: '$name\uf8ff',
        )
        .snapshots()
        .handleError((Object error) {
      if (error is FirebaseException) {
        handleFirebaseException(error);
      } else {
        debugPrint('An unknown error occurred in getProfilesByName: $error');
      }
    });
  }

  /// Retrieve all profiles for zipcode
  Stream<QuerySnapshot> getProfilesByZipcode({required String zipcode}) {
    return _riderProfileDatabaseReference
        .where('zipCode', isEqualTo: zipcode)
        .snapshots()
        .handleError((Object error) {
      if (error is FirebaseException) {
        handleFirebaseException(error);
      } else {
        debugPrint('An unknown error occurred in getProfilesByZipcode: $error');
      }
    });
  }

  /// Delete user's RiderProfile at [email]
  Future<void> deleteRiderProfile({required String email}) async {
    try {
      await _riderProfileDatabaseReference
          .doc(_convertEmailToPath(email: email))
          .delete();
    } on FirebaseException catch (e) {
      handleFirebaseException(e);
    }
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

/// Handle Firebase exceptions
void handleFirebaseException(FirebaseException exception) {
  switch (exception.code) {
    case 'not-found':
      debugPrint('Document not found');
      break;
    case 'permission-denied':
      debugPrint('Permission denied');
      break;
    // Add cases for other error codes
    default:
      debugPrint('An unknown error occurred: ${exception.message}');
  }
  // Depending on the use case, you might want to rethrow the exception
  // or handle it silently
}
