/// Represents a sub-category model.
///
/// This class contains the properties and methods to represent a sub-category.
/// It is used in conjunction with the Category model
/// to organize data in the database.
class SubCategory {
  /// Creates a new sub-category instance.
  SubCategory({
    required this.id,
    required this.name,
    required this.isRider,
    required this.position,
    required this.skills,
    required this.parentId,
    required this.lastEditBy,
    required this.description,
    required this.lastEditDate,
  });

  /// Creates a [SubCategory] from a backend-neutral map.
  factory SubCategory.fromMap(Map<String, dynamic> data) {
    final rawSkills = data['skills'] as List?;
    return SubCategory(
      id: data['id'] as String,
      name: data['name'] as String,
      isRider: data['rider'] as bool,
      position: data['position'] as int,
      parentId: data['parentId'] as String?,
      lastEditBy: data['lastEditBy'] as String,
      description: data['description'] as String,
      lastEditDate: _parseDateTime(data['lastEditDate']),
      skills: rawSkills?.map((e) => e as String).toList() ?? <String>[],
    );
  }

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

  /// Converts the sub-category to a backend-neutral map.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'skills': List<String>.from(skills),
      'rider': isRider,
      'position': position,
      'parentId': parentId,
      'lastEditBy': lastEditBy,
      'description': description,
      'lastEditDate': lastEditDate.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw ArgumentError('Expected DateTime, String, or int, got $value');
  }
}
