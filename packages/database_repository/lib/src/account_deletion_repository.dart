/// Outcome status for an account deletion request.
enum AccountDeletionStatus {
  /// All backend cleanup and identity removal completed.
  completed,

  /// Deletion has been durably queued and is completing asynchronously.
  scheduled,

  /// The user must reauthenticate before deletion can proceed.
  requiresRecentLogin,
}

/// Result returned by [AccountDeletionRepository.deleteCurrentAccount].
class AccountDeletionResult {
  /// Creates an [AccountDeletionResult].
  const AccountDeletionResult({
    required this.status,
    this.message,
  });

  /// Outcome status of the deletion request.
  final AccountDeletionStatus status;

  /// Optional human-readable status message.
  final String? message;
}

/// Backend-neutral failure thrown when account deletion fails.
class AccountDeletionFailure implements Exception {
  /// Creates an [AccountDeletionFailure].
  const AccountDeletionFailure([
    this.message = 'Account deletion could not be completed. Please try again.',
  ]);

  /// Human-readable failure message.
  final String message;

  @override
  String toString() => message;
}

/// Backend-neutral interface for requesting durable account deletion.
// ignore: one_member_abstracts
abstract interface class AccountDeletionRepository {
  /// Requests deletion of the currently authenticated user's account and data.
  Future<AccountDeletionResult> deleteCurrentAccount();
}
