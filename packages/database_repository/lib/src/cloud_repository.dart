// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

///Repository that interacts with Goolge [CloudRepository]
///and Horse and Rider's Companion
class CloudRepository {
  ///Constant to point to the Riders Photo Collection
  static const String RIDERS_PHOTO = 'Riders_Photo';

  ///   Constant pointing to the Horses Photo Collection
  static const String HORSES_PHOTO = 'Horses_Photo';

  final _storageReference = FirebaseStorage.instance.ref();

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
  Future<String?> addRiderPhoto({
    required XFile? file,
    required String riderId,
  }) {
    final riderRef = _storageReference.child(RIDERS_PHOTO).child(riderId);
    return _uploadPhoto(ref: riderRef, file: file);
  }

  /// Method to add Horse photo to Cloud Firestore
  Future<String?> addHorsePhoto({
    required XFile? file,
    required String horseId,
  }) {
    final horseRef = _storageReference.child(HORSES_PHOTO).child(horseId);
    return _uploadPhoto(ref: horseRef, file: file);
  }
}
