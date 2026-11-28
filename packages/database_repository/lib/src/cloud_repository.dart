// ignore_for_file: constant_identifier_names, prefer_initializing_formals

import 'dart:async';
import 'dart:io';

import 'package:database_repository/src/logging/app_logger.dart';
import 'package:database_repository/src/media_storage_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

///Repository that interacts with Goolge [CloudRepository]
///and Horse and Rider's Companion
class CloudRepository implements MediaStorageRepository {
  /// Creates a [CloudRepository] backed by [storage] (defaults to
  /// [FirebaseStorage.instance]).
  CloudRepository({
    FirebaseStorage? storage,
    firebase_auth.FirebaseAuth? auth,
    String? Function()? currentUidProvider,
  }) : _storage = storage,
       _auth = auth,
       _currentUidProvider = currentUidProvider;

  ///Constant to point to the Riders Photo Collection
  static const String RIDERS_PHOTO = 'Riders_Photo';

  ///   Constant pointing to the Horses Photo Collection
  static const String HORSES_PHOTO = 'Horses_Photo';

  final FirebaseStorage? _storage;
  final firebase_auth.FirebaseAuth? _auth;
  final String? Function()? _currentUidProvider;

  String? _resolveUid() {
    final provided = _currentUidProvider?.call()?.trim();
    if (provided != null && provided.isNotEmpty) return provided;
    try {
      if (_auth != null) {
        final uid = _auth.currentUser?.uid.trim();
        return (uid == null || uid.isEmpty) ? null : uid;
      }
      if (Firebase.apps.isNotEmpty) {
        final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid.trim();
        return (uid == null || uid.isEmpty) ? null : uid;
      }
    } catch (_) {}
    return null;
  }

  Reference get _storageReference =>
      (_storage ?? FirebaseStorage.instance).ref();

  String _inferImageContentType(XFile file) {
    final mime = file.mimeType?.trim().toLowerCase();
    if (mime != null && mime.startsWith('image/')) {
      return mime;
    }
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<String?> _uploadPhoto({
    required Reference ref,
    required XFile? file,
  }) async {
    try {
      if (file == null) {
        throw Exception('No file provided for upload');
      }
      final metadata = SettableMetadata(
        contentType: _inferImageContentType(file),
        cacheControl: 'public, max-age=86400',
      );
      if (kIsWeb) {
        final data = await file.readAsBytes();
        await ref.putData(data, metadata);
      } else {
        final mobileFile = File(file.path);
        await ref.putFile(mobileFile, metadata);
      }
      return await ref.getDownloadURL();
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.warning(
        LogCategory.storage,
        'Firebase storage upload failed',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        LogCategory.storage,
        'Unexpected photo upload error',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  /// Method to add Riders Photo to Cloud Firestore
  @override
  Future<String?> addRiderPhoto({
    required XFile? file,
    required String riderId,
  }) {
    final uid = _resolveUid();
    final ridersRoot = _storageReference.child(RIDERS_PHOTO);
    final riderRef = uid != null
        ? ridersRoot.child(uid).child(riderId)
        : ridersRoot.child(riderId);
    return _uploadPhoto(ref: riderRef, file: file);
  }

  /// Method to add Horse photo to Cloud Firestore
  @override
  Future<String?> addHorsePhoto({
    required XFile? file,
    required String horseId,
  }) {
    final uid = _resolveUid();
    final horsesRoot = _storageReference.child(HORSES_PHOTO);
    final horseRef = uid != null
        ? horsesRoot.child(uid).child(horseId)
        : horsesRoot.child(horseId);
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
      final meta = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=31536000',
      );
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
    } on FirebaseException catch (e, stackTrace) {
      final firstSegment = path.trim().split('/').firstWhere(
        (s) => s.isNotEmpty,
        orElse: () => 'root',
      );
      AppLogger.warning(
        LogCategory.storage,
        'Firebase storage uploadBytes failed (${e.code}) '
        '[prefix=$firstSegment, contentType=${contentType ?? 'unknown'}, '
        'bytes=${bytes.length}]',
        error: e,
        stackTrace: stackTrace,
      );
      throw MediaStorageException(e.message ?? e.code, code: e.code);
    }
  }

  @override
  Future<void> deleteByUrl(String url) async {
    try {
      await (_storage ?? FirebaseStorage.instance).refFromURL(url).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      throw MediaStorageException(e.message ?? e.code, code: e.code);
    }
  }
}
