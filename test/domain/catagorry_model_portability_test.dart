import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Catagorry backend-neutral model and CatagorryFirestoreMapper', () {
    final editDate = DateTime(2026, 5, 1, 9, 15);

    test('constructs and round-trips via fromMap/toMap without Firebase', () {
      final original = Catagorry(
        id: 'cat-1',
        name: 'Dressage',
        rider: true,
        position: 2,
        lastEditBy: 'admin@example.com',
        description: 'Flatwork fundamentals',
        lastEditDate: editDate,
      );

      final map = original.toMap();
      expect(map['lastEditDate'], editDate.toIso8601String());

      final decoded = Catagorry.fromMap(map);
      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.rider, original.rider);
      expect(decoded.position, original.position);
      expect(decoded.lastEditBy, original.lastEditBy);
      expect(decoded.description, original.description);
      expect(decoded.lastEditDate, original.lastEditDate);
    });

    test('fromMap supports DateTime, ISO string, and epoch ms', () {
      final base = {
        'id': 'cat-1',
        'name': 'Jumping',
        'rider': false,
        'position': 1,
        'lastEditBy': 'coach@example.com',
        'description': 'Grid work',
      };

      expect(
        Catagorry.fromMap({...base, 'lastEditDate': editDate}).lastEditDate,
        editDate,
      );
      expect(
        Catagorry.fromMap({
          ...base,
          'lastEditDate': editDate.toIso8601String(),
        }).lastEditDate,
        editDate,
      );
      expect(
        Catagorry.fromMap({
          ...base,
          'lastEditDate': editDate.millisecondsSinceEpoch,
        }).lastEditDate,
        editDate,
      );
    });

    test(
      'CatagorryFirestoreMapper deserializes Timestamp, preserves doc ID, '
      'and serializes identically',
      () async {
        final fake = FakeFirebaseFirestore();
        await fake
            .collection(CatagorryRepository.CATEGORIES)
            .doc('cat-ts')
            .set({
          'name': 'Groundwork',
          'rider': false,
          'position': 0,
          'lastEditBy': 'trainer@example.com',
          'description': 'Leading and yielding',
          'lastEditDate': Timestamp.fromDate(editDate),
        });

        final snap = await fake
            .collection(CatagorryRepository.CATEGORIES)
            .doc('cat-ts')
            .get();
        final loaded = CatagorryFirestoreMapper.fromFirestore(snap, null);

        expect(loaded.id, 'cat-ts');
        expect(loaded.name, 'Groundwork');
        expect(loaded.rider, false);
        expect(loaded.position, 0);
        expect(loaded.lastEditBy, 'trainer@example.com');
        expect(loaded.description, 'Leading and yielding');
        expect(loaded.lastEditDate, editDate);

        expect(CatagorryFirestoreMapper.toFirestore(loaded), {
          'id': 'cat-ts',
          'name': 'Groundwork',
          'rider': false,
          'position': 0,
          'lastEditBy': 'trainer@example.com',
          'description': 'Leading and yielding',
          'lastEditDate': editDate,
        });
      },
    );

    test(
      'CatagorryRepository reads and writes via CatagorryFirestoreMapper',
      () async {
        final fake = FakeFirebaseFirestore();
        final repo = CatagorryRepository(firestore: fake);

        final riderCat = Catagorry(
          id: 'r-cat',
          name: 'Balance',
          rider: true,
          position: 1,
          lastEditBy: 'admin@example.com',
          description: 'Rider balance',
          lastEditDate: editDate,
        );
        final horseCat = Catagorry(
          id: 'h-cat',
          name: 'Desensitizing',
          rider: false,
          position: 2,
          lastEditBy: 'admin@example.com',
          description: 'Horse confidence',
          lastEditDate: editDate,
        );

        await repo.createOrEditCategory(catagory: riderCat);
        await repo.createOrEditCategory(catagory: horseCat);

        final single = await repo.getCategory(categorry: riderCat).first;
        expect(single?.name, 'Balance');
        expect(single?.lastEditDate, editDate);

        final riderList = await repo.getCatagoriesForRiderSkillTree().first;
        expect(riderList.map((c) => c.id), ['r-cat']);

        final horseList = await repo.getCatagoriesForHorseSkillTree().first;
        expect(horseList.map((c) => c.id), ['h-cat']);

        repo.deleteCategory(catagorry: horseCat);
        final afterDelete = await repo.getCatagoriesForHorseSkillTree().first;
        expect(afterDelete, isEmpty);
      },
    );
  });
}
