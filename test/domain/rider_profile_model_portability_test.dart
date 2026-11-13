import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RiderProfile backend-neutral model & Firestore mapper', () {
    final editDate = DateTime.utc(2025, 5, 1, 10, 15);
    final subStart = DateTime.utc(2025);
    final subEnd = DateTime.utc(2026);

    test(
      'Firebase-free toMap and fromMap round-trip all fields & nested items',
      () {
        final rider = RiderProfile(
          id: 'alex@example.com',
          name: 'Alex Rider',
          email: 'Alex@Example.com',
          bio: 'Eventing rider',
          picUrl: 'https://example.com/alex.jpg',
          homeUrl: 'HTTPS://EXAMPLE.COM',
          zipCode: '40502',
          cityName: 'Lexington',
          stateIso: 'KY',
          stateName: 'Kentucky',
          countryIso: 'US',
          countryName: 'United States',
          locationName: 'Lexington, KY',
          editor: true,
          isTrainer: true,
          subscribed: true,
          lastEditBy: 'alex@example.com',
          lastEditDate: editDate,
          subscriptionDate: subStart,
          subscriptionEndDate: subEnd,
          notes: [
            BaseListItem(
              id: 'n1',
              name: 'Alex Rider',
              message: 'Flatwork focus',
              date: editDate,
            ),
          ],
          students: [
            BaseListItem(id: 'student@example.com', name: 'Student One'),
          ],
          instructors: [
            BaseListItem(id: 'coach@example.com', name: 'Coach Sam'),
          ],
          ownedHorses: [BaseListItem(id: 'h1', name: 'Comet')],
          archivedHorses: [BaseListItem(id: 'h2', name: 'Starlight')],
          ownershipRosterVersion: 'roster-v4',
          studentHorses: [BaseListItem(id: 'h3', name: 'Scout')],
          savedProfilesList: [
            BaseListItem(id: 'peer@example.com', name: 'Peer'),
          ],
          savedResourcesList: const ['res-1', 'res-2'],
          messagesList: const ['msg-1'],
          skillLevels: [
            SkillLevel(
              skillId: 's1',
              skillName: 'Two-Point',
              verified: true,
              lastEditBy: 'coach@example.com',
              lastEditDate: editDate,
              levelState: LevelState.PROFICIENT,
            ),
          ],
        );

        final map = rider.toMap();
        expect(map['email'], 'alex@example.com');
        expect(map['homeUrl'], 'https://example.com');
        expect(map['lastEditDate'], editDate.toIso8601String());
        expect(map['subscriptionDate'], subStart.toIso8601String());
        expect(map['subscriptionEndDate'], subEnd.toIso8601String());
        expect(map['ownershipRosterVersion'], 'roster-v4');

        final restored = RiderProfile.fromMap(map);
        expect(restored.id, 'alex@example.com');
        expect(restored.email, 'alex@example.com');
        expect(restored.homeUrl, 'https://example.com');
        expect(restored.editor, isTrue);
        expect(restored.isTrainer, isTrue);
        expect(restored.subscribed, isTrue);
        expect(restored.lastEditDate, editDate);
        expect(restored.subscriptionDate, subStart);
        expect(restored.subscriptionEndDate, subEnd);
        expect(restored.notes?.single.message, 'Flatwork focus');
        expect(restored.students?.single.id, 'student@example.com');
        expect(restored.instructors?.single.id, 'coach@example.com');
        expect(restored.ownedHorses?.single.id, 'h1');
        expect(restored.archivedHorses?.single.id, 'h2');
        expect(restored.ownershipRosterVersion, 'roster-v4');
        expect(restored.studentHorses?.single.id, 'h3');
        expect(restored.savedProfilesList?.single.id, 'peer@example.com');
        expect(restored.savedResourcesList, ['res-1', 'res-2']);
        expect(restored.messagesList, ['msg-1']);
        expect(restored.skillLevels?.single.skillId, 's1');

        // Mutable fields remain supported.
        restored
          ..name = 'Alex Updated'
          ..bio = 'Updated bio';
        expect(restored.name, 'Alex Updated');
        expect(restored.bio, 'Updated bio');
      },
    );

    test(
      'RiderProfileFirestoreMapper deserializes legacy/admin docs and '
      'preserves exact Firestore serialization parity',
      () async {
        final fake = FakeFirebaseFirestore();
        final docRef = fake
            .collection('Rider_Profile')
            .doc('admin@horseandriderscompanion.com');
        await docRef.set({
          'id': 'admin-uid',
          'name': 'Horse and Rider Admin',
          'email': 'admin@horseandriderscompanion.com',
          'editor': true,
          'lastEditDate': Timestamp.fromDate(editDate),
          'subscriptionDate': Timestamp.fromDate(subStart),
          'subscriptionEndDate': Timestamp.fromDate(subEnd),
          'ownedHorses': [
            {'id': 'transferred-horse-1', 'name': 'Atlas'},
          ],
          'archivedHorses': [
            {'id': 'archived-horse-1', 'name': 'Biscuit'},
          ],
          'ownershipRosterVersion': 'v2',
          'skillLevels': [
            {
              'skillId': 's1',
              'skillName': 'Safety Check',
              'verified': true,
              'lastEditBy': 'admin@horseandriderscompanion.com',
              'lastEditDate': Timestamp.fromDate(editDate),
              'levelState': 'PROFICIENT',
            },
          ],
        });

        final snap = await docRef.get();
        final loaded = RiderProfileFirestoreMapper.fromFirestore(snap, null);

        expect(loaded.id, 'admin-uid');
        expect(loaded.editor, isTrue);
        expect(loaded.lastEditDate, editDate.toLocal());
        expect(loaded.subscriptionDate, subStart.toLocal());
        expect(loaded.subscriptionEndDate, subEnd.toLocal());
        expect(loaded.ownedHorses?.single.id, 'transferred-horse-1');
        expect(loaded.archivedHorses?.single.id, 'archived-horse-1');
        expect(loaded.ownershipRosterVersion, 'v2');
        expect(loaded.notes, isNull);
        expect(loaded.students, isNull);
        expect(loaded.skillLevels?.single.levelState, LevelState.PROFICIENT);

        final encoded = RiderProfileFirestoreMapper.toFirestore(loaded);
        expect(encoded['id'], 'admin-uid');
        expect(encoded['email'], 'admin@horseandriderscompanion.com');
        expect(encoded['lastEditDate'], editDate.toLocal());
        expect(encoded['subscriptionDate'], subStart.toLocal());
        expect(encoded['subscriptionEndDate'], subEnd.toLocal());
        expect(encoded['ownershipRosterVersion'], 'v2');
        expect(encoded.containsKey('notes'), isFalse);
        expect(encoded.containsKey('bio'), isFalse);
      },
    );

    test(
      'RiderProfileRepository persists and queries via '
      'RiderProfileFirestoreMapper',
      () async {
        final fake = FakeFirebaseFirestore();
        final repo = RiderProfileRepository(firestore: fake);
        final profile = RiderProfile(
          id: 'uid-1',
          name: 'Sam',
          email: 'sam@example.com',
          ownedHorses: [BaseListItem(id: 'horse-a', name: 'Comet')],
          instructors: [BaseListItem(id: 'coach@example.com', name: 'Coach')],
        );

        await repo.createOrUpdateRiderProfile(riderProfile: profile);
        final fetched = await repo.getRiderProfileByEmail(
          email: 'sam@example.com',
        );
        expect(fetched?.id, 'uid-1');
        expect(fetched?.email, 'sam@example.com');
        expect(fetched?.ownedHorses?.single.id, 'horse-a');
        expect(fetched?.instructors?.single.id, 'coach@example.com');

        await repo.addOrUpdateOwnedHorse(
          riderProfile: fetched,
          horseId: 'horse-b',
        );
        final updated = await repo.getRiderProfileByEmail(
          email: 'sam@example.com',
        );
        expect(
          updated?.ownedHorses?.map((h) => h.id),
          containsAll(['horse-a', 'horse-b']),
        );
      },
    );
  });
}
