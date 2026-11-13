import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories of backend-neutral repository failures.
enum RepositoryFailureKind {
  /// The caller lacks permission to perform the requested operation.
  permissionDenied,

  /// The backend is temporarily unreachable, timed out, or aborted.
  unavailable,

  /// The requested record or collection does not exist.
  notFound,

  /// The caller is not authenticated or their session expired.
  unauthenticated,

  /// The request parameters or preconditions were rejected.
  invalidArgument,

  /// Any other unexpected backend failure.
  unexpected,
}

/// Backend-neutral exception thrown by repositories when a backend operation
/// fails.
class RepositoryException implements Exception {
  /// Creates a [RepositoryException] with a failure [kind], user-facing
  /// [message], and optional backend [code].
  const RepositoryException({
    required this.kind,
    required this.message,
    this.code,
  });

  /// Translates a [FirebaseException] into a backend-neutral
  /// [RepositoryException].
  factory RepositoryException.fromFirebase(FirebaseException error) {
    final kind = switch (error.code) {
      'permission-denied' => RepositoryFailureKind.permissionDenied,
      'unavailable' ||
      'deadline-exceeded' ||
      'aborted' ||
      'resource-exhausted' => RepositoryFailureKind.unavailable,
      'not-found' => RepositoryFailureKind.notFound,
      'unauthenticated' => RepositoryFailureKind.unauthenticated,
      'invalid-argument' ||
      'failed-precondition' => RepositoryFailureKind.invalidArgument,
      _ => RepositoryFailureKind.unexpected,
    };
    return RepositoryException(
      kind: kind,
      message: error.message ?? error.code,
      code: error.code,
    );
  }

  /// High-level category describing the failure.
  final RepositoryFailureKind kind;

  /// Human-readable error message.
  final String message;

  /// Optional provider-specific error code for diagnostics.
  final String? code;

  @override
  String toString() => message;
}

/// Runs [action] and translates any [FirebaseException] into a
/// [RepositoryException].
Future<T> guardFirebase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on FirebaseException catch (e) {
    throw RepositoryException.fromFirebase(e);
  }
}
