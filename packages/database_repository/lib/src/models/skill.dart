// ignore_for_file: constant_identifier_names

/// Difficulty state for skills
enum DifficultyState {
  /// Introductory level skill
  Introductory,

  /// Intermediate level skill
  Intermediate,

  /// Advanced level skill
  Advanced,

  /// Represents all difficulty levels
  All,
}

/// Category of a skill
enum SkillCategory {
  /// Categort for any skill that does not fit into other categories
  Other,

  /// Category for skills that are performed in-hand
  In_Hand,

  /// Category for skills that are performed while mounted
  Mounted,

  /// Category for skills related to horse care and management
  Husbandry,
}

/// Model of a Skill
class Skill implements Comparable<Skill> {
  /// Creates a new Skill object.
  Skill({
    required this.id,
    required this.rider,
    required this.position,
    required this.skillName,
    required this.lastEditBy,
    required this.description,
    required this.lastEditDate,
    this.prerequisites = const [],
    required this.learningDescription,
    required this.proficientDescription,
    this.category = SkillCategory.Mounted,
    this.difficulty = DifficultyState.Introductory,
  });

  /// Unique identifier for the skill
  final String id;

  /// Position of the skill in the skill tree
  int position = -1;

  /// Whether the skill is for the rider or not
  final bool rider;

  /// Name of the skill
  final String skillName;

  /// Last user who edited the skill
  final String? lastEditBy;

  /// Description of the skill
  final String? description;

  /// Date when the skill was last edited
  final DateTime? lastEditDate;

  /// Category of the skill
  final SkillCategory category;

  /// New field: list of prerequisite skill IDs
  final List<String> prerequisites;

  /// Difficulty level of the skill
  final DifficultyState difficulty;

  /// Description of the skill when learning
  final String? learningDescription;

  /// Description of the skill when proficient
  final String? proficientDescription;

  /// Creates a [Skill] from a backend-neutral map.
  // ignore: sort_constructors_first
  factory Skill.fromMap(Map<String, dynamic> data) {
    return Skill(
      id: data['id'] as String,
      rider: data['rider'] as bool,
      position: data['position'] as int,
      skillName: data['skillName'] as String,
      lastEditBy: data['lastEditBy'] as String?,
      description: data['description'] as String?,
      lastEditDate: _parseNullableDateTime(data['lastEditDate']),
      learningDescription: data['learningDescription'] as String?,
      proficientDescription: data['proficientDescription'] as String?,
      category: _categoryFromString(data['category'] as String?),
      difficulty: _difficultyFromString(data['difficulty'] as String?),
      // gracefully handle nulls and ensure it's a List<String>
      prerequisites: (data['prerequisites'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          [],
    );
  }

  /// Converts the [Skill] object to a backend-neutral map.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'rider': rider,
      'position': position,
      'skillName': skillName,
      if (lastEditBy != null) 'lastEditBy': lastEditBy,
      if (description != null) 'description': description,
      if (lastEditDate != null)
        'lastEditDate': lastEditDate!.toIso8601String(),
      'category': categoryToString(category),
      'difficulty': difficultyToString(difficulty),
      if (learningDescription != null)
        'learningDescription': learningDescription,
      if (proficientDescription != null)
        'proficientDescription': proficientDescription,
      // only store if non-empty
      if (prerequisites.isNotEmpty)
        'prerequisites': List<String>.from(prerequisites),
    };
  }

  /// Serializes [category] to its persisted string value.
  static String categoryToString(SkillCategory category) {
    switch (category) {
      case SkillCategory.Husbandry:
        return 'Husbandry';
      case SkillCategory.In_Hand:
        return 'In_Hand';
      case SkillCategory.Mounted:
        return 'Mounted';
      case SkillCategory.Other:
        return 'Other';
    }
  }

  /// Serializes [difficulty] to its persisted string value.
  static String difficultyToString(DifficultyState difficulty) {
    switch (difficulty) {
      case DifficultyState.Introductory:
        return 'Introductory';
      case DifficultyState.Intermediate:
        return 'Intermediate';
      case DifficultyState.Advanced:
        return 'Advanced';
      case DifficultyState.All:
        return 'Introductory';
    }
  }

  static SkillCategory _categoryFromString(String? value) {
    switch (value) {
      case 'Husbandry':
        return SkillCategory.Husbandry;
      case 'In_Hand':
        return SkillCategory.In_Hand;
      case 'Mounted':
        return SkillCategory.Mounted;
      default:
        return SkillCategory.Other;
    }
  }

  static DifficultyState _difficultyFromString(String? value) {
    switch (value) {
      case 'Intermediate':
        return DifficultyState.Intermediate;
      case 'Advanced':
        return DifficultyState.Advanced;
      case 'Introductory':
      default:
        return DifficultyState.Introductory;
    }
  }

  static DateTime? _parseNullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// Gets the position of the skill in the skill tree.
  int getPosition() {
    return position;
  }

  @override
  int compareTo(Skill skill) {
    return position.compareTo(skill.position);
  }
}
