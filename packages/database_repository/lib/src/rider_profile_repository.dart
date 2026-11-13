// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/models.dart';
import 'package:flutter/foundation.dart';

///Interface for Firebase and Rider's Profile
class RiderProfileRepository {
  RiderProfileRepository({FirebaseFirestore? firestore})
    : _riderProfileDatabaseReference = (firestore ?? FirebaseFirestore.instance)
          .collection(RIDER_PROFILE)
          .withConverter<RiderProfile>(
            fromFirestore: RiderProfile.fromFirestore,
            toFirestore: (riderProfile, options) => riderProfile.toFirestore(),
          );

  static const String RIDER_PROFILE = 'Rider_Profile';
  static const String OWNED_HORSES = 'ownedHorses';
  final CollectionReference<RiderProfile> _riderProfileDatabaseReference;

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
      rethrow;
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
            OWNED_HORSES: FieldValue.arrayUnion([
              BaseListItem(id: horseId).toFirestore(),
            ]),
          });
    } on FirebaseException catch (e) {
      handleFirebaseException(e);
      rethrow;
    }
  }

  /// Updates the signed-in rider's saved contacts without rewriting their profile.
  Future<void> saveContact({
    required String email,
    required BaseListItem contact,
    required bool add,
  }) async {
    final firestore = _riderProfileDatabaseReference.firestore;
    final doc = firestore
        .collection(RIDER_PROFILE)
        .doc(_convertEmailToPath(email: email));
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      final contacts = snapshot.data()?['savedProfilesList'] as List? ?? [];
      final remaining = contacts.where(
        (item) => item is! Map || item['id'] != contact.id,
      );
      transaction.update(doc, {
        'savedProfilesList': [...remaining, if (add) contact.toFirestore()],
      });
    });
  }

  /// Writes only the rider's notes, preserving other profile fields.
  Future<void> saveRiderLogEntry({
    required String email,
    required BaseListItem entry,
    required bool isEdit,
  }) async {
    if (!entry.canEditRiderLog(email) || entry.riderLog == null) {
      throw ArgumentError('A rider can only save their own journal entries.');
    }

    final firestore = _riderProfileDatabaseReference.firestore;
    final doc = firestore
        .collection(RIDER_PROFILE)
        .doc(_convertEmailToPath(email: email));
    if (!isEdit) {
      await doc.update({
        'notes': FieldValue.arrayUnion([entry.toFirestore()]),
      });
      return;
    }

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      final notes = List<Object?>.of(
        snapshot.data()?['notes'] as List? ?? const [],
      );
      final index = notes.indexWhere(
        (note) => note is Map && note['id'] == entry.id,
      );
      if (index < 0) throw StateError('This log entry no longer exists.');
      final original = Map<String, dynamic>.from(notes[index]! as Map);
      if (!BaseListItem.fromJson(original).canEditRiderLog(email)) {
        throw StateError('This log entry cannot be edited.');
      }
      // Preserve legacy fields and any fields this version does not recognize.
      notes[index] = {...original, ...entry.toFirestore()};
      transaction.update(doc, {'notes': notes});
    });
  }

  /// Retrieve the user's profile using [email]
  Stream<RiderProfile?> getRiderProfile({required String email}) {
    return _riderProfileDatabaseReference
        .doc(_convertEmailToPath(email: email))
        .snapshots()
        .map((snap) => snap.data())
        .handleError((Object error) {
          if (error is FirebaseException) {
            handleFirebaseException(error);
          } else {
            debugPrint('An unknown error occurred in getRiderProfile: $error');
          }
        });
  }

  Future<RiderProfile?> getRiderProfileByEmail({
    required String email,
    bool serverOnly = false,
  }) async {
    final snap = await _riderProfileDatabaseReference
        .doc(_convertEmailToPath(email: email))
        .get(serverOnly ? const GetOptions(source: Source.server) : null);
    return snap.data();
  }

  ///Retrive a single profile by [name]
  Stream<RiderProfile?> getProfileByName({required String name}) {
    return _riderProfileDatabaseReference
        .where('name', isEqualTo: name)
        .get()
        .asStream()
        .map((event) => event.docs.isNotEmpty ? event.docs.first.data() : null)
        .handleError((Object error) {
          if (error is FirebaseException) {
            handleFirebaseException(error);
          } else {
            debugPrint('An unknown error occurred in getProfileByName: $error');
          }
        });
  }

  /// Retrieve all profile for [name]
  Stream<List<RiderProfile>> getProfilesByName({required String name}) {
    return _riderProfileDatabaseReference
        .where('name', isGreaterThanOrEqualTo: name)
        .where('name', isLessThanOrEqualTo: '$name\uf8ff')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((Object error) {
          if (error is FirebaseException) {
            handleFirebaseException(error);
          } else {
            debugPrint(
              'An unknown error occurred in getProfilesByName: $error',
            );
          }
        });
  }

  /// Retrieve all profiles for zipcode
  Stream<List<RiderProfile>> getProfilesByZipcode({required String zipcode}) {
    return _riderProfileDatabaseReference
        .where('zipCode', isEqualTo: zipcode)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((Object error) {
          if (error is FirebaseException) {
            handleFirebaseException(error);
          } else {
            debugPrint(
              'An unknown error occurred in getProfilesByZipcode: $error',
            );
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
      rethrow;
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
