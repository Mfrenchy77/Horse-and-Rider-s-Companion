import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'BaseListItem backend-neutral model and BaseListItemFirestoreMapper',
    () {
    final entryDate = DateTime(2026, 5, 10, 8, 30);

    test('constructs and round-trips via fromMap/toMap without Firebase', () {
      final item = BaseListItem(
        id: 'entry-1',
        name: 'Great session',
        date: entryDate,
        extra: 'Extra info',
        depth: 2,
        message: 'Alex',
        imageUrl: 'LogTag.Training',
        parentId: 'alex@example.com',
        isSelected: true,
        isCollapsed: false,
        riderLog: const RiderLogDetails(
          type: RiderLogType.training,
          horseId: 'horse-1',
          horse: 'Comet',
          title: 'Worked on transitions',
        ),
      );

      final map = item.toMap();
      expect(map['date'], entryDate.toIso8601String());

      final decoded = BaseListItem.fromMap(map);
      expect(decoded.id, item.id);
      expect(decoded.name, item.name);
      expect(decoded.date, item.date);
      expect(decoded.extra, item.extra);
      expect(decoded.depth, item.depth);
      expect(decoded.message, item.message);
      expect(decoded.imageUrl, item.imageUrl);
      expect(decoded.parentId, item.parentId);
      expect(decoded.isSelected, item.isSelected);
      expect(decoded.isCollapsed, item.isCollapsed);
      expect(decoded.riderLog?.horseId, 'horse-1');
      expect(decoded.riderLogType, RiderLogType.training);
      expect(decoded.canEditRiderLog('alex@example.com'), isTrue);
    });

    test('fromJson/fromMap support DateTime, ISO string, epoch ms, and nulls', () {
      final fromIso = BaseListItem.fromJson({
        'id': 'i1',
        'date': entryDate.toIso8601String(),
      });
      final fromEpoch = BaseListItem.fromMap({
        'id': 'i2',
        'date': entryDate.millisecondsSinceEpoch,
      });
      final fromNull = BaseListItem.fromMap({});

      expect(fromIso.date, entryDate);
      expect(fromEpoch.date, entryDate);
      expect(fromNull.id, isNull);
      expect(fromNull.date, isNull);
      expect(fromNull.riderLog, isNull);
    });

    test(
      'BaseListItemFirestoreMapper deserializes Timestamp and serializes '
      'identically',
      () async {
        final fake = FakeFirebaseFirestore();
        await fake.collection('Items').doc('item-ts').set({
          'id': 'item-ts',
          'name': 'Contact Name',
          'date': Timestamp.fromDate(entryDate),
          'depth': 1,
          'extra': 'trainer',
          'message': 'Hello',
          'parentId': 'owner@example.com',
          'imageUrl': 'https://example.com/pic.png',
          'isSelected': false,
          'isCollapsed': true,
        });

        final snap = await fake.collection('Items').doc('item-ts').get();
        final loaded = BaseListItemFirestoreMapper.fromFirestore(snap, null);

        expect(loaded.id, 'item-ts');
        expect(loaded.date, entryDate);
        expect(loaded.name, 'Contact Name');
        expect(loaded.isCollapsed, true);

        expect(BaseListItemFirestoreMapper.toFirestore(loaded), {
          'id': 'item-ts',
          'name': 'Contact Name',
          'date': entryDate,
          'depth': 1,
          'extra': 'trainer',
          'message': 'Hello',
          'parentId': 'owner@example.com',
          'imageUrl': 'https://example.com/pic.png',
          'isSelected': false,
          'isCollapsed': true,
        });

        expect(
          BaseListItemFirestoreMapper.toFirestore(BaseListItem(id: null)),
          <String, dynamic>{},
        );
      },
    );
  });
}
