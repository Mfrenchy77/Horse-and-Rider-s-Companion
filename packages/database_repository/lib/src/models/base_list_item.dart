// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:cloud_firestore/cloud_firestore.dart';

class BaseListItem {
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
  DateTime? date;
  final String? id;
  String? message;
  String? imageUrl;
  String? parentId;
  bool? isSelected;
  bool? isCollapsed;
  final String? name;

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
