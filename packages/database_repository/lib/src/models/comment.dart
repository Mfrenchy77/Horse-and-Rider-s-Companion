import 'package:database_repository/src/models/base_list_item.dart';

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
    required this.editedDate,
    required this.resourceId,
    required List<BaseListItem>? usersWhoRated,
  }) : usersWhoRated = usersWhoRated?.toList();

  /// Constructs a [Comment] instance from a backend-neutral map.
  // ignore: sort_constructors_first
  factory Comment.fromMap(Map<String, dynamic> data) {
    final rawUsers = data['usersWhoRated'] as List?;
    return Comment(
      id: data['id'] as String?,
      rating: data['rating'] as int?,
      comment: data['comment'] as String?,
      parentId: data['parentId'] as String?,
      resourceId: data['resourceId'] as String?,
      date: _parseDateTime(data['date']),
      editedDate: _parseNullableDateTime(data['editedDate']),
      usersWhoRated: rawUsers == null ? null : _convertUsersWhoRated(rawUsers),
      user: data['user'] == null
          ? null
          : BaseListItem.fromMap(
              Map<String, dynamic>.from(data['user'] as Map),
            ),
    );
  }

  /// Constructs a [Comment] instance from a JSON map.
  // ignore: sort_constructors_first
  factory Comment.fromJson(Map<String, dynamic> json) => Comment.fromMap(json);

  /// Id of the comment
  final String? id;

  /// The rating of the comment
  int? rating;

  /// The date the comment was made
  final DateTime date;

  /// The date if edited
  final DateTime? editedDate;

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

  /// Converts a comment to a backend-neutral map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'rating': rating,
      'comment': comment,
      'parentId': parentId,
      'user': user?.toMap(),
      'editedDate': editedDate?.toIso8601String(),
      'resourceId': resourceId,
      'usersWhoRated': usersWhoRated?.map((e) => e.toMap()).toList(),
    };
  }

  /// Converts a comment to a json map.
  Map<String, dynamic> toJson() => toMap();

  /// Copies a comment with new values
  Comment copyWith({
    String? id,
    int? rating,
    DateTime? date,
    String? comment,
    String? parentId,
    BaseListItem? user,
    String? resourceId,
    DateTime? editedDate,
    List<BaseListItem>? usersWhoRated,
  }) {
    return Comment(
      id: id ?? this.id,
      user: user ?? this.user,
      date: date ?? this.date,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      parentId: parentId ?? this.parentId,
      editedDate: editedDate ?? this.editedDate,
      resourceId: resourceId ?? this.resourceId,
      usersWhoRated: usersWhoRated ?? this.usersWhoRated,
    );
  }
}

List<BaseListItem> _convertUsersWhoRated(List<dynamic> itemMap) {
  final usersWhoRated = <BaseListItem>[];
  for (final item in itemMap) {
    usersWhoRated.add(
      BaseListItem.fromMap(Map<String, dynamic>.from(item as Map)),
    );
  }
  return usersWhoRated;
}

DateTime _parseDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  throw ArgumentError('Expected DateTime, String, or int, got $value');
}

DateTime? _parseNullableDateTime(Object? value) {
  if (value == null) return null;
  return _parseDateTime(value);
}
