import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const email = 'rider@example.com';
  late RiderProfileRepository repository;

  setUp(() async {
    repository = RiderProfileRepository(firestore: FakeFirebaseFirestore());
    await repository.createOrUpdateRiderProfile(
      riderProfile: RiderProfile(
        id: 'rider',
        email: email,
        name: 'Rider',
        bio: 'Trail rider',
        notes: [
          BaseListItem(
            id: 'legacy',
            name: 'Vet visit',
            imageUrl: 'LogTag.Health',
            parentId: email,
          ),
          BaseListItem(
            id: 'trainer',
            name: 'Lesson feedback',
            parentId: 'instructor@example.com',
          ),
          BaseListItem(
            id: 'audit',
            name: 'Skill changed',
            imageUrl: 'LogTag.Edit',
            parentId: email,
          ),
        ],
      ),
    );
  });

  BaseListItem entry(String id, String notes) => BaseListItem(
    id: id,
    date: DateTime.utc(2025, 4, 3),
    name: notes,
    parentId: email,
    riderLog: const RiderLogDetails(
      type: RiderLogType.lesson,
      title: 'First lesson',
      instructor: 'Alex',
      focus: 'Transitions',
      nextSteps: 'Repeat on both reins',
    ),
  );

  test(
    'append and edit preserve legacy notes and other profile data',
    () async {
      await repository.saveRiderLogEntry(
        email: email,
        entry: entry('new', 'Original'),
        isEdit: false,
      );
      await repository.saveRiderLogEntry(
        email: email,
        entry: entry('new', 'Original'),
        isEdit: false,
      );
      await repository.saveRiderLogEntry(
        email: email,
        entry: entry('new', 'Updated'),
        isEdit: true,
      );
      final saved = (await repository.getRiderProfileByEmail(email: email))!;
      expect(saved.bio, 'Trail rider');
      expect(saved.notes!.map((note) => note.id), [
        'legacy',
        'trainer',
        'audit',
        'new',
      ]);
      expect(saved.notes!.first.riderLogType, RiderLogType.care);
      final latest = saved.notes!.last;
      expect(latest.name, 'Updated');
      expect(latest.riderLog?.instructor, 'Alex');
      expect(latest.riderLog?.horse, isNull);
      expect(latest.riderLog?.nextSteps, 'Repeat on both reins');
    },
  );

  test('rejects edits to instructor, activity, and missing entries', () async {
    for (final id in ['trainer', 'audit', 'missing']) {
      await expectLater(
        repository.saveRiderLogEntry(
          email: email,
          entry: entry(id, 'Changed'),
          isEdit: true,
        ),
        throwsStateError,
      );
    }
    await expectLater(
      repository.saveRiderLogEntry(
        email: 'instructor@example.com',
        entry: entry('new', 'Changed'),
        isEdit: false,
      ),
      throwsArgumentError,
    );
  });
}
