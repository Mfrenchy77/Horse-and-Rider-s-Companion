import 'package:database_repository/src/models/models.dart';

/// Backend-neutral interface for resources, articles, and comment ratings.
abstract interface class ResourcesStore {
  /// Generates a new unique resource identifier.
  String newId();

  /// Creates or updates [resource].
  Future<void> createOrUpdateResource({required Resource resource});

  /// Atomically applies [added] and [removed] skill links to resource [id].
  Future<void> updateSkillLinks({
    required String id,
    required Set<String> added,
    required Set<String> removed,
  });

  /// Creates or updates [resource] with backend-managed timestamps.
  Future<void> createResourceWithServerTimestamps({required Resource resource});

  /// Creates an article resource with backend-managed timestamps.
  Future<void> createArticle({required Resource resource});

  /// Streams all resources.
  Stream<List<Resource>> getResources();

  /// Streams resources linked to [skillId].
  Stream<List<Resource>> getResourcesForSkill({required String skillId});

  /// Streams resources ordered by `updatedAt` descending.
  Stream<List<Resource>> getResourcesOrderedByUpdatedAt();

  /// Fetches a single resource by [id].
  Future<Resource?> getResourceById(String id);

  /// Deletes [resource].
  Future<void> deleteResource({required Resource resource});

  /// Toggles a comment vote atomically and returns the updated [Comment].
  Future<Comment> rateComment({
    required String resourceId,
    required String commentId,
    required String userEmail,
    required int vote,
  });

  /// Updates a user's rating item on [resource].
  Future<void> editResourceRating({
    required Resource resource,
    required BaseListItem userWhoRated,
  });

  /// Streams published articles, optionally filtered by [tagsFilter].
  Stream<List<Resource>> getPublishedArticles({
    List<String> tagsFilter = const [],
  });

  /// Fetches a single article by [id].
  Future<Resource?> getArticleById(String id);

  /// Updates mutable fields on an article.
  Future<void> updateArticleContent({
    required String id,
    String? title,
    String? description,
    String? content,
    List<String>? tags,
    String? coverImageUrl,
  });

  /// Sets the publication [status] of an article.
  Future<void> setArticleStatus({
    required String id,
    required ResourceStatus status,
  });
}
