import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a sub-category model.
///
/// This class contains the properties and methods to represent a sub-category.
/// It is used in conjunction with the Category model to organize data in the database.
class SubCategory {
  /// Creates a new sub-category instance.
  SubCategory({
    /// The id of the sub-category.
    required this.id,

    /// The name of the sub-category.
    required this.name,

    /// Whether or not the sub-category is for a horse or rider
    required this.isRider,

    /// The position of the sub-category.
    required this.position,

    /// The skills associated with the sub-category.
    required this.skills,

    /// The id of the parent category.
    required this.parentId,

    /// The user who last edited the sub-category.
    required this.lastEditBy,

    /// The description of the sub-category.
    required this.description,

    /// The date the sub-category was last edited.
    required this.lastEditDate,
  });

  /// The id of the sub-category.
  final String id;

  /// The name of the sub-category.
  final String name;

  /// Whether or not the sub-category is for a horse or rider
  final bool isRider;

  /// The position of the sub-category.
  final int position;

  /// The skills associated with the sub-category.
  final List<String> skills;

  /// The id of the parent category.
  final String? parentId;

  /// The user who last edited the sub-category.
  final String lastEditBy;

  /// The description of the sub-category.
  final String description;

  /// The date the sub-category was last edited.
  final DateTime lastEditDate;

  /// Creates a new sub-category instance from a map.
  /// to store retreive from Firestore database.
  // ignore: sort_constructors_first
  factory SubCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return SubCategory(
      id: data!['id'] as String,
      name: data['name'] as String,
      isRider: data['rider'] as bool,
      position: data['position'] as int,
      parentId: data['parentId'] as String?,
      lastEditBy: data['lastEditBy'] as String,
      description: data['description'] as String,
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
      skills: (data['skills'] as List).map((e) => e as String).toList(),
    );
  }

  /// Converts the sub-category to a map.
  /// to store in Firestore database.
  Map<String, Object?> toFirestore() {
    return {
      'id': id,
      'name': name,
      'skills': skills,
      'rider': isRider,
      'position': position,
      'parentId': parentId,
      'lastEditBy': lastEditBy,
      'description': description,
      'lastEditDate': lastEditDate,
    };
  }
}
