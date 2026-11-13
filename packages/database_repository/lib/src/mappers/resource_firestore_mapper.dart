import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/mappers/base_list_item_firestore_mapper.dart';
import 'package:database_repository/src/mappers/comment_firestore_mapper.dart';
import 'package:database_repository/src/models/base_list_item.dart';
import 'package:database_repository/src/models/comment.dart';
import 'package:database_repository/src/models/resource.dart';

/// Firestore persistence mapper for [Resource].
class ResourceFirestoreMapper {
  const ResourceFirestoreMapper._();

  /// Converts a Firestore map (which may contain [Timestamp]s) into a
  /// [Resource].
  static Resource fromMap(Map<String, dynamic> data, {String? idFromDoc}) {
    final normalized = Map<String, dynamic>.from(data);
    final rawCreatedAt = normalized['createdAt'];
    if (rawCreatedAt is Timestamp) {
      normalized['createdAt'] = rawCreatedAt.toDate();
    }
    final rawLastEditDate = normalized['lastEditDate'];
    if (rawLastEditDate is Timestamp) {
      normalized['lastEditDate'] = rawLastEditDate.toDate();
    }

    final rawComments = normalized.remove('comments');
    final rawUsersWhoRated = normalized.remove('usersWhoRated');

    final base = Resource.fromMap(normalized, idFromDoc: idFromDoc);

    List<Comment>? comments;
    if (rawComments is List) {
      comments = <Comment>[];
      for (final item in rawComments) {
        if (item is Map<String, dynamic>) {
          comments.add(CommentFirestoreMapper.fromMap(item));
        } else if (item is Map) {
          comments.add(
            CommentFirestoreMapper.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    List<BaseListItem>? usersWhoRated;
    if (rawUsersWhoRated is List) {
      usersWhoRated = <BaseListItem>[];
      for (final item in rawUsersWhoRated) {
        if (item is Map<String, dynamic>) {
          usersWhoRated.add(BaseListItemFirestoreMapper.fromMap(item));
        } else if (item is Map) {
          usersWhoRated.add(
            BaseListItemFirestoreMapper.fromMap(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return base.copyWith(
      comments: comments,
      usersWhoRated: usersWhoRated,
    );
  }

  /// Converts a Firestore [DocumentSnapshot] into a [Resource].
  static Resource fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return fromMap(map, idFromDoc: snapshot.id);
  }

  /// Converts a [Resource] into a Firestore-compatible document map,
  /// preserving `Timestamp` fields, omitted vs explicit nulls, and legacy
  /// nested [Comment] / [BaseListItem] formats.
  static Map<String, Object?> toFirestore(
    Resource resource, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    Timestamp? toTimestamp(DateTime? d) =>
        d == null ? null : Timestamp.fromDate(d);
    return {
      // Keep 'id' for backward-compat with docs that stored it.
      'id': resource.id,
      if (resource.url != null) 'url': resource.url,
      if (resource.name != null) 'name': resource.name,
      if (resource.rating != null) 'rating': resource.rating,
      if (resource.type != null) 'type': resource.type!.name,
      if (resource.content != null) 'content': resource.content,
      if (resource.status != null) 'status': resource.status!.name,
      if (resource.authorId != null) 'authorId': resource.authorId,
      if (resource.thumbnail != null) 'thumbnail': resource.thumbnail,
      if (resource.lastEditBy != null) 'lastEditBy': resource.lastEditBy,
      if (resource.authorName != null) 'authorName': resource.authorName,
      if (resource.createdAt != null)
        'createdAt': toTimestamp(resource.createdAt),
      if (resource.tags != null) 'tags': resource.tags,
      if (resource.authorPhoto != null) 'authorPhoto': resource.authorPhoto,
      if (resource.description != null) 'description': resource.description,
      if (resource.numberOfRates != null)
        'numberOfRates': resource.numberOfRates,
      if (resource.coverImageUrl != null)
        'coverImageUrl': resource.coverImageUrl,
      'skillTreeIds': resource.skillTreeIds,
      'blocksEmbedding': resource.blocksEmbedding,
      if (resource.lastEditDate != null)
        'lastEditDate': toTimestamp(resource.lastEditDate),
      if (resource.usersWhoRated != null)
        'usersWhoRated': List<dynamic>.from(
          resource.usersWhoRated!.map((e) => e.toJson()),
        ),
      if (resource.comments != null)
        'comments': List<dynamic>.from(
          resource.comments!.map(CommentFirestoreMapper.toJson),
        ),
    };
  }
}
