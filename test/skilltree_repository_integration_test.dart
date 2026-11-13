// ignore_for_file: prefer_const_constructors

import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillTreeRepository with FakeFirestore', () {
    late FakeFirebaseFirestore fake;
    late SkillTreeRepository repo;

    setUp(() {
      fake = FakeFirebaseFirestore();
      repo = SkillTreeRepository(firestore: fake);
    });

    test('create/read/update/delete Skills, filter by rider and category',
        () async {
      final now = DateTime.now();
      final s1 = Skill(
        id: 's1',
        skillName: 'Mounted Balance',
        rider: true,
        position: 1,
        lastEditBy: 'tester',
        description: 'desc',
        lastEditDate: now,
        learningDescription: 'learn',
        proficientDescription: 'pro',
      );
      final s2 = Skill(
        id: 's2',
        skillName: 'Grooming',
        rider: false,
        position: 2,
        lastEditBy: 'tester',
        description: 'desc',
        lastEditDate: now,
        category: SkillCategory.Husbandry,
        difficulty: DifficultyState.Intermediate,
        learningDescription: 'learn',
        proficientDescription: 'pro',
      );

      await repo.createOrEditSkill(skill: s1);
      await repo.createOrEditSkill(skill: s2);

      final all = await repo.getSkills().first;
      expect(all.length, 2);

      final riderOnly = await repo.getSkillsForRiderSkillTree().first;
      expect(riderOnly.map((s) => s.id), contains('s1'));
      expect(riderOnly.any((s) => s.id == 's2'), isFalse);

      // category string stored in Firestore is 'Mounted'
      final mounted = await repo.getSkillsFromCategory(id: 'Mounted').first;
      expect(mounted.length, 1);
      expect(mounted.first.id, 's1');

      // delete and verify
      repo.deleteSkill(skill: s1);
      final afterDelete = await repo.getSkills().first;
      expect(afterDelete.map((s) => s.id), isNot(contains('s1')));
      expect(afterDelete.length, 1);
    });

    test('repository uses provided Firestore instance (isolation)', () async {
      final other = FakeFirebaseFirestore();
      final repoA = SkillTreeRepository(firestore: fake);
      final repoB = SkillTreeRepository(firestore: other);

      final now = DateTime.now();
      final s = Skill(
        id: 'iso',
        skillName: 'Isolation Skill',
        rider: true,
        position: 0,
        lastEditBy: 'x',
        description: 'x',
        lastEditDate: now,
        category: SkillCategory.Other,
        learningDescription: 'x',
        proficientDescription: 'x',
      );

      await repoA.createOrEditSkill(skill: s);
      final aCount = (await repoA.getSkills().first).length;
      final bCount = (await repoB.getSkills().first).length;
      expect(aCount, 1);
      expect(bCount, 0);
    });
  });
}
