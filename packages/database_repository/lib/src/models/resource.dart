// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/src/models/base_list_item.dart';

///Model of a Resource
class Resource {
  Resource({
    this.id,
    this.url,
    this.name,
    this.rating,
    this.thumbnail,
    this.lastEditBy,
    this.description,
    this.skillTreeIds,
    this.lastEditDate,
    this.numberOfRates,
    this.usersWhoRated,
  });

  /// Rating of the resource
  int? rating;

  /// Id of the resource
  final String? id;

  /// Url of the resource
  final String? url;

  /// Name of the resource
  final String? name;

  /// Number of users who rated this resource
  int? numberOfRates;
  final String? thumbnail;

  /// User who last edited the resource
  final String? lastEditBy;

  /// Description of the resource
  final String? description;

  /// List of skillTreeIds that this resource is part of
  List<String?>? skillTreeIds;

  ///Date of the last edit
  final DateTime? lastEditDate;

  ///List of users who rated this resource
  List<BaseListItem>? usersWhoRated;

  factory Resource.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Resource(
      id: data!['id'] as String?,
      url: data['url'] as String?,
      name: data['name'] as String?,
      rating: data['rating'] as int?,
      thumbnail: data['thumbnail'] as String?,
      lastEditBy: data['lastEditBy'] as String?,
      description: data['description'] as String?,
      numberOfRates: data['numberOfRates'] as int?,
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
      usersWhoRated: data['usersWhoRated'] == null
          ? null
          : _convertUsersWhoRated(data['usersWhoRated'] as List),
      skillTreeIds: (data['skillTreeIds']) == null
          ? null
          : (data['skillTreeIds'] as List).map((e) => e as String?).toList(),
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (name != null) 'name': name,
      if (rating != null) 'rating': rating,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (description != null) 'description': description,
      if (skillTreeIds != null) 'skillTreeIds': skillTreeIds,
      if (lastEditDate != null) 'lastEditDate': lastEditDate,
      if (numberOfRates != null) 'numberOfRates': numberOfRates,
      if (usersWhoRated != null)
        'usersWhoRated':
            List<dynamic>.from(usersWhoRated!.map((e) => e.toJson())),
    };
  }

  Resource copyWith({
    String? id,
    int? rating,
    String? url,
    String? name,
    String? thumbnail,
    int? numberOfRates,
    String? lastEditBy,
    String? description,
    DateTime? lastEditDate,
    List<String?>? skillTreeIds,
    List<BaseListItem>? usersWhoRated,
  }) {
    return Resource(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      thumbnail: thumbnail ?? this.thumbnail,
      lastEditBy: lastEditBy ?? this.lastEditBy,
      description: description ?? this.description,
      skillTreeIds: skillTreeIds ?? this.skillTreeIds,
      lastEditDate: lastEditDate ?? this.lastEditDate,
      numberOfRates: numberOfRates ?? this.numberOfRates,
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
