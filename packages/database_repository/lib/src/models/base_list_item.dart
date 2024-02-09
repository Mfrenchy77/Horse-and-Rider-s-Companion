// ignore_for_file:  sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';

/// This is a multi use container. It is used to represent a Rating for a
///  Resource, a Log Entry for Horse or Rider, a Instructor Request, a Contact
///  for adding to a users Profile.
class BaseListItem {
  /// Constructor for a BaseListItem
  BaseListItem({
    this.name,
    this.date,
    this.depth,
    this.message,
    this.id = '',
    this.imageUrl,
    this.parentId,
    this.isSelected,
    this.isCollapsed,
  });

  int? depth;

  /// If BaseListItem is for a Log Entry, this is the date of the log entry
  DateTime? date;

  /// If BaseListItem is a Rating, this is the users email who rated the
  ///  resource.
  /// 
  ///  If it is a Log Entry, this is the date of the log entry.
  /// 
  ///  If it is a Instructor Request, this is the user making the request's
  ///  email.
  /// 
  ///  If it is a Contact, this is the contact's email.
  final String? id;

  /// If BaseListItem is a Log Entry, this is the Users Name who made the log
  ///  entry.
  String? message;
  /// If the BaseListItem is a Log Entry, this is the Tag
  /// 
  /// If the BaseListItem is an Instructor Request, this is the users Thumbnail.
  /// 
  /// If it is a Contact, this is the contact's thumbnail.
  String? imageUrl;

  /// If BaseListItem is a Log Entry, this is the users email.
  String? parentId;

  /// If BaseListItem is a Rating, this is used to notate a positive rating.
  /// 
  /// If it is a Instructor Request, this is used to notate if the request
  /// has been accepted or not.
  bool? isSelected;

  /// If BaseListItem is a Rating, this is used to notate a negative rating.
  /// 
  /// If it is a Instructor Request, this is used to notate if the request
  /// is for a Horse or a Rider. True if Rider, False if Horse.
  /// 
  ///  If it is a
  /// Contact, this is used to notate if the contact is a Horse or a Rider.
  /// True if Rider, False if Horse.
  bool? isCollapsed;

  /// If BaseListItem is a Log Entry, this is used to hold the log entry
  ///  message.
  /// 
  ///  If it is a Instructor Request, this is used to hold the name of the user
  ///  making the request.
  /// 
  ///  If it is a Contact, this is used to hold the contact's name.
  final String? name;

  /// Creates a BaseListItem from a json map
  factory BaseListItem.fromJson(Map<String, dynamic> json) => BaseListItem(
        id: json['id'] as String?,
        depth: json['depth'] as int?,
        name: json['name'] as String?,
        message: json['message'] as String?,
        parentId: json['parentId'] as String?,
        isSelected: json['isSelected'] as bool?,
        imageUrl: json['imageUrl'] as String?,
        isCollapsed: json['isCollapsed'] as bool?,
        date: (json['date'] as Timestamp?)?.toDate(),
      );

  /// Creates a BaseListItem from a firestore snapshot
  factory BaseListItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return BaseListItem(
      id: data!['id'] as String?,
      depth: data['depth'] as int?,
      name: data['name'] as String?,
      message: data['message'] as String?,
      imageUrl: data['imageUrl'] as String?,
      parentId: data['parentId'] as String?,
      isSelected: data['isSelected'] as bool?,
      isCollapsed: data['isCollapsed'] as bool?,
      date: (data['date'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts a List of BaseListItems to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (depth != null) 'depth': depth,
      if (message != null) 'message': message,
      if (parentId != null) 'parentId': parentId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (isSelected != null) 'isSelected': isSelected,
      if (isCollapsed != null) 'isCollapsed': isCollapsed,
    };
  }

  /// Converts a List of BaseListItems to a List of json maps
  Map<String, Object?> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (depth != null) 'depth': depth,
      if (message != null) 'message': message,
      if (parentId != null) 'parentId': parentId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (isSelected != null) 'isSelected': isSelected,
      if (isCollapsed != null) 'isCollapsed': isCollapsed,
    };
  }
}
