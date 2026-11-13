import 'package:database_repository/src/connection_request.dart';

/// Backend-neutral interface for creating, streaming, and dismissing
/// rider/horse connection and transfer requests.
abstract interface class ConnectionRequestStore {
  /// Streams active connection/transfer requests involving [userEmail].
  Stream<List<ConnectionRequest>> watchRequests({required String userEmail});

  /// Persists a new or updated [request].
  Future<void> sendRequest(ConnectionRequest request);

  /// Dismisses/denies/cancels [request] with [dismissalNote].
  Future<void> dismissRequest({
    required ConnectionRequest request,
    required String dismissalNote,
    String status = 'dismissed',
  });
}
