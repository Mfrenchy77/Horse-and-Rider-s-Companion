import 'dart:async';

import 'package:database_repository/src/connection_request.dart';
import 'package:database_repository/src/connection_request_store.dart';
import 'package:database_repository/src/firestore_connection_request_store.dart';

/// In-memory [ConnectionRequestStore] for unit, widget, and integration tests.
class InMemoryConnectionRequestStore implements ConnectionRequestStore {
  /// Creates an [InMemoryConnectionRequestStore], optionally pre-populated with
  /// [initialRequests].
  InMemoryConnectionRequestStore({
    Iterable<ConnectionRequest> initialRequests = const [],
  }) {
    for (final request in initialRequests) {
      final docId = _resolveDocId(request);
      _items[docId] = request;
    }
  }

  final Map<String, ConnectionRequest> _items = <String, ConnectionRequest>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  static const Set<String> _clientDismissStatuses = {
    'declined',
    'cancelled',
    'dismissed',
  };

  static String _resolveDocId(ConnectionRequest request) {
    final resolved = FirestoreConnectionRequestStore.docIdFor(request);
    if (resolved.isNotEmpty) return resolved;
    return '${request.kind.name}:${request.senderEmail}:'
        '${request.recipientEmail}';
  }

  /// Current pending requests involving [userEmail], sorted newest first.
  List<ConnectionRequest> pendingFor(String userEmail) {
    final normalized = userEmail.trim().toLowerCase();
    if (normalized.isEmpty) return const <ConnectionRequest>[];
    final items = _items.values
        .where(
          (r) =>
              r.status == 'pending' &&
              !r.isAccepted &&
              (r.partiesIds.map((e) => e.toLowerCase()).contains(normalized) ||
                  r.senderEmail.toLowerCase() == normalized ||
                  r.recipientEmail.toLowerCase() == normalized),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// All stored requests (including accepted/dismissed), for test assertions.
  List<ConnectionRequest> get allRequests => List.unmodifiable(_items.values);

  @override
  Stream<List<ConnectionRequest>> watchRequests({required String userEmail}) {
    late final StreamController<List<ConnectionRequest>> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<List<ConnectionRequest>>(
      onListen: () {
        controller.add(pendingFor(userEmail));
        sub = _changes.stream.listen((_) {
          if (!controller.isClosed) {
            controller.add(pendingFor(userEmail));
          }
        });
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> sendRequest(ConnectionRequest request) async {
    final docId = _resolveDocId(request);
    if (_items.containsKey(docId)) return;
    _items[docId] = ConnectionRequest.fromMap({
      ...request.toMap(),
      'id': docId,
    }, idFromDoc: docId);
    _changes.add(null);
  }

  @override
  Future<void> dismissRequest({
    required ConnectionRequest request,
    required String dismissalNote,
    String status = 'dismissed',
  }) async {
    final safeStatus = _clientDismissStatuses.contains(status)
        ? status
        : 'dismissed';
    final docId = _resolveDocId(request);
    final existing = _items[docId] ?? _findMatching(request);
    if (existing == null || existing.status != 'pending') return;
    final key = _items.containsKey(docId) ? docId : _resolveDocId(existing);
    _items[key] = ConnectionRequest.fromMap({
      ...existing.toMap(),
      'status': safeStatus,
      'dismissalNote': dismissalNote,
    }, idFromDoc: existing.id);
    _changes.add(null);
  }

  /// Marks [request] as accepted (used by fake/emulator backend handlers in tests).
  Future<void> markAccepted(ConnectionRequest request) async {
    final docId = _resolveDocId(request);
    final existing = _items[docId] ?? _findMatching(request);
    if (existing == null) return;
    final key = _items.containsKey(docId) ? docId : _resolveDocId(existing);
    _items[key] = ConnectionRequest.fromMap({
      ...existing.toMap(),
      'status': 'accepted',
      'isAccepted': true,
    }, idFromDoc: existing.id);
    _changes.add(null);
  }

  ConnectionRequest? _findMatching(ConnectionRequest target) {
    for (final item in _items.values) {
      if (item.id == target.id &&
          (target.messageId.isEmpty || item.messageId == target.messageId)) {
        return item;
      }
    }
    return null;
  }

  /// Closes the underlying change stream.
  Future<void> dispose() => _changes.close();
}
