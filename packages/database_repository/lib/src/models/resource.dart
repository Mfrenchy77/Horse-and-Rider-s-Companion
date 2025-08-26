// ignore: lines_longer_than_80_chars
// ignore_for_file: public_member_api_docs, sort_constructors_first, no_leading_underscores_for_local_identifiers

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

/// What kind of resource this is. Optional for legacy docs without `type`.
enum ResourceType { link, video, pdf, article, other }

/// Publication state (useful if you add moderation).
enum ResourceStatus { pending, published, rejected }

/// Model of a Resource
class Resource {
  Resource({
    this.id,
    this.url,
    this.name,
    this.type,
    this.tags,
    this.rating,
    this.status,
    this.content,
    this.comments,
    this.authorId,
    this.createdAt,
    this.thumbnail,
    this.lastEditBy,
    this.authorName,
    this.authorPhoto,
    this.description,
    this.lastEditDate,
    this.coverImageUrl,
    this.usersWhoRated,
    this.numberOfRates,
    List<String>? skillTreeIds,
  }) : skillTreeIds = (skillTreeIds ?? const <String>[]).toList();

  /// Id of the resource (doc id). Keep required so repo can `.doc(id)`.
  final String? id;

  /// Url of the resource (for link/video/pdf)
  final String? url;

  /// Name/title of the resource
  final String? name;

  /// Rating (legacy aggregate)
  int? rating;

  /// Number of users who rated this resource (legacy aggregate)
  int? numberOfRates;

  /// Thumbnail url of the resource
  final String? thumbnail;

  /// User who last edited the resource (uid or display name)
  final String? lastEditBy;

  /// Description/summary
  final String? description;

  /// List of skillTreeIds that this resource is part of
  List<String> skillTreeIds;

  /// Date of the last edit
  final DateTime? lastEditDate;

  /// List of Comments for this resource
  List<Comment>? comments;

  /// List of users who rated this resource
  List<BaseListItem>? usersWhoRated;

  // -------- New/optional fields (articles & moderation) --------

  /// Resource type (link/pdf/video/article/other)
  final ResourceType? type;

  /// Publication status (pending/published/rejected)
  final ResourceStatus? status;

  /// Article body (markdown/plain). Only for `type == article`.
  final String? content;

  /// Optional cover image for articles/resources
  final String? coverImageUrl;

  /// Author info
  final String? authorId;
  final String? authorName;
  final String? authorPhoto;

  /// Created/updated timestamps (prefer these over `lastEditDate`)
  final DateTime? createdAt;

  /// Simple tags for filtering
  final List<String>? tags;

  // ------------------ Firestore converter entrypoints ------------------

  factory Resource.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final map = snapshot.data() ?? const <String, dynamic>{};
    return Resource.fromMap(map, idFromDoc: snapshot.id);
  }

  Map<String, Object?> toFirestore() {
    Timestamp? _ts(DateTime? d) => d == null ? null : Timestamp.fromDate(d);
    return {
      // Keep 'id' for backward-compat with docs that stored it.
      'id': id,
      if (url != null) 'url': url,
      if (name != null) 'name': name,
      if (rating != null) 'rating': rating,
      if (type != null) 'type': type!.name,
      if (content != null) 'content': content,
      if (status != null) 'status': status!.name,
      if (authorId != null) 'authorId': authorId,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (authorName != null) 'authorName': authorName,
      if (createdAt != null) 'createdAt': _ts(createdAt),
      if (tags != null && tags!.isNotEmpty) 'tags': tags,
      if (authorPhoto != null) 'authorPhoto': authorPhoto,
      if (description != null) 'description': description,
      if (numberOfRates != null) 'numberOfRates': numberOfRates,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (skillTreeIds.isNotEmpty) 'skillTreeIds': skillTreeIds,
      if (lastEditDate != null) 'lastEditDate': _ts(lastEditDate),
      if (usersWhoRated != null)
        'usersWhoRated':
            List<dynamic>.from(usersWhoRated!.map((e) => e.toJson())),
      if (comments != null)
        'comments': List<dynamic>.from(comments!.map((e) => e.toJson())),
    };
  }

  // ------------------ Map/JSON helpers (no sealed types) ------------------

  /// Parse from a plain map (works for JSON, local cache, tests).
  factory Resource.fromMap(Map<String, dynamic> data, {String? idFromDoc}) {
    DateTime? _asDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse('$v');
    }

    List<String> _asStringList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e is String ? e : (e?.toString() ?? ''))
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const <String>[];
    }

    ResourceType? _typeFrom(dynamic v) {
      switch ((v as String?)?.toLowerCase()) {
        case 'link':
          return ResourceType.link;
        case 'video':
          return ResourceType.video;
        case 'pdf':
          return ResourceType.pdf;
        case 'article':
          return ResourceType.article;
        case 'other':
          return ResourceType.other;
        default:
          return null;
      }
    }

    ResourceStatus? _statusFrom(dynamic v) {
      switch ((v as String?)?.toLowerCase()) {
        case 'pending':
          return ResourceStatus.pending;
        case 'published':
          return ResourceStatus.published;
        case 'rejected':
          return ResourceStatus.rejected;
        default:
          return null;
      }
    }

    final id = (data['id'] as String?) ?? idFromDoc ?? '';
    return Resource(
      id: id,
      url: data['url'] as String?,
      name: data['name'] as String?,
      rating: _asInt(data['rating']),
      type: _typeFrom(data['type']),
      tags: _asStringList(data['tags']),
      status: _statusFrom(data['status']),
      content: data['content'] as String?,
      authorId: data['authorId'] as String?,
      createdAt: _asDate(data['createdAt']),
      thumbnail: data['thumbnail'] as String?,
      lastEditBy: data['lastEditBy'] as String?,
      authorName: data['authorName'] as String?,
      description: data['description'] as String?,
      lastEditDate: _asDate(data['lastEditDate']),
      authorPhoto: data['authorPhoto'] as String?,
      numberOfRates: _asInt(data['numberOfRates']),
      coverImageUrl: data['coverImageUrl'] as String?,
      skillTreeIds: _asStringList(data['skillTreeIds']),
      comments: data['comments'] == null
          ? null
          : _convertComments(data['comments'] as List),
      usersWhoRated: data['usersWhoRated'] == null
          ? null
          : _convertUsersWhoRated(data['usersWhoRated'] as List),
    );
  }

  Map<String, Object?> toJson() => toFirestore();

  factory Resource.fromJson(Map<String, dynamic> json) =>
      Resource.fromMap(json, idFromDoc: json['id'] as String?);

  // ------------------ Copy & conveniences ------------------

  Resource copyWith({
    String? id,
    String? url,
    int? rating,
    String? name,
    String? content,
    String? authorId,
    String? thumbnail,
    int? numberOfRates,
    String? lastEditBy,
    ResourceType? type,
    String? authorName,
    List<String>? tags,
    String? authorPhoto,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? coverImageUrl,
    ResourceStatus? status,
    DateTime? lastEditDate,
    List<Comment>? comments,
    List<String>? skillTreeIds,
    List<BaseListItem>? usersWhoRated,
  }) {
    return Resource(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      type: type ?? this.type,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      status: status ?? this.status,
      content: content ?? this.content,
      comments: comments ?? this.comments,
      authorId: authorId ?? this.authorId,
      thumbnail: thumbnail ?? this.thumbnail,
      createdAt: createdAt ?? this.createdAt,
      lastEditBy: lastEditBy ?? this.lastEditBy,
      authorName: authorName ?? this.authorName,
      description: description ?? this.description,
      authorPhoto: authorPhoto ?? this.authorPhoto,
      skillTreeIds: skillTreeIds ?? this.skillTreeIds,
      lastEditDate: lastEditDate ?? this.lastEditDate,
      usersWhoRated: usersWhoRated ?? this.usersWhoRated,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      numberOfRates: numberOfRates ?? this.numberOfRates,
    );
  }

  bool get isArticle => type == ResourceType.article;
  bool get isPublished => status == ResourceStatus.published;
}

// ------------------ Helpers ------------------

List<BaseListItem> _convertUsersWhoRated(List<dynamic>? itemMap) {
  final out = <BaseListItem>[];
  if (itemMap != null) {
    for (final item in itemMap) {
      if (item is Map<String, dynamic>) {
        out.add(BaseListItem.fromJson(item));
      }
    }
  }
  return out;
}

List<Comment> _convertComments(List<dynamic>? itemMap) {
  final out = <Comment>[];
  if (itemMap != null) {
    for (final item in itemMap) {
      if (item is Map<String, dynamic>) {
        out.add(Comment.fromJson(item));
      }
    }
  }
  return out;
}
