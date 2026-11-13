import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Skill backend-neutral model & Firestore mapper', () {
    final editDate = DateTime.utc(2025, 4, 10, 12, 30);

    test('toMap and fromMap round-trip all fields and omit empty/null optionals', () {
      final full = Skill(
        id: 'skill-1',
        rider: true,
        position: 3,
        skillName: 'Two-Point',
        lastEditBy: 'coach@example.com',
        description: 'Balanced jumping position',
        lastEditDate: editDate,
        prerequisites: const ['skill-0'],
        learningDescription: 'Hold for 5 strides',
        proficientDescription: 'Hold over gymnastic',
        difficulty: DifficultyState.Intermediate,
      );

      final map = full.toMap();
      expect(map, {
        'id': 'skill-1',
        'rider': true,
        'position': 3,
        'skillName': 'Two-Point',
        'lastEditBy': 'coach@example.com',
        'description': 'Balanced jumping position',
        'lastEditDate': editDate.toIso8601String(),
        'category': 'Mounted',
        'difficulty': 'Intermediate',
        'learningDescription': 'Hold for 5 strides',
        'proficientDescription': 'Hold over gymnastic',
        'prerequisites': ['skill-0'],
      });

      final restored = Skill.fromMap(map);
      expect(restored.id, 'skill-1');
      expect(restored.rider, isTrue);
      expect(restored.position, 3);
      expect(restored.skillName, 'Two-Point');
      expect(restored.lastEditBy, 'coach@example.com');
      expect(restored.description, 'Balanced jumping position');
      expect(restored.lastEditDate, editDate);
      expect(restored.category, SkillCategory.Mounted);
      expect(restored.difficulty, DifficultyState.Intermediate);
      expect(restored.learningDescription, 'Hold for 5 strides');
      expect(restored.proficientDescription, 'Hold over gymnastic');
      expect(restored.prerequisites, ['skill-0']);

      // Mutable position remains supported.
      restored.position = 7;
      expect(restored.getPosition(), 7);

      final minimal = Skill(
        id: 'skill-2',
        rider: false,
        position: 0,
        skillName: 'Halt',
        lastEditBy: null,
        description: null,
        lastEditDate: null,
        learningDescription: null,
        proficientDescription: null,
        category: SkillCategory.In_Hand,
        difficulty: DifficultyState.All,
      );

      expect(minimal.toMap(), {
        'id': 'skill-2',
        'rider': false,
        'position': 0,
        'skillName': 'Halt',
        'category': 'In_Hand',
        'difficulty': 'Introductory',
      });
    });

    test(
      'SkillFirestoreMapper preserves legacy Firestore format & Timestamps',
      () async {
      final firestore = FakeFirebaseFirestore();
      final docRef = firestore.collection('Skills').doc('skill-fs');
      await docRef.set({
        'id': 'skill-fs',
        'rider': true,
        'position': 2,
        'skillName': 'Leg Yield',
        'lastEditBy': 'trainer@example.com',
        'description': 'Lateral movement',
        'lastEditDate': Timestamp.fromDate(editDate),
        'category': 'Husbandry',
        'difficulty': 'Advanced',
        'learningDescription': '3 steps sideways',
        'proficientDescription': 'Full diagonal',
        'prerequisites': ['skill-1', 42, 'skill-0'],
      });

      final snap = await docRef.get();
      final loaded = SkillFirestoreMapper.fromFirestore(snap, null);

      expect(loaded.id, 'skill-fs');
      expect(loaded.lastEditDate, editDate.toLocal());
      expect(loaded.category, SkillCategory.Husbandry);
      expect(loaded.difficulty, DifficultyState.Advanced);
      expect(loaded.prerequisites, ['skill-1', 'skill-0']);

      final encoded = SkillFirestoreMapper.toFirestore(loaded);
      expect(encoded['lastEditDate'], editDate.toLocal());
      expect(encoded['category'], 'Husbandry');
      expect(encoded['difficulty'], 'Advanced');
      expect(encoded['prerequisites'], ['skill-1', 'skill-0']);
    });
  });
}
