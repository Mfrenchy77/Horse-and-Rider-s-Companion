// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

///Repository that interacts with Goolge [CloudRepository]
///and Horse and Rider's Companion
class CloudRepository {
  ///Constant to point to the Riders Photo Collection
  static const String RIDERS_PHOTO = 'Riders_Photo';

  ///   Constant pointing to the Horses Photo Collection
  static const String HORSES_PHOTO = 'Horses_Photo';

  final _storageReference = FirebaseStorage.instance.ref();

  ///   Method to add Riders Photo to Cloud Firestore
  ///   returns the url or null
  Future<String?> addRiderPhoto({
    required String path,
    required String riderId,
  }) async {
    final riderRef = _storageReference.child(RIDERS_PHOTO).child(riderId);
    final file = File(path);
    try {
      await riderRef.putFile(file);
      return await riderRef.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  ///   Method to add Horse photo to Cloud Firestore
  ///    returns the url or null
  Future<String?> addHorsePhoto({
    required String path,
    required String horseId,
  }) async {
    final horseRef = _storageReference.child(HORSES_PHOTO).child(horseId);
    final file = File(path);
    try {
      await horseRef.putFile(file);
      return horseRef.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }
}
