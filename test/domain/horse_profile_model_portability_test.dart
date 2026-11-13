import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HorseProfile backend-neutral model & Firestore mapper', () {
    final dob = DateTime.utc(2016, 5, 12);
    final purchaseDate = DateTime.utc(2020, 8);
    final editDate = DateTime.utc(2025, 3, 14, 9, 45);

    test(
      'Firebase-free toMap and fromMap round-trip all fields & nested items',
      () {
      final horse = HorseProfile(
        id: 'horse-1',
        name: 'Comet',
        currentOwnerId: 'owner@example.com',
        currentOwnerName: 'Alex Owner',
        archiveStatus: 'archived',
        saleListing: (
          price: '12000',
          location: 'Lexington, KY',
          description: 'Well-schooled gelding',
        ),
        transferRequestId: 'tx-42',
        ownershipVersion: 'v3',
        height: 165,
        breed: 'Warmblood',
        color: 'Bay',
        gender: 'Gelding',
        picUrl: 'https://example.com/comet.jpg',
        zipCode: '40502',
        cityName: 'Lexington',
        nickname: 'Comet',
        stateIso: 'KY',
        stateName: 'Kentucky',
        countryIso: 'US',
        countryName: 'United States',
        locationName: 'Lexington, KY',
        lastEditBy: 'owner@example.com',
        dateOfBirth: dob,
        dateOfPurchase: purchaseDate,
        lastEditDate: editDate,
        purchasePrice: 10000,
        notes: [
          BaseListItem(
            id: 'note-1',
            name: 'Alex Owner',
            message: 'Great trail ride',
            date: editDate,
          ),
        ],
        instructors: [
          BaseListItem(
            id: 'coach@example.com',
            name: 'Coach Sam',
          ),
        ],
        skillLevels: [
          SkillLevel(
            skillId: 'skill-1',
            skillName: 'Leading',
            verified: true,
            lastEditBy: 'coach@example.com',
            lastEditDate: editDate,
            levelState: LevelState.PROFICIENT,
          ),
        ],
      );

      expect(horse.isArchived, isTrue);

      final map = horse.toMap();
      expect(map['dateOfBirth'], dob.toIso8601String());
      expect(map['dateOfPurchase'], purchaseDate.toIso8601String());
      expect(map['lastEditDate'], editDate.toIso8601String());
      expect(map['archiveStatus'], 'archived');
      expect(map['ownershipVersion'], 'v3');
      expect(map['transferRequestId'], 'tx-42');

      final restored = HorseProfile.fromMap(map);
      expect(restored.id, 'horse-1');
      expect(restored.name, 'Comet');
      expect(restored.currentOwnerId, 'owner@example.com');
      expect(restored.currentOwnerName, 'Alex Owner');
      expect(restored.archiveStatus, 'archived');
      expect(restored.isArchived, isTrue);
      expect(restored.saleListing?.price, '12000');
      expect(restored.saleListing?.location, 'Lexington, KY');
      expect(restored.transferRequestId, 'tx-42');
      expect(restored.ownershipVersion, 'v3');
      expect(restored.dateOfBirth, dob);
      expect(restored.dateOfPurchase, purchaseDate);
      expect(restored.lastEditDate, editDate);
      expect(restored.notes?.single.message, 'Great trail ride');
      expect(restored.instructors?.single.id, 'coach@example.com');
      expect(restored.skillLevels?.single.skillId, 'skill-1');
      expect(restored.skillLevels?.single.levelState, LevelState.PROFICIENT);

      // Mutable fields remain supported.
      restored
        ..height = 168
        ..currentOwnerId = 'admin@example.com';
      expect(restored.height, 168);
      expect(restored.currentOwnerId, 'admin@example.com');
    });

    test(
      'HorseProfileFirestoreMapper deserializes legacy/archived docs and '
      'preserves exact Firestore serialization parity',
      () async {
        final fake = FakeFirebaseFirestore();
        final docRef = fake.collection('Horse_Profile').doc('horse-fs');
        await docRef.set({
          'id': 'horse-fs',
          'name': 'Starlight',
          'currentOwnerId': 'admin@horseandriderscompanion.com',
          'currentOwnerName': 'Admin Account',
          'archiveStatus': 'deceased',
          'ownershipVersion': 'v2',
          'transferRequestId': 'tr-99',
          'saleListing': {
            'location': 'Ocala, FL',
            'description': 'Retired mare',
          },
          'dateOfBirth': Timestamp.fromDate(dob),
          'dateOfPurchase': Timestamp.fromDate(purchaseDate),
          'lastEditDate': Timestamp.fromDate(editDate),
          'notes': [
            {
              'id': 'n1',
              'message': 'Vet check clear',
              'date': Timestamp.fromDate(editDate),
            },
          ],
          'instructors': [
            {'id': 'inst@example.com', 'name': 'Instructor'},
          ],
          'skillLevels': [
            {
              'skillId': 's1',
              'skillName': 'Grooming',
              'verified': true,
              'lastEditBy': 'inst@example.com',
              'lastEditDate': Timestamp.fromDate(editDate),
              'levelState': 'LEARNING',
            },
          ],
        });

        final snap = await docRef.get();
        final loaded = HorseProfileFirestoreMapper.fromFirestore(snap, null);

        expect(loaded.id, 'horse-fs');
        expect(loaded.isArchived, isTrue);
        expect(loaded.archiveStatus, 'deceased');
        expect(loaded.ownershipVersion, 'v2');
        expect(loaded.transferRequestId, 'tr-99');
        expect(loaded.saleListing?.price, '');
        expect(loaded.saleListing?.location, 'Ocala, FL');
        expect(loaded.dateOfBirth, dob.toLocal());
        expect(loaded.dateOfPurchase, purchaseDate.toLocal());
        expect(loaded.lastEditDate, editDate.toLocal());
        expect(loaded.notes?.single.date, editDate.toLocal());
        expect(loaded.instructors?.single.name, 'Instructor');
        expect(loaded.skillLevels?.single.levelState, LevelState.LEARNING);

        final encoded = HorseProfileFirestoreMapper.toFirestore(loaded);
        expect(encoded['id'], 'horse-fs');
        expect(encoded['name'], 'Starlight');
        expect(encoded['currentOwnerId'], 'admin@horseandriderscompanion.com');
        expect(encoded['currentOwnerName'], 'Admin Account');
        expect(encoded['dateOfBirth'], dob.toLocal());
        expect(encoded['dateOfPurchase'], purchaseDate.toLocal());
        expect(encoded['lastEditDate'], editDate.toLocal());
        // Server-managed fields are omitted from client Firestore writes.
        expect(encoded.containsKey('archiveStatus'), isFalse);
        expect(encoded.containsKey('saleListing'), isFalse);
        expect(encoded.containsKey('transferRequestId'), isFalse);
        expect(encoded.containsKey('ownershipVersion'), isFalse);
        // Optional unset fields are omitted.
        expect(encoded.containsKey('breed'), isFalse);
        expect(encoded.containsKey('height'), isFalse);
      },
    );

    test(
      'handles missing legacy fields and round-trips via '
      'HorseProfileRepository',
      () async {
        final fake = FakeFirebaseFirestore();
        final repo = HorseProfileRepository(firestore: fake);

        final minimal = HorseProfile.fromMap({
          'id': 'horse-min',
          'name': 'Biscuit',
        });
        expect(minimal.archiveStatus, 'active');
        expect(minimal.isArchived, isFalse);
        expect(minimal.currentOwnerId, '');
        expect(minimal.currentOwnerName, '');
        expect(minimal.notes, isNull);
        expect(minimal.instructors, isNull);
        expect(minimal.skillLevels, isNull);

        await repo.createOrUpdateHorseProfile(horseProfile: minimal);
        final fetched = await repo.getHorseProfileById(id: 'horse-min').first;
        expect(fetched?.id, 'horse-min');
        expect(fetched?.name, 'Biscuit');
      },
    );
  });
}
