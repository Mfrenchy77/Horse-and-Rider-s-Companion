import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late HorseProfileRepository horses;
  late RiderProfileRepository riders;
  setUp(() {
    db = FakeFirebaseFirestore();
    horses = HorseProfileRepository(firestore: db);
    riders = RiderProfileRepository(firestore: db);
  });

  test(
    'horse CRUD round trip preserves dates, ownership, location and notes',
    () async {
      final birth = DateTime.utc(2020, 2, 3);
      final horse = HorseProfile(
        id: 'h',
        name: 'Star',
        nickname: 'Starlight',
        currentOwnerId: 'r@example.com',
        currentOwnerName: 'Rider',
        height: 150,
        zipCode: '92101',
        dateOfBirth: birth,
        notes: [BaseListItem(id: 'note', name: 'Training')],
      );
      await horses.createOrUpdateHorseProfile(horseProfile: horse);
      final saved = await horses.getHorseProfileById(id: 'h').first;
      expect(saved?.name, 'Star');
      expect(saved?.dateOfBirth?.isAtSameMomentAs(birth), isTrue);
      expect(saved?.currentOwnerId, 'r@example.com');
      expect(saved?.notes?.single.name, 'Training');
      expect((await horses.getAllUsersHorses(ids: ['h']).first).single.id, 'h');
      await horses.deleteHorseProfile(id: 'h');
      expect(await horses.getHorseProfileById(id: 'h').first, isNull);
    },
  );
  test('empty and null horse IDs return an empty list', () async {
    expect(await horses.getAllUsersHorses(ids: []).first, isEmpty);
    expect(await horses.getAllUsersHorses(ids: null).first, isEmpty);
  });
  test(
    'horse searches match stored name, nickname and zip-code fields',
    () async {
      await horses.createOrUpdateHorseProfile(
        horseProfile: HorseProfile(
          id: 'h',
          name: 'Star',
          nickname: 'Starlight',
          zipCode: '92101',
        ),
      );
      expect((await horses.getHorseByName(name: 'Sta').first).single.id, 'h');
      expect(
        (await horses.getHorseByNickName(nickName: 'Starl').first).single.id,
        'h',
      );
      expect(
        (await horses.getHorseByZipCode(zipCode: '92101').first).single.id,
        'h',
      );
      expect(await horses.getHorseByZipCode(zipCode: '00000').first, isEmpty);
    },
  );
  test('rider CRUD uses the same document for email lookups', () async {
    final rider = RiderProfile(
      id: 'r',
      name: 'Rider',
      email: 'r@example.com',
      bio: 'Trainer',
      zipCode: '92101',
    );
    await riders.createOrUpdateRiderProfile(riderProfile: rider);
    expect(
      (await riders.getRiderProfile(email: rider.email).first)?.bio,
      'Trainer',
    );
    expect((await riders.getRiderProfileByEmail(email: rider.email))?.id, 'r');
    await riders.createOrUpdateRiderProfile(
      riderProfile: rider.copyWith(name: 'Updated'),
    );
    expect((await riders.getProfileByName(name: 'Updated').first)?.id, 'r');
    await riders.deleteRiderProfile(email: rider.email);
    expect(await riders.getRiderProfileByEmail(email: rider.email), isNull);
  });
  test(
    'rider name and location searches return only matching profiles',
    () async {
      for (final rider in [
        RiderProfile(
          id: '1',
          name: 'Alice',
          email: 'alice@example.com',
          zipCode: '92101',
        ),
        RiderProfile(
          id: '2',
          name: 'Bob',
          email: 'bob@example.com',
          zipCode: '10001',
        ),
      ]) {
        await riders.createOrUpdateRiderProfile(riderProfile: rider);
      }
      expect(
        (await riders.getProfilesByName(name: 'Ali').first).single.id,
        '1',
      );
      expect(
        (await riders.getProfilesByZipcode(zipcode: '10001').first).single.id,
        '2',
      );
      expect(await riders.getProfileByName(name: 'Missing').first, isNull);
    },
  );
  test(
    'adding ownership is idempotent and preserves existing entries',
    () async {
      final rider = RiderProfile(
        id: 'r',
        name: 'Rider',
        email: 'r@example.com',
      );
      await riders.createOrUpdateRiderProfile(riderProfile: rider);
      await riders.addOrUpdateOwnedHorse(riderProfile: rider, horseId: 'h');
      await riders.addOrUpdateOwnedHorse(riderProfile: rider, horseId: 'h');
      final saved = await riders.getRiderProfileByEmail(email: rider.email);
      expect(saved?.ownedHorses?.map((horse) => horse.id), ['h']);
    },
  );
}
