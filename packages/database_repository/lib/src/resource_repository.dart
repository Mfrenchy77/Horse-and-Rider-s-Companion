// lib/database_repository/src/resources_repository.dart
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
          ),
      _raw = (firestore ?? FirebaseFirestore.instance).collection(RESOURCES);

  static const String RESOURCES = 'Resources';

  final CollectionReference<Resource> _ref;
  final CollectionReference<Map<String, dynamic>> _raw;

  /// Mint a new random document id (avoids key hotspotting).
  String newId() => _raw.doc().id;

  // ---------------------------------------------------------------------------
  // Core CRUD (type-agnostic)
  // ---------------------------------------------------------------------------

  /// Create or update a resource document (no server timestamps).
  Future<void> createOrUpdateResource({required Resource resource}) async {
    if (resource.id == null) {
      throw ArgumentError('Resource.id must not be null');
    }
    await guardFirebase(
      () => _ref.doc(resource.id).set(resource, SetOptions(merge: true)),
    );
  }

  /// Applies only the chosen link changes to the latest resource document.
  Future<void> updateSkillLinks({
    required String id,
    required Set<String> added,
    required Set<String> removed,
  }) async {
    if (added.isEmpty && removed.isEmpty) return;
    final doc = _raw.doc(id);
    await _raw.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      final data = snapshot.data();
      if (data == null) throw StateError('This resource no longer exists.');
      final current = (data['skillTreeIds'] as List? ?? []).whereType<String>();
      final links = {...current}
        ..removeAll(removed)
        ..addAll(added);
      transaction.update(doc, {'skillTreeIds': links.toList()});
    });
  }

  /// Create a resource and set server timestamps.
  /// - Sets `createdAt` if missing, always bumps `updatedAt`.
  Future<void> createResourceWithServerTimestamps({
    required Resource resource,
  }) async {
    if (resource.id == null) {
      throw ArgumentError('Resource.id must not be null');
    }
    final data = resource.toFirestore();
    await guardFirebase(
      () => _raw.doc(resource.id).set({
        ...data,
        if (!data.containsKey('createdAt'))
          'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  /// Convenience for articles.
  Future<void> createArticle({required Resource resource}) async {
    if (resource.type != ResourceType.article) {
      // Safety: ensure we don't accidentally store wrong type.
      await createResourceWithServerTimestamps(
        resource: resource.copyWith(type: ResourceType.article),
      );
    } else {
      await createResourceWithServerTimestamps(resource: resource);
    }
  }

  /// Stream all resources mapped to domain models.
  Stream<List<Resource>> getResources() {
    return _ref.snapshots().map(
      (snap) => snap.docs.map((d) => d.data()).toList(),
    );
  }

  /// Listen only to resources linked to a particular skill.
  Stream<List<Resource>> getResourcesForSkill({required String skillId}) {
    return _ref
        .where('skillTreeIds', arrayContains: skillId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  /// Optionally, a convenience stream ordered by `updatedAt` desc (if present).
  Stream<List<Resource>> getResourcesOrderedByUpdatedAt() {
    return _ref
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
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

  /// Toggle a comment vote against the latest saved comment, atomically.
  /// Only comments are written, preserving newer resource edits.
  Future<Comment> rateComment({
    required String resourceId,
    required String commentId,
    required String userEmail,
    required int vote,
  }) async {
    if (resourceId.trim().isEmpty ||
        commentId.trim().isEmpty ||
        userEmail.trim().isEmpty ||
        (vote != 1 && vote != -1)) {
      throw ArgumentError(
        'A resource, comment, user and +1/-1 vote are required',
      );
    }
    final ref = _raw.doc(resourceId);
    return _raw.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) throw StateError('Resource no longer exists');
      final comments = List<Map<String, dynamic>>.from(
        (data['comments'] as List? ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      final index = comments.indexWhere((item) => item['id'] == commentId);
      if (index < 0) throw StateError('Comment no longer exists');
      final current = comments[index];
      final ratings = List<Map<String, dynamic>>.from(
        (current['usersWhoRated'] as List? ?? const []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      );
      final previous = ratings.where((item) => item['id'] == userEmail);
      final previousVote = previous.isEmpty
          ? 0
          : previous.first['isSelected'] == true
          ? 1
          : previous.first['isCollapsed'] == true
          ? -1
          : 0;
      final nextVote = previousVote == vote ? 0 : vote;
      ratings.removeWhere((item) => item['id'] == userEmail);
      if (nextVote != 0) {
        ratings.add({
          'id': userEmail,
          'isSelected': nextVote == 1,
          'isCollapsed': nextVote == -1,
        });
      }
      final updated = <String, dynamic>{
        ...current,
        'rating':
            ((current['rating'] as num?)?.toInt() ?? 0) -
            previousVote +
            nextVote,
        'usersWhoRated': ratings,
      };
      comments[index] = updated;
      transaction.update(ref, {'comments': comments});
      return Comment.fromJson(updated);
    });
  }

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
  // Article-focused helpers
  // ---------------------------------------------------------------------------

  /// Stream of **published** articles, newest first.
  /// Optional tag filter via `arrayContainsAny` (up to 10 values).
  Stream<List<Resource>> getPublishedArticles({
    List<String> tagsFilter = const [],
  }) {
    var q = _ref
        .where('type', isEqualTo: 'article')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true);

    if (tagsFilter.isNotEmpty) {
      q = q.where('tags', arrayContainsAny: tagsFilter.take(10).toList());
    }
    return q.snapshots().map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Fetch a single **article** by id (null if not found or not an article).
  Future<Resource?> getArticleById(String id) async {
    final r = await getResourceById(id);
    if (r == null || r.type != ResourceType.article) return null;
    return r;
  }

  /// Update mutable article fields (owner edits).
  /// Sets `updatedAt` server-side.
  Future<void> updateArticleContent({
    required String id,
    String? title,
    String? description,
    String? content,
    List<String>? tags,
    String? coverImageUrl,
  }) async {
    final data = <String, dynamic>{
      if (title != null) 'name': title,
      if (description != null) 'description': description,
      if (content != null) 'content': content,
      if (tags != null) 'tags': tags,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _raw.doc(id).set(data, SetOptions(merge: true));
  }

  /// Admin-only: set article status (also bumps updatedAt).
  Future<void> setArticleStatus({
    required String id,
    required ResourceStatus status,
  }) async {
    await _raw.doc(id).set({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Pagination helpers (optional)
  // ---------------------------------------------------------------------------

  Future<({List<Resource> items, DocumentSnapshot<Resource>? lastDoc})>
  fetchPublishedArticlesPage({
    int limit = 20,
    DocumentSnapshot<Resource>? startAfter,
    List<String> tagsFilter = const [],
  }) async {
    var q = _ref
        .where('type', isEqualTo: 'article')
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true);

    if (tagsFilter.isNotEmpty) {
      q = q.where('tags', arrayContainsAny: tagsFilter.take(10).toList());
    }
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.limit(limit).get();
    return (
      items: snap.docs.map((d) => d.data()).toList(),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
    );
  }
}
