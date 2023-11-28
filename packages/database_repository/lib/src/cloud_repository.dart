// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

///Repository that interacts with Goolge [CloudRepository]
///and Horse and Rider's Companion
class CloudRepository {
  ///Constant to point to the Riders Photo Collection
  static const String RIDERS_PHOTO = 'Riders_Photo';

  ///   Constant pointing to the Horses Photo Collection
  static const String HORSES_PHOTO = 'Horses_Photo';

  final _storageReference = FirebaseStorage.instance.ref();

  /// Method to add Riders Photo to Cloud Firestore
  Future<String?> addRiderPhoto({
    String? path, // For mobile
    Uint8List? data, // For web
    required String riderId,
  }) async {
    final riderRef = _storageReference.child(RIDERS_PHOTO).child(riderId);

    try {
      if (kIsWeb && data != null) {
        // Web upload logic
        await riderRef.putData(data);
      } else if (path != null) {
        // Mobile upload logic
        final file = File(path);
        await riderRef.putFile(file);
      } else {
        throw Exception('No data provided for upload');
      }
      return await riderRef.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    } catch (e) {
      debugPrint('Error: $e');
    }
    return null;
  }

  /// Method to add Horse photo to Cloud Firestore
  Future<String?> addHorsePhoto({
    String? path, // For mobile
    Uint8List? data, // For web
    required String horseId,
  }) async {
    final horseRef = _storageReference.child(HORSES_PHOTO).child(horseId);

    try {
      if (kIsWeb && data != null) {
        // Web upload logic
        await horseRef.putData(data);
      } else if (path != null) {
        // Mobile upload logic
        final file = File(path);
        await horseRef.putFile(file);
      } else {
        throw Exception('No data provided for upload');
      }
      return await horseRef.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    } catch (e) {
      debugPrint('Error: $e');
    }
    return null;
  }
}
