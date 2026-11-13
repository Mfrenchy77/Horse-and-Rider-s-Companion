import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Level backend-neutral model and LevelFirestoreMapper', () {
    final editDate = DateTime(2026, 4, 15, 10, 30);

    test('constructs and round-trips via fromMap/toMap without Firebase', () {
      final original = Level(
        id: 'lvl-1',
        level: 2,
        rider: true,
        skillId: 'skill-1',
        levelName: 'Intermediate',
        position: 3,
        lastEditBy: 'coach@example.com',
        description: 'Canter transitions',
        lastEditDate: editDate,
        learningDescription: 'Practicing smooth transitions',
        completeDescription: 'Consistent transitions on both leads',
      );

      final map = original.toMap();
      expect(map['lastEditDate'], editDate.toIso8601String());

      final decoded = Level.fromMap(map);
      expect(decoded.id, original.id);
      expect(decoded.level, original.level);
      expect(decoded.rider, original.rider);
      expect(decoded.skillId, original.skillId);
      expect(decoded.levelName, original.levelName);
      expect(decoded.position, original.position);
      expect(decoded.lastEditBy, original.lastEditBy);
      expect(decoded.description, original.description);
      expect(decoded.lastEditDate, original.lastEditDate);
      expect(decoded.learningDescription, original.learningDescription);
      expect(decoded.completeDescription, original.completeDescription);
      expect(decoded.compareTo(original), 0);
    });

    test('fromMap supports DateTime, ISO string, epoch ms, and null', () {
      final fromDateTime = Level.fromMap({
        'position': 1,
        'lastEditDate': editDate,
      });
      final fromIso = Level.fromMap({
        'position': 1,
        'lastEditDate': editDate.toIso8601String(),
      });
      final fromEpoch = Level.fromMap({
        'position': 1,
        'lastEditDate': editDate.millisecondsSinceEpoch,
      });
      final fromNull = Level.fromMap({'position': 1});

      expect(fromDateTime.lastEditDate, editDate);
      expect(fromIso.lastEditDate, editDate);
      expect(fromEpoch.lastEditDate, editDate);
      expect(fromNull.lastEditDate, isNull);
      expect(fromNull.id, isNull);
      expect(fromNull.levelName, isNull);
    });

    test(
      'LevelFirestoreMapper deserializes Timestamp and serializes identically',
      () async {
        final fake = FakeFirebaseFirestore();
        await fake.collection(LevelsRepository.LEVELS).doc('lvl-ts').set({
          'id': 'lvl-ts',
          'level': 1,
          'rider': false,
          'skillId': 'skill-horse',
          'levelName': 'Groundwork',
          'position': 0,
          'lastEditBy': 'trainer@example.com',
          'description': 'Yield hindquarters',
          'lastEditDate': Timestamp.fromDate(editDate),
          'learningDescription': 'In progress',
          'completeDescription': 'Mastered',
        });

        final snapshot = await fake
            .collection(LevelsRepository.LEVELS)
            .doc('lvl-ts')
            .get();
        final loaded = LevelFirestoreMapper.fromFirestore(snapshot, null);

        expect(loaded.id, 'lvl-ts');
        expect(loaded.level, 1);
        expect(loaded.rider, false);
        expect(loaded.skillId, 'skill-horse');
        expect(loaded.levelName, 'Groundwork');
        expect(loaded.position, 0);
        expect(loaded.lastEditBy, 'trainer@example.com');
        expect(loaded.description, 'Yield hindquarters');
        expect(loaded.lastEditDate, editDate);
        expect(loaded.learningDescription, 'In progress');
        expect(loaded.completeDescription, 'Mastered');

        final serialized = LevelFirestoreMapper.toFirestore(loaded);
        expect(serialized, {
          'position': 0,
          'id': 'lvl-ts',
          'level': 1,
          'rider': false,
          'skillId': 'skill-horse',
          'learningDescription': 'In progress',
          'completeDescription': 'Mastered',
          'levelName': 'Groundwork',
          'lastEditBy': 'trainer@example.com',
          'description': 'Yield hindquarters',
          'lastEditDate': editDate,
        });
      },
    );

    test('LevelFirestoreMapper omits null optional fields', () {
      final minimal = Level(
        id: null,
        level: null,
        rider: null,
        skillId: null,
        levelName: null,
        position: 5,
        lastEditBy: null,
        description: null,
        lastEditDate: null,
        learningDescription: null,
        completeDescription: null,
      );

      expect(LevelFirestoreMapper.toFirestore(minimal), {'position': 5});
    });

    test(
      'LevelsRepository reads and writes through LevelFirestoreMapper',
      () async {
        final fake = FakeFirebaseFirestore();
        final repo = LevelsRepository(firestore: fake);

        final riderLevel = Level(
          id: 'r1',
          level: 1,
          rider: true,
          skillId: 's1',
          levelName: 'Walk',
          position: 1,
          lastEditBy: 'admin@example.com',
          description: 'Desc',
          lastEditDate: editDate,
          learningDescription: 'Learn',
          completeDescription: 'Done',
        );
        final horseLevel = Level(
          id: 'h1',
          level: 1,
          rider: false,
          skillId: 's2',
          levelName: 'Halt',
          position: 2,
          lastEditBy: 'admin@example.com',
          description: 'Desc',
          lastEditDate: editDate,
          learningDescription: 'Learn',
          completeDescription: 'Done',
        );

        await repo.createOrUpdateLevel(level: riderLevel);
        await repo.createOrUpdateLevel(level: horseLevel);

        final single = await repo.getLevel(id: 'r1').first;
        expect(single?.levelName, 'Walk');
        expect(single?.lastEditDate, editDate);

        final riderLevels = await repo.getLevelsForRiderSkillTree().first;
        expect(riderLevels.map((l) => l.id), ['r1']);

        final horseLevels = await repo.getLevelsForHorseSkillTree().first;
        expect(horseLevels.map((l) => l.id), ['h1']);

        repo.deleteLevel(level: horseLevel);
        final afterDelete = await repo.getLevelsForHorseSkillTree().first;
        expect(afterDelete, isEmpty);
      },
    );
  });
}
