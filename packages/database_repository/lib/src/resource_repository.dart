// ignore_for_file: constant_identifier_names, public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart'; // exports Resource, BaseListItem

/// CRUD interface for Firebase Resources.
/// - Collection: "Resources"
/// - Uses Firestore's withConverter to (de)serialize the refined Resource model
/// - Keeps repository slim: Cubits/UseCases build the Resource instance.
class ResourcesRepository {
  ResourcesRepository({FirebaseFirestore? firestore})
      : _ref = (firestore ?? FirebaseFirestore.instance)
            .collection(RESOURCES)
            .withConverter<Resource>(
              fromFirestore: Resource.fromFirestore,
              toFirestore: (Resource resource, SetOptions? _) =>
                  resource.toFirestore(),
            );
  static const String RESOURCES = 'Resources';

  final CollectionReference<Resource> _ref;

  // ---------------------------------------------------------------------------
  // Core CRUD (type-agnostic)
  // ---------------------------------------------------------------------------

  /// Create or update a resource document.
  /// - Provide a fully-formed `Resource` from your Cubit.
  /// - Uses `merge:true` so you can do partial updates safely.
  Future<void> createOrUpdateResource({required Resource resource}) async {
    if (resource.id == null) {
      throw ArgumentError('Resource.id must not be null');
    }
    await _ref.doc(resource.id).set(resource, SetOptions(merge: true));
  }

  /// Stream all resources (no ordering to avoid index issues on legacy docs).
  Stream<QuerySnapshot<Resource>> getResources() => _ref.snapshots();

  /// Optionally, a convenience stream ordered by `updatedAt` desc (if present).
  Stream<QuerySnapshot<Resource>> getResourcesOrderedByUpdatedAt() {
    return _ref.orderBy('updatedAt', descending: true).snapshots();
  }

  /// Fetch a single resource by id (returns null if not found).
  Future<Resource?> getResourceById(String id) async {
    final snap = await _ref.doc(id).get();
    return snap.data();
  }

  /// Delete resource.
  Future<void> deleteResource({required Resource resource}) async {
    await _ref.doc(resource.id).delete();
  }

  // ---------------------------------------------------------------------------
  // Ratings (kept for backward compatibility with your existing schema)
  // Stores per-user rating items in a subcollection: usersWhoRated/{userId}
  // ---------------------------------------------------------------------------

  Future<void> editResourceRating({
    required Resource resource,
    required BaseListItem userWhoRated,
  }) async {
    final ratingsRef = _ref
        .doc(resource.id)
        .collection('usersWhoRated')
        .withConverter<BaseListItem>(
          fromFirestore: BaseListItem.fromFirestore,
          toFirestore: (BaseListItem b, SetOptions? _) => b.toFirestore(),
        );

    await ratingsRef.doc(userWhoRated.id).set(userWhoRated);
  }

  // ---------------------------------------------------------------------------
  // Article-focused helpers (non-intrusive; repo stays generic otherwise)
  // ---------------------------------------------------------------------------

  /// Stream of **published** articles, newest first.
  /// Optional tag filter via `arrayContainsAny` (up to 10 values).
  Stream<QuerySnapshot<Resource>> getPublishedArticles({
    List<String> tagsFilter = const [],
  }) {
    var q = _ref
        .where('type', isEqualTo: 'article')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true);

    if (tagsFilter.isNotEmpty) {
      q = q.where('tags', arrayContainsAny: tagsFilter.take(10).toList());
    }
    return q.snapshots();
  }

  /// Fetch a single **article** by id (null if not found or not an article).
  Future<Resource?> getArticleById(String id) async {
    final r = await getResourceById(id);
    if (r == null || r.type != ResourceType.article) return null;
    return r;
  }

  /// Update mutable article fields (owner edits).
  /// Pass only the fields you want to change; `updatedAt` is set server-side.
  Future<void> updateArticleContent({
    required String id,
    String? title,
    String? description,
    String? content,
    List<String>? tags,
    String? coverImageUrl,
  }) async {
    final data = <String, dynamic>{
      if (title != null) 'name': title, // model uses `name` as title
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _ref.doc(id).update(data);
  }

  /// Admin-only: set article status.
  Future<void> setArticleStatus({
    required String id,
    required ResourceStatus status,
  }) async {
    await _ref.doc(id).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Pagination helpers (optional)
  // ---------------------------------------------------------------------------

  /// Page through published articles. Returns items + lastDoc for next page.
  Future<
      ({
        List<Resource> items,
        DocumentSnapshot<Resource>? lastDoc,
      })> fetchPublishedArticlesPage({
    int limit = 20,
    DocumentSnapshot<Resource>? startAfter,
    List<String> tagsFilter = const [],
  }) async {
    var q = _ref
        .where('type', isEqualTo: 'article')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (tagsFilter.isNotEmpty) {
      q = q.where('tags', arrayContainsAny: tagsFilter.take(10).toList());
    }
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.get();
    return (
      items: snap.docs.map((d) => d.data()).toList(),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last
    );
  }
}
