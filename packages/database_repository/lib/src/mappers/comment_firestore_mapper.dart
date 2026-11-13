import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/mappers/base_list_item_firestore_mapper.dart';
import 'package:database_repository/src/models/comment.dart';

/// Firestore persistence mapper for [Comment].
class CommentFirestoreMapper {
  const CommentFirestoreMapper._();

  /// Converts a Firestore map (which may contain [Timestamp]s) into a
  /// [Comment].
  static Comment fromMap(Map<String, dynamic> data) {
    final rawUsers = data['usersWhoRated'] as List?;
    final usersWhoRated = rawUsers
        ?.map(
          (item) => BaseListItemFirestoreMapper.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final rawUser = data['user'];
    final user = rawUser == null
        ? null
        : BaseListItemFirestoreMapper.fromMap(
            Map<String, dynamic>.from(rawUser as Map),
          );

    return Comment(
      id: data['id'] as String?,
      rating: data['rating'] as int?,
      comment: data['comment'] as String?,
      parentId: data['parentId'] as String?,
      resourceId: data['resourceId'] as String?,
      date: _parseDateTime(data['date']),
      editedDate: _parseNullableDateTime(data['editedDate']),
      usersWhoRated: usersWhoRated,
      user: user,
    );
  }

  /// Converts a Firestore [DocumentSnapshot] into a [Comment].
  static Comment fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    return fromMap(snapshot.data()!);
  }

  /// Converts a [Comment] into a Firestore-compatible document map (omitting
  /// null optional fields, matching legacy `Comment.toFirestore`).
  static Map<String, Object?> toFirestore(
    Comment comment, [
    // ignore: avoid_unused_constructor_parameters
    SetOptions? options,
  ]) {
    return {
      if (comment.id != null) 'id': comment.id,
      'date': comment.date,
      if (comment.user != null)
        'user': BaseListItemFirestoreMapper.toFirestore(comment.user!),
      if (comment.rating != null) 'rating': comment.rating,
      if (comment.comment != null) 'comment': comment.comment,
      if (comment.parentId != null) 'parentId': comment.parentId,
      if (comment.editedDate != null) 'editedDate': comment.editedDate,
      if (comment.resourceId != null) 'resourceId': comment.resourceId,
      if (comment.usersWhoRated != null)
        'usersWhoRated': List<dynamic>.from(
          comment.usersWhoRated!.map(BaseListItemFirestoreMapper.toFirestore),
        ),
    };
  }

  /// Converts a [Comment] into a Firestore-compatible map preserving null keys
  /// (matching legacy `Comment.toJson` used inside `Resource.toFirestore`).
  static Map<String, dynamic> toJson(Comment comment) {
    return {
      'id': comment.id,
      'date': comment.date,
      'rating': comment.rating,
      'comment': comment.comment,
      'parentId': comment.parentId,
      'user': comment.user == null
          ? null
          : BaseListItemFirestoreMapper.toFirestore(comment.user!),
      'editedDate': comment.editedDate,
      'resourceId': comment.resourceId,
      'usersWhoRated': comment.usersWhoRated
          ?.map(BaseListItemFirestoreMapper.toFirestore)
          .toList(),
    };
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw ArgumentError('Expected Timestamp or DateTime, got $value');
  }

  static DateTime? _parseNullableDateTime(Object? value) {
    if (value == null) return null;
    return _parseDateTime(value);
  }
}
