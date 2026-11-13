// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:io';

import 'package:database_repository/src/media_storage_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

///Repository that interacts with Goolge [CloudRepository]
///and Horse and Rider's Companion
class CloudRepository implements MediaStorageRepository {
  /// Creates a [CloudRepository] backed by [storage] (defaults to
  /// [FirebaseStorage.instance]).
  // ignore: prefer_initializing_formals
  CloudRepository({FirebaseStorage? storage}) : _storage = storage;

  ///Constant to point to the Riders Photo Collection
  static const String RIDERS_PHOTO = 'Riders_Photo';

  ///   Constant pointing to the Horses Photo Collection
  static const String HORSES_PHOTO = 'Horses_Photo';

  final FirebaseStorage? _storage;

  Reference get _storageReference =>
      (_storage ?? FirebaseStorage.instance).ref();

  Future<String?> _uploadPhoto({
    required Reference ref,
    required XFile? file,
  }) async {
    try {
      if (file == null) {
        throw Exception('No file provided for upload');
      }
      if (kIsWeb) {
        final data = await file.readAsBytes();
        await ref.putData(data);
      } else {
        final mobileFile = File(file.path);
        await ref.putFile(mobileFile);
      }
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    } catch (e) {
      debugPrint('Error: $e');
    }
    return null;
  }

  /// Method to add Riders Photo to Cloud Firestore
  @override
  Future<String?> addRiderPhoto({
    required XFile? file,
    required String riderId,
  }) {
    final riderRef = _storageReference.child(RIDERS_PHOTO).child(riderId);
    return _uploadPhoto(ref: riderRef, file: file);
  }

  /// Method to add Horse photo to Cloud Firestore
  @override
  Future<String?> addHorsePhoto({
    required XFile? file,
    required String horseId,
  }) {
    final horseRef = _storageReference.child(HORSES_PHOTO).child(horseId);
    return _uploadPhoto(ref: horseRef, file: file);
  }

  @override
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final ref = _storageReference.child(path);
      final meta = contentType == null
          ? null
          : SettableMetadata(contentType: contentType);
      final uploadTask = ref.putData(bytes, meta);
      StreamSubscription<TaskSnapshot>? sub;
      if (onProgress != null) {
        sub = uploadTask.snapshotEvents.listen((snap) {
          final progress = snap.totalBytes == 0
              ? 0.0
              : snap.bytesTransferred / snap.totalBytes;
          onProgress(progress);
        });
      }
      final TaskSnapshot snapshot;
      try {
        snapshot = await uploadTask;
      } finally {
        await sub?.cancel();
      }
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw MediaStorageException(e.message ?? e.code);
    }
  }
}
