import 'package:database_repository/database_repository.dart';

/// An abstract class representing a skill item.
class SkillItem {
  /// constructor
  SkillItem({this.skill, this.category});

  /// A skill
  final Skill? skill;

  /// A catagorry
  final Catagorry? category;

  /// Returns the type of the skill item.
  String get type => skill != null ? 'Skill' : 'Category';
}
