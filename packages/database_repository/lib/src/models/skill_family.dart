// ignore_for_file: public_member_api_docs

import 'package:database_repository/src/models/skill.dart';

/// The subject a skill or skill family belongs to.
enum SkillSubject {
  rider,
  horse;

  static SkillSubject fromString(String? value) {
    return switch (value?.toLowerCase()) {
      'horse' => SkillSubject.horse,
      'rider' || _ => SkillSubject.rider,
    };
  }

  String toWireString() => name;
}

/// Organizational grouping for skills within a subject and realm.
///
/// Skill families carry no progress state, completion count, or ordering gate.
class SkillFamily {
  const SkillFamily({
    required this.id,
    required this.subject,
    required this.realm,
    required this.name,
    required this.description,
    this.sortOrder = 0,
    this.schemaVersion = 2,
  });

  factory SkillFamily.fromMap(Map<String, dynamic> data) {
    return SkillFamily(
      id: data['id'] as String? ?? '',
      subject: SkillSubject.fromString(data['subject'] as String?),
      realm: parseSkillRealm(data['realm'] as String?),
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 2,
    );
  }

  final String id;
  final SkillSubject subject;
  final SkillCategory realm;
  final String name;
  final String description;
  final int sortOrder;
  final int schemaVersion;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subject': subject.toWireString(),
      'realm': Skill.categoryToString(realm),
      'name': name,
      'description': description,
      'sortOrder': sortOrder,
      'schemaVersion': schemaVersion,
    };
  }
}

/// Parses a realm string onto [SkillCategory] (`Other` = Theory & Knowledge).
SkillCategory parseSkillRealm(String? value) {
  return switch (value) {
    'Husbandry' => SkillCategory.Husbandry,
    'In_Hand' => SkillCategory.In_Hand,
    'Mounted' => SkillCategory.Mounted,
    'Other' || _ => SkillCategory.Other,
  };
}
