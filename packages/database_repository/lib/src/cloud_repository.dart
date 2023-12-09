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

  /// Method to add Riders Photo to Cloud Firestore
  Future<String?> addRiderPhoto({
    required XFile? file,
    required String riderId,
  }) async {
    final riderRef = _storageReference.child(RIDERS_PHOTO).child(riderId);

    try {
      if (file != null) {
        if (kIsWeb) {
          // Web upload logic
          final data = await file.readAsBytes();
          await riderRef.putData(data);
        } else {
          // Mobile upload logic
          final mobileFile = File(file.path);
          await riderRef.putFile(mobileFile);
        }
        return await riderRef.getDownloadURL();
      } else {
        throw Exception('No file provided for upload');
      }
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    } catch (e) {
      debugPrint('Error: $e');
    }
    return null;
  }

  /// Method to add Horse photo to Cloud Firestore
  Future<String?> addHorsePhoto({
    required XFile? file,
    required String horseId,
  }) async {
    final horseRef = _storageReference.child(HORSES_PHOTO).child(horseId);

    try {
      if (file != null) {
        if (kIsWeb) {
          // Web upload logic
          final data = await file.readAsBytes();
          await horseRef.putData(data);
        } else {
          // Mobile upload logic
          final mobileFile = File(file.path);
          await horseRef.putFile(mobileFile);
        }
        return await horseRef.getDownloadURL();
      } else {
        throw Exception('No file provided for upload');
      }
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    } catch (e) {
      debugPrint('Error: $e');
    }
    return null;
  }
}
