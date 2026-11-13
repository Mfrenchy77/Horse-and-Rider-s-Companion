import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/connection_request.dart';
import 'package:database_repository/src/connection_request_store.dart';

/// Dedicated Firestore [ConnectionRequestStore] backed by the `Requests`
/// collection, independent of legacy `Conversations` and `Messages`.
class FirestoreConnectionRequestStore implements ConnectionRequestStore {
  /// Creates a [FirestoreConnectionRequestStore] using [firestore].
  FirestoreConnectionRequestStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Top-level Firestore collection for dedicated connection requests.
  static const String requestsCollection = 'Requests';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(requestsCollection);

  @override
  Stream<List<ConnectionRequest>> watchRequests({required String userEmail}) {
    final normalizedEmail = userEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return Stream.value(const <ConnectionRequest>[]);
    }
    return _requests
        .where('partiesIds', arrayContains: normalizedEmail)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
          final items = [
            for (final doc in snap.docs)
              ConnectionRequest.fromMap(
                _normalizeTimestamps(doc.data()),
                idFromDoc: doc.id,
              ),
          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  /// Resolves the canonical `Requests` document ID for [request].
  static String docIdFor(ConnectionRequest request) {
    if (request.id.isNotEmpty &&
        request.messageId.isNotEmpty &&
        !request.id.endsWith('_${request.messageId}')) {
      return '${request.id}_${request.messageId}';
    }
    if (request.id.isNotEmpty) return request.id;
    return request.messageId;
  }

  /// Streams deduplication keys for non-pending `Requests` involving
  /// [userEmail] so dual-read stores suppress resolved legacy items.
  Stream<Set<String>> watchResolvedKeys({required String userEmail}) {
    final normalizedEmail = userEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return Stream.value(const <String>{});
    }
    return _requests
        .where('partiesIds', arrayContains: normalizedEmail)
        .snapshots()
        .map((snap) {
          final keys = <String>{};
          for (final doc in snap.docs) {
            final data = doc.data();
            final status = data['status'] as String? ?? 'pending';
            if (status == 'pending') continue;
            final req = ConnectionRequest.fromMap(
              _normalizeTimestamps(data),
              idFromDoc: doc.id,
            );
            keys.add(
              req.messageId.isNotEmpty
                  ? '${req.kind.name}:${req.senderEmail}:${req.messageId}'
                  : '${req.kind.name}:${req.id}',
            );
          }
          return keys;
        });
  }

  @override
  Future<void> sendRequest(ConnectionRequest request) async {
    final resolvedId = docIdFor(request);
    final docId = resolvedId.isNotEmpty ? resolvedId : _requests.doc().id;
    final docRef = _requests.doc(docId);
    final existing = await docRef.get();
    if (existing.exists) return;
    final payload = request.toMap()
      ..['id'] = docId
      ..['createdAt'] = Timestamp.fromDate(request.createdAt)
      ..['updatedAt'] = Timestamp.fromDate(request.createdAt);
    await docRef.set(payload);
  }

  static const Set<String> _clientDismissStatuses = {
    'declined',
    'cancelled',
    'dismissed',
  };

  @override
  Future<void> dismissRequest({
    required ConnectionRequest request,
    required String dismissalNote,
    String status = 'dismissed',
  }) async {
    final docId = docIdFor(request);
    if (docId.isEmpty) return;
    final safeStatus = _clientDismissStatuses.contains(status)
        ? status
        : 'dismissed';
    await _requests.doc(docId).update({
      'status': safeStatus,
      'dismissalNote': dismissalNote,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Map<String, dynamic> _normalizeTimestamps(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    final createdAt = out['createdAt'];
    if (createdAt is Timestamp) {
      out['createdAt'] = createdAt.toDate();
    }
    return out;
  }
}
