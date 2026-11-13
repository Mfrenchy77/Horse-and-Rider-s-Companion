import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubCategory backend-neutral model and SubCategoryFirestoreMapper', () {
    final editDate = DateTime(2026, 5, 2, 14);

    test('constructs and round-trips via fromMap/toMap without Firebase', () {
      final original = SubCategory(
        id: 'sub-1',
        name: 'Lateral Work',
        isRider: false,
        position: 3,
        skills: ['skill-a', 'skill-b'],
        parentId: 'cat-1',
        lastEditBy: 'admin@example.com',
        description: 'Shoulder-in and leg-yield',
        lastEditDate: editDate,
      );

      final map = original.toMap();
      expect(map['rider'], false);
      expect(map['lastEditDate'], editDate.toIso8601String());

      final decoded = SubCategory.fromMap(map);
      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.isRider, original.isRider);
      expect(decoded.position, original.position);
      expect(decoded.skills, ['skill-a', 'skill-b']);
      expect(decoded.parentId, 'cat-1');
      expect(decoded.lastEditBy, original.lastEditBy);
      expect(decoded.description, original.description);
      expect(decoded.lastEditDate, original.lastEditDate);
    });

    test(
      'fromMap supports DateTime, ISO string, epoch ms, and null parentId',
      () {
      final base = {
        'id': 'sub-2',
        'name': 'Seat',
        'rider': true,
        'position': 1,
        'parentId': null,
        'lastEditBy': 'coach@example.com',
        'description': 'Independent seat',
      };

      final fromDt = SubCategory.fromMap({...base, 'lastEditDate': editDate});
      expect(fromDt.lastEditDate, editDate);
      expect(fromDt.parentId, isNull);
      expect(fromDt.skills, isEmpty);

      expect(
        SubCategory.fromMap({
          ...base,
          'lastEditDate': editDate.toIso8601String(),
        }).lastEditDate,
        editDate,
      );
      expect(
        SubCategory.fromMap({
          ...base,
          'lastEditDate': editDate.millisecondsSinceEpoch,
        }).lastEditDate,
        editDate,
      );
    });

    test(
      'SubCategoryFirestoreMapper deserializes Timestamp, preserves doc ID, '
      'and serializes identically',
      () async {
        final fake = FakeFirebaseFirestore();
        await fake
            .collection(SubCategoryRepository.SUB_CATEGORIES)
            .doc('sub-ts')
            .set({
          'name': 'Transitions',
          'skills': ['s1', 's2'],
          'rider': true,
          'position': 4,
          'parentId': 'cat-dressage',
          'lastEditBy': 'trainer@example.com',
          'description': 'Walk-trot-canter',
          'lastEditDate': Timestamp.fromDate(editDate),
        });

        final snap = await fake
            .collection(SubCategoryRepository.SUB_CATEGORIES)
            .doc('sub-ts')
            .get();
        final loaded = SubCategoryFirestoreMapper.fromFirestore(snap, null);

        expect(loaded.id, 'sub-ts');
        expect(loaded.name, 'Transitions');
        expect(loaded.isRider, true);
        expect(loaded.position, 4);
        expect(loaded.skills, ['s1', 's2']);
        expect(loaded.parentId, 'cat-dressage');
        expect(loaded.lastEditBy, 'trainer@example.com');
        expect(loaded.description, 'Walk-trot-canter');
        expect(loaded.lastEditDate, editDate);

        expect(SubCategoryFirestoreMapper.toFirestore(loaded), {
          'id': 'sub-ts',
          'name': 'Transitions',
          'skills': ['s1', 's2'],
          'rider': true,
          'position': 4,
          'parentId': 'cat-dressage',
          'lastEditBy': 'trainer@example.com',
          'description': 'Walk-trot-canter',
          'lastEditDate': editDate,
        });
      },
    );

    test(
      'SubCategoryRepository reads and writes via SubCategoryFirestoreMapper',
      () async {
        final fake = FakeFirebaseFirestore();
        final repo = SubCategoryRepository(firestore: fake);

        final riderSub = SubCategory(
          id: 'r-sub',
          name: 'Posting',
          isRider: true,
          position: 1,
          skills: ['s1'],
          parentId: 'cat-1',
          lastEditBy: 'admin@example.com',
          description: 'Rising trot',
          lastEditDate: editDate,
        );
        final horseSub = SubCategory(
          id: 'h-sub',
          name: 'Lunging',
          isRider: false,
          position: 2,
          skills: ['s2'],
          parentId: null,
          lastEditBy: 'admin@example.com',
          description: 'Circle work',
          lastEditDate: editDate,
        );

        await repo.createOrEditSubCategory(subCategory: riderSub);
        await repo.createOrEditSubCategory(subCategory: horseSub);

        final single = await repo.getSubCategory(subCategory: riderSub).first;
        expect(single?.name, 'Posting');
        expect(single?.lastEditDate, editDate);

        final riderList = await repo.getSubCategoriesForRiderSkillTree().first;
        expect(riderList.map((s) => s.id), ['r-sub']);

        final horseList = await repo.getSubCategoriesForHorseSkillTree().first;
        expect(horseList.map((s) => s.id), ['h-sub']);

        repo.deleteSubCategory(subCategory: horseSub);
        final afterDelete =
            await repo.getSubCategoriesForHorseSkillTree().first;
        expect(afterDelete, isEmpty);
      },
    );
  });
}
