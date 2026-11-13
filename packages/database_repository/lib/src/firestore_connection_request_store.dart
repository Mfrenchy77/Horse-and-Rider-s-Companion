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

  @override
  Future<void> sendRequest(ConnectionRequest request) async {
    final docId = request.id.isNotEmpty
        ? request.id
        : _requests.doc().id;
    final payload = request.toMap()
      ..['id'] = docId
      ..['createdAt'] = Timestamp.fromDate(request.createdAt)
      ..['updatedAt'] = Timestamp.fromDate(request.createdAt);
    await _requests.doc(docId).set(payload);
  }

  @override
  Future<void> dismissRequest({
    required ConnectionRequest request,
    required String dismissalNote,
  }) async {
    if (request.id.isEmpty) return;
    await _requests.doc(request.id).update({
      'status': 'dismissed',
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
