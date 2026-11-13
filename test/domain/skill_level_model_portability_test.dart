import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillLevel backend-neutral model and SkillLevelFirestoreMapper', () {
    final editDate = DateTime(2026, 5, 3, 11, 45);

    test('constructs and round-trips via fromMap/toMap without Firebase', () {
      for (final levelState in LevelState.values) {
        final original = SkillLevel(
          skillId: 'skill-${levelState.name}',
          skillName: 'Skill ${levelState.name}',
          verified: levelState == LevelState.VERIFIED,
          lastEditBy: 'coach@example.com',
          lastEditDate: editDate,
          levelState: levelState,
        );

        final map = original.toMap();
        expect(map['lastEditDate'], editDate.toIso8601String());

        final decoded = SkillLevel.fromMap(map);
        expect(decoded.skillId, original.skillId);
        expect(decoded.skillName, original.skillName);
        expect(decoded.verified, original.verified);
        expect(decoded.lastEditBy, original.lastEditBy);
        expect(decoded.lastEditDate, original.lastEditDate);
        expect(decoded.levelState, original.levelState);
      }
    });

    test('fromMap and fromJson support DateTime, ISO, epoch ms, and nulls', () {
      final fromIso = SkillLevel.fromJson({
        'skillId': 's1',
        'skillName': 'Balance',
        'verified': true,
        'lastEditBy': null,
        'lastEditDate': editDate.toIso8601String(),
        'levelState': 'PROFICIENT',
      });
      final fromEpoch = SkillLevel.fromMap({
        'skillId': 's2',
        'skillName': 'Halt',
        'lastEditDate': editDate.millisecondsSinceEpoch,
        'levelState': 'LEARNING',
      });
      final fromUnknown = SkillLevel.fromMap({
        'skillId': 's3',
        'skillName': 'Walk',
        'levelState': 'LEGACY_UNKNOWN',
      });

      expect(fromIso.lastEditDate, editDate);
      expect(fromIso.lastEditBy, isNull);
      expect(fromIso.levelState, LevelState.PROFICIENT);

      expect(fromEpoch.lastEditDate, editDate);
      expect(fromEpoch.verified, false);
      expect(fromEpoch.levelState, LevelState.LEARNING);

      expect(fromUnknown.lastEditDate, isNull);
      expect(fromUnknown.levelState, LevelState.NO_PROGRESS);
    });

    test(
      'SkillLevelFirestoreMapper deserializes Timestamp and serializes '
      'identically for toFirestore and toJson',
      () async {
        final fake = FakeFirebaseFirestore();
        await fake.collection('SkillLevels').doc('sl-1').set({
          'skillId': 's-canter',
          'skillName': 'Canter',
          'verified': true,
          'lastEditBy': 'trainer@example.com',
          'lastEditDate': Timestamp.fromDate(editDate),
          'levelState': 'VERIFIED',
        });

        final snap = await fake.collection('SkillLevels').doc('sl-1').get();
        final loaded = SkillLevelFirestoreMapper.fromFirestore(snap, null);

        expect(loaded.skillId, 's-canter');
        expect(loaded.skillName, 'Canter');
        expect(loaded.verified, true);
        expect(loaded.lastEditBy, 'trainer@example.com');
        expect(loaded.lastEditDate, editDate);
        expect(loaded.levelState, LevelState.VERIFIED);

        expect(SkillLevelFirestoreMapper.toFirestore(loaded), {
          'skillId': 's-canter',
          'verified': true,
          'skillName': 'Canter',
          'lastEditBy': 'trainer@example.com',
          'lastEditDate': editDate,
          'levelState': 'VERIFIED',
        });

        final minimal = SkillLevel(
          skillId: 's-min',
          skillName: 'Walk',
          lastEditBy: null,
          lastEditDate: null,
        );
        expect(SkillLevelFirestoreMapper.toFirestore(minimal), {
          'skillId': 's-min',
          'verified': false,
          'skillName': 'Walk',
          'levelState': 'NO_PROGRESS',
        });
        expect(SkillLevelFirestoreMapper.toJson(minimal), {
          'skillId': 's-min',
          'verified': false,
          'skillName': 'Walk',
          'lastEditBy': null,
          'lastEditDate': null,
          'levelState': 'NO_PROGRESS',
        });
      },
    );

    test(
      'HorseProfile and RiderProfile preserve nested SkillLevel serialization',
      () async {
        final fake = FakeFirebaseFirestore();
        final skillLevelMap = {
          'skillId': 's1',
          'skillName': 'Leading',
          'verified': true,
          'lastEditBy': 'coach@example.com',
          'lastEditDate': Timestamp.fromDate(editDate),
          'levelState': 'PROFICIENT',
        };

        await fake.collection('Horses').doc('h1').set({
          'id': 'h1',
          'name': 'Comet',
          'currentOwnerId': 'alex@example.com',
          'currentOwnerName': 'Alex',
          'skillLevels': [skillLevelMap],
        });
        await fake.collection('Riders').doc('r1').set({
          'id': 'r1',
          'name': 'Alex',
          'email': 'alex@example.com',
          'skillLevels': [skillLevelMap],
        });

        final horseSnap = await fake.collection('Horses').doc('h1').get();
        final horse = HorseProfile.fromFirestore(horseSnap, null);
        expect(horse.skillLevels, hasLength(1));
        expect(horse.skillLevels!.first.lastEditDate, editDate);
        expect(horse.skillLevels!.first.levelState, LevelState.PROFICIENT);
        expect(horse.toFirestore()['skillLevels'], [
          {
            'skillId': 's1',
            'verified': true,
            'skillName': 'Leading',
            'lastEditBy': 'coach@example.com',
            'lastEditDate': editDate,
            'levelState': 'PROFICIENT',
          },
        ]);

        final riderSnap = await fake.collection('Riders').doc('r1').get();
        final rider = RiderProfile.fromFirestore(riderSnap, null);
        expect(rider.skillLevels, hasLength(1));
        expect(rider.skillLevels!.first.lastEditDate, editDate);
        expect(rider.skillLevels!.first.levelState, LevelState.PROFICIENT);
        expect(rider.toFirestore()['skillLevels'], [
          {
            'skillId': 's1',
            'verified': true,
            'skillName': 'Leading',
            'lastEditBy': 'coach@example.com',
            'lastEditDate': editDate,
            'levelState': 'PROFICIENT',
          },
        ]);
      },
    );
  });
}
