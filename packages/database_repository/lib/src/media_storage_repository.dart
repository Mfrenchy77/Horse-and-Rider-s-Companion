import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Backend-neutral exception thrown when media storage operations fail.
class MediaStorageException implements Exception {
  /// Creates a [MediaStorageException] with a user-facing [message].
  const MediaStorageException(this.message);

  /// Error message describing the failure.
  final String message;

  @override
  String toString() => message;
}

/// Backend-neutral interface for media file uploads.
abstract interface class MediaStorageRepository {
  /// Uploads a rider profile photo and returns its download URL, or `null`
  /// if the upload could not be completed.
  Future<String?> addRiderPhoto({
    required XFile? file,
    required String riderId,
  });

  /// Uploads a horse profile photo and returns its download URL, or `null`
  /// if the upload could not be completed.
  Future<String?> addHorsePhoto({
    required XFile? file,
    required String horseId,
  });

  /// Uploads raw [bytes] to [path] with optional [contentType] metadata and
  /// [onProgress] callback (0.0–1.0), returning the resulting download URL.
  Future<String> uploadBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    void Function(double progress)? onProgress,
  });
}
