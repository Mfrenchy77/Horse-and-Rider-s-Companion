import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

/// Model that represents a comment on a resource
class Comment {
  /// Constructor for a comment
  Comment({
    required this.id,
    required this.user,
    required this.date,
    required this.rating,
    required this.comment,
    required this.parentId,
    required this.resourceId,
    required this.usersWhoRated,
  });

  /// Id of the comment
  final String? id;

  /// The rating of the comment
  int? rating;

  /// The date the comment was made
  final DateTime? date;

  /// The comment
  final String? comment;

  /// Parent id, if the comment is a reply
  final String? parentId;

  /// Id of the resource that the comment is on
  final String? resourceId;

  /// User who made the comment
  final BaseListItem? user;

  /// List of users who rated this comment
  List<BaseListItem>? usersWhoRated;

  /// Converts a comment to a map for Firestore
  // ignore: sort_constructors_first
  factory Comment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Comment(
      id: data!['id'] as String?,
      rating: data['rating'] as int?,
      comment: data['comment'] as String?,
      parentId: data['parentId'] as String?,
      resourceId: data['resourceId'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      usersWhoRated: data['usersWhoRated'] == null
          ? null
          : _convertUsersWhoRated(data['usersWhoRated'] as List),
      user: data['user'] == null
          ? null
          : BaseListItem.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  /// Constructs an [Comment] instance from a JSON map.
  // ignore: sort_constructors_first
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String?,
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      parentId: json['parentId'] as String?,
      resourceId: json['resourceId'] as String?,
      date: (json['date'] as Timestamp).toDate(),
      usersWhoRated: _convertUsersWhoRated(json['usersWhoRated'] as List?),
      user: json['user'] == null
          ? null
          : BaseListItem.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  /// Converts a comment to a map for Firestore
  Map<String, Object?> toFirestore() {
    return {
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (user != null) 'user': user,
      if (rating != null) 'rating': rating,
      if (comment != null) 'comment': comment,
      if (parentId != null) 'parentId': parentId,
      if (resourceId != null) 'resourceId': resourceId,
      if (usersWhoRated != null)
        'usersWhoRated':
            List<dynamic>.from(usersWhoRated!.map((e) => e.toJson())),
    };
  }

  /// Converts a comment to a json map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'rating': rating,
      'comment': comment,
      'parentId': parentId,
      'user': user?.toJson(),
      'resourceId': resourceId,
      'usersWhoRated': usersWhoRated?.map((e) => e.toJson()).toList(),
    };
  }

  /// Copies a comment with new values
  Comment copyWith({
    String? id,
    int? rating,
    DateTime? date,
    String? comment,
    String? parentId,
    BaseListItem? user,
    String? resourceId,
    List<BaseListItem>? usersWhoRated,
  }) {
    return Comment(
      id: id ?? this.id,
      user: user ?? this.user,
      date: date ?? this.date,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      parentId: parentId ?? this.parentId,
      resourceId: resourceId ?? this.resourceId,
      usersWhoRated: usersWhoRated ?? this.usersWhoRated,
    );
  }
}

List<BaseListItem> _convertUsersWhoRated(List<dynamic>? itemMap) {
  final usersWhoRated = <BaseListItem>[];
  if (itemMap != null) {
    for (final item in itemMap) {
      usersWhoRated.add(BaseListItem.fromJson(item as Map<String, dynamic>));
    }
  }

  return usersWhoRated;
}
