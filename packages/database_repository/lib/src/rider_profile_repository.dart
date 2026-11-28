// ignore_for_file: lines_longer_than_80_chars, constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/logging/app_logger.dart';
import 'package:database_repository/src/mappers/base_list_item_firestore_mapper.dart';
import 'package:database_repository/src/mappers/rider_profile_firestore_mapper.dart';
import 'package:database_repository/src/models/models.dart';
import 'package:database_repository/src/repository_exception.dart';
import 'package:database_repository/src/rider_profile_store.dart';

///Interface for Firebase and Rider's Profile
class RiderProfileRepository implements RiderProfileStore {
  RiderProfileRepository({FirebaseFirestore? firestore})
    : _riderProfileDatabaseReference = (firestore ?? FirebaseFirestore.instance)
          .collection(RIDER_PROFILE)
          .withConverter<RiderProfile>(
            fromFirestore: RiderProfileFirestoreMapper.fromFirestore,
            toFirestore: RiderProfileFirestoreMapper.toFirestore,
          ),
      _publicRiderProfileDatabaseReference =
          (firestore ?? FirebaseFirestore.instance)
              .collection(PUBLIC_RIDER_PROFILE)
              .withConverter<RiderProfile>(
                fromFirestore: RiderProfileFirestoreMapper.fromFirestore,
                toFirestore: RiderProfileFirestoreMapper.toFirestore,
              );

  static const String RIDER_PROFILE = 'Rider_Profile';
  static const String PUBLIC_RIDER_PROFILE = 'Public_Rider_Profile';
  static const String OWNED_HORSES = 'ownedHorses';
  final CollectionReference<RiderProfile> _riderProfileDatabaseReference;
  final CollectionReference<RiderProfile> _publicRiderProfileDatabaseReference;

  ///create or update [riderProfile] for user

  @override
  Future<void> createOrUpdateRiderProfile({
    required RiderProfile riderProfile,
  }) async {
    try {
      await _riderProfileDatabaseReference
          .doc(_convertEmailToPath(email: riderProfile.email))
          .set(riderProfile, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      handleFirebaseException(e);
      throw RepositoryException.fromFirebase(e);
    }
  }

  @override
  Future<void> addOrUpdateOwnedHorse({
    required RiderProfile? riderProfile,
    required String? horseId,
  }) async {
    try {
      await _riderProfileDatabaseReference
          .doc(_convertEmailToPath(email: riderProfile?.email))
          .update({
            OWNED_HORSES: FieldValue.arrayUnion([
              BaseListItemFirestoreMapper.toFirestore(
                BaseListItem(id: horseId),
              ),
            ]),
          });
    } on FirebaseException catch (e) {
      handleFirebaseException(e);
      throw RepositoryException.fromFirebase(e);
    }
  }

  /// Updates the signed-in rider's saved contacts without rewriting their profile.
  @override
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
        'savedProfilesList': [
          ...remaining,
          if (add) BaseListItemFirestoreMapper.toFirestore(contact),
        ],
      });
    });
  }

  /// Writes only the rider's notes, preserving other profile fields.
  @override
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
        'notes': FieldValue.arrayUnion([
          BaseListItemFirestoreMapper.toFirestore(entry),
        ]),
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
      if (!BaseListItemFirestoreMapper.fromMap(
        original,
      ).canEditRiderLog(email)) {
        throw StateError('This log entry cannot be edited.');
      }
      // Preserve legacy fields and any fields this version does not recognize.
      notes[index] = {
        ...original,
        ...BaseListItemFirestoreMapper.toFirestore(entry),
      };
      transaction.update(doc, {'notes': notes});
    });
  }

  /// Retrieve the user's profile using [email]
  @override
  Stream<RiderProfile?> getRiderProfile({required String email}) {
    return _riderProfileDatabaseReference
        .doc(_convertEmailToPath(email: email))
        .snapshots()
        .map((snap) => snap.data())
        .handleError((Object error, StackTrace stackTrace) {
          if (error is FirebaseException) {
            handleFirebaseException(error);
          } else {
            AppLogger.error(
              LogCategory.database,
              'Error in getRiderProfile',
              error: error,
              stackTrace: stackTrace,
            );
          }
        });
  }

  @override
  Future<RiderProfile?> getRiderProfileByEmail({
    required String email,
    bool serverOnly = false,
  }) async {
    final docId = _convertEmailToPath(email: email);
    final options = serverOnly ? const GetOptions(source: Source.server) : null;
    try {
      final snap = await _riderProfileDatabaseReference
          .doc(docId)
          .get(options);
      if (snap.exists) return snap.data();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
    final publicSnap = await _publicRiderProfileDatabaseReference
        .doc(docId)
        .get(options);
    return publicSnap.data();
  }

  /// Retrieve the sanitized public rider profile using [email]
  @override
  Stream<RiderProfile?> getPublicRiderProfile({required String email}) {
    return _publicRiderProfileDatabaseReference
        .doc(_convertEmailToPath(email: email))
        .snapshots()
        .map((snap) => snap.data())
        .handleError((Object error, StackTrace stackTrace) {
          if (error is FirebaseException) {
            handleFirebaseException(error);
          } else {
            AppLogger.error(
              LogCategory.database,
              'Error in getPublicRiderProfile',
              error: error,
              stackTrace: stackTrace,
            );
          }
        });
  }

  ///Retrieve a single public rider profile by [name]
  @override
  Stream<RiderProfile?> getProfileByName({required String name}) {
    return _publicRiderProfileDatabaseReference
        .where('name', isEqualTo: name)
        .get()
        .asStream()
        .map((event) => event.docs.isNotEmpty ? event.docs.first.data() : null)
        .handleError((Object error, StackTrace stackTrace) {
          if (error is FirebaseException) {
            handleFirebaseException(error);
          } else {
            AppLogger.error(
              LogCategory.database,
              'Error in getProfileByName',
              error: error,
              stackTrace: stackTrace,
            );
          }
        });
  }

  /// Retrieve all public rider profiles for [name]
  @override
  Stream<List<RiderProfile>> getProfilesByName({required String name}) {
    return _publicRiderProfileDatabaseReference
        .where('name', isGreaterThanOrEqualTo: name)
        .where('name', isLessThanOrEqualTo: '$name\uf8ff')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((Object error, StackTrace stackTrace) {
          if (error is FirebaseException) {
            handleFirebaseException(error);
          } else {
            AppLogger.error(
              LogCategory.database,
              'Error in getProfilesByName',
              error: error,
              stackTrace: stackTrace,
            );
          }
        });
  }

  /// Retrieve all public rider profiles for zipcode
  @override
  Stream<List<RiderProfile>> getProfilesByZipcode({required String zipcode}) {
    return _publicRiderProfileDatabaseReference
        .where('zipCode', isEqualTo: zipcode)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((Object error, StackTrace stackTrace) {
          if (error is FirebaseException) {
            handleFirebaseException(error);
          } else {
            AppLogger.error(
              LogCategory.database,
              'Error in getProfilesByZipcode',
              error: error,
              stackTrace: stackTrace,
            );
          }
        });
  }

  /// Delete user's RiderProfile at [email]
  @override
  Future<void> deleteRiderProfile({required String email}) async {
    try {
      await _riderProfileDatabaseReference
          .doc(_convertEmailToPath(email: email))
          .delete();
    } on FirebaseException catch (e) {
      handleFirebaseException(e);
      throw RepositoryException.fromFirebase(e);
    }
  }

  /// Returns the canonical Firestore `Rider_Profile` document ID for [email].
  static String profileDocIdForEmail(String email) {
    return _convertEmailToPath(email: email.trim().toLowerCase());
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
      AppLogger.warning(LogCategory.database, 'Firestore document not found');
    case 'permission-denied':
      AppLogger.warning(LogCategory.database, 'Firestore permission denied');
    default:
      AppLogger.error(
        LogCategory.database,
        'Firestore operation failed (${exception.code})',
        error: exception.message,
      );
  }
}
