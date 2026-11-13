import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillNode backend-neutral model and SkillNodeFirestoreMapper', () {
    test('constructs, copies, and round-trips via fromMap/toMap', () {
      final root = SkillNode(
        id: 'node-1',
        name: 'Halt',
        skillId: 'skill-halt',
        position: 0,
        parentId: null,
      );
      final child = root.copyWith(
        id: 'node-2',
        name: 'Rein Back',
        skillId: 'skill-rein-back',
        position: 1,
        parentId: 'node-1',
      );

      final decodedRoot = SkillNode.fromMap(root.toMap());
      expect(decodedRoot.id, 'node-1');
      expect(decodedRoot.parentId, isNull);
      expect(decodedRoot.position, 0);

      final decodedChild = SkillNode.fromMap(child.toMap());
      expect(decodedChild.id, 'node-2');
      expect(decodedChild.name, 'Rein Back');
      expect(decodedChild.skillId, 'skill-rein-back');
      expect(decodedChild.parentId, 'node-1');
      expect(decodedChild.position, 1);
    });

    test(
      'SkillNodeFirestoreMapper preserves doc ID and serializes identically',
      () async {
        final fake = FakeFirebaseFirestore();
        await fake.collection('SkillNodes').doc('node-doc').set({
          'name': 'Walk',
          'skillId': 'skill-walk',
          'parentId': 'root-node',
          'position': 2,
        });

        final snap = await fake.collection('SkillNodes').doc('node-doc').get();
        final loaded = SkillNodeFirestoreMapper.fromFirestore(snap, null);

        expect(loaded.id, 'node-doc');
        expect(loaded.name, 'Walk');
        expect(loaded.skillId, 'skill-walk');
        expect(loaded.parentId, 'root-node');
        expect(loaded.position, 2);

        expect(SkillNodeFirestoreMapper.toFirestore(loaded), {
          'id': 'node-doc',
          'name': 'Walk',
          'skillId': 'skill-walk',
          'parentId': 'root-node',
          'position': 2,
        });
      },
    );
  });
}
