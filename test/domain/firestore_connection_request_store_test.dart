import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreConnectionRequestStore and ConnectionRequest', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreConnectionRequestStore store;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      store = FirestoreConnectionRequestStore(firestore: firestore);
    });

    ConnectionRequest buildRequest({
      required String id,
      required ConnectionRequestKind kind,
      required DateTime createdAt,
      String senderEmail = 'sender@example.com',
      String recipientEmail = 'recipient@example.com',
      String? horseId,
      String? horseName,
      String? horseOwnerId,
      String? horseOwnerName,
    }) {
      return ConnectionRequest(
        id: id,
        messageId: 'msg-$id',
        kind: kind,
        senderEmail: senderEmail,
        senderName: 'Sender Name',
        recipientEmail: recipientEmail,
        recipientName: 'Recipient Name',
        title: 'Title $id',
        summary: 'Summary $id',
        parties: const ['Sender Name', 'Recipient Name'],
        partiesIds: [senderEmail.toLowerCase(), recipientEmail.toLowerCase()],
        createdAt: createdAt,
        horseId: horseId,
        horseName: horseName,
        horseOwnerId: horseOwnerId,
        horseOwnerName: horseOwnerName,
      );
    }

    test(
      'supports all four ConnectionRequestKind values via sendRequest and '
      'watchRequests',
      () async {
        final base = DateTime(2026, 11, 13, 10);
        final requests = [
          buildRequest(
            id: 'req-instructor',
            kind: ConnectionRequestKind.instructor,
            createdAt: base,
          ),
          buildRequest(
            id: 'req-student',
            kind: ConnectionRequestKind.student,
            createdAt: base.add(const Duration(minutes: 1)),
          ),
          buildRequest(
            id: 'req-student-horse',
            kind: ConnectionRequestKind.studentHorse,
            createdAt: base.add(const Duration(minutes: 2)),
            horseId: 'horse-3',
            horseName: 'Comet',
            horseOwnerId: 'recipient@example.com',
            horseOwnerName: 'Recipient Name',
          ),
          buildRequest(
            id: 'req-transfer',
            kind: ConnectionRequestKind.transferHorse,
            createdAt: base.add(const Duration(minutes: 3)),
            horseId: 'horse-4',
            horseName: 'Apollo',
            horseOwnerId: 'sender@example.com',
            horseOwnerName: 'Sender Name',
          ),
        ];

        for (final req in requests) {
          await store.sendRequest(req);
        }

        final received = await store
            .watchRequests(userEmail: '  RECIPIENT@example.com ')
            .first;

        expect(received, hasLength(4));
        // Sorted descending by createdAt
        expect(received.map((r) => r.id).toList(), [
          'req-transfer',
          'req-student-horse',
          'req-student',
          'req-instructor',
        ]);
        expect(received.map((r) => r.kind).toList(), [
          ConnectionRequestKind.transferHorse,
          ConnectionRequestKind.studentHorse,
          ConnectionRequestKind.student,
          ConnectionRequestKind.instructor,
        ]);
        expect(received.first.horseId, 'horse-4');
        expect(received.first.horseName, 'Apollo');
        expect(received.first.horseOwnerId, 'sender@example.com');
      },
    );

    test(
      'streams realtime updates and excludes dismissed or unrelated requests',
      () async {
        final now = DateTime(2026, 11, 13, 12);
        final req1 = buildRequest(
          id: 'req-1',
          kind: ConnectionRequestKind.instructor,
          createdAt: now,
        );
        final req2 = buildRequest(
          id: 'req-2',
          kind: ConnectionRequestKind.transferHorse,
          createdAt: now.add(const Duration(minutes: 5)),
          horseId: 'h-2',
          horseName: 'Star',
        );
        final unrelated = buildRequest(
          id: 'req-other',
          kind: ConnectionRequestKind.student,
          createdAt: now,
          senderEmail: 'a@example.com',
          recipientEmail: 'b@example.com',
        );

        await store.sendRequest(unrelated);

        final emissions = <List<ConnectionRequest>>[];
        final sub = store
            .watchRequests(userEmail: 'recipient@example.com')
            .listen(emissions.add);

        await Future<void>.delayed(Duration.zero);
        await store.sendRequest(req1);
        await Future<void>.delayed(Duration.zero);
        await store.sendRequest(req2);
        await Future<void>.delayed(Duration.zero);
        await store.dismissRequest(request: req1, dismissalNote: 'Declined');
        await Future<void>.delayed(Duration.zero);

        await sub.cancel();

        expect(emissions.first, isEmpty);
        expect(emissions.last.map((r) => r.id).toList(), ['req-2']);

        final dismissedDoc = await firestore
            .collection(FirestoreConnectionRequestStore.requestsCollection)
            .doc('req-1')
            .get();
        expect(dismissedDoc.data()?['status'], 'dismissed');
        expect(dismissedDoc.data()?['dismissalNote'], 'Declined');
        expect(dismissedDoc.data()?['updatedAt'], isA<Timestamp>());
      },
    );

    test('deterministic IDs are idempotent on repeated sendRequest', () async {
      final now = DateTime(2026, 11, 13, 14);
      final req = buildRequest(
        id: 'legacy_conv_1_msg_1',
        kind: ConnectionRequestKind.transferHorse,
        createdAt: now,
        horseId: 'horse-99',
        horseName: 'Spirit',
      );

      await store.sendRequest(req);
      await store.sendRequest(req);

      final snapshot = await firestore
          .collection(FirestoreConnectionRequestStore.requestsCollection)
          .get();
      expect(snapshot.docs, hasLength(1));
      expect(snapshot.docs.single.id, 'legacy_conv_1_msg_1');
    });

    test('watchRequests returns empty list when userEmail is blank', () async {
      final items = await store.watchRequests(userEmail: '   ').first;
      expect(items, isEmpty);
    });

    test('fromMap/toMap round-trips all kinds and optional fields', () {
      final created = DateTime(2026, 11, 13, 15, 30);
      for (final kind in ConnectionRequestKind.values) {
        final original = ConnectionRequest(
          id: 'id-${kind.name}',
          messageId: 'msg-${kind.name}',
          kind: kind,
          senderEmail: 'alice@example.com',
          senderName: 'Alice',
          senderPicUrl: 'https://example.com/alice.png',
          recipientEmail: 'bob@example.com',
          recipientName: 'Bob',
          title: 'Title',
          summary: 'Body',
          parties: const ['Alice', 'Bob'],
          partiesIds: const ['alice@example.com', 'bob@example.com'],
          createdAt: created,
          isAccepted: true,
          horseId: 'horse-1',
          horseName: 'Shadow',
          horsePicUrl: 'https://example.com/shadow.png',
          horseOwnerId: 'alice@example.com',
          horseOwnerName: 'Alice',
        );

        final map = original.toMap();
        final restored = ConnectionRequest.fromMap(map);

        expect(restored.id, original.id);
        expect(restored.messageId, original.messageId);
        expect(restored.kind, original.kind);
        expect(restored.senderEmail, original.senderEmail);
        expect(restored.senderName, original.senderName);
        expect(restored.senderPicUrl, original.senderPicUrl);
        expect(restored.recipientEmail, original.recipientEmail);
        expect(restored.recipientName, original.recipientName);
        expect(restored.title, original.title);
        expect(restored.summary, original.summary);
        expect(restored.parties, original.parties);
        expect(restored.partiesIds, original.partiesIds);
        expect(restored.createdAt, original.createdAt);
        expect(restored.isAccepted, original.isAccepted);
        expect(restored.horseId, original.horseId);
        expect(restored.horseName, original.horseName);
        expect(restored.horsePicUrl, original.horsePicUrl);
        expect(restored.horseOwnerId, original.horseOwnerId);
        expect(restored.horseOwnerName, original.horseOwnerName);
      }
    });

    test(
      'fromLegacyMessage and toLegacyMessage preserve request semantics',
      () {
        final created = DateTime(2026, 11, 13, 16);
        final original = buildRequest(
          id: 'req-legacy',
          kind: ConnectionRequestKind.studentHorse,
          createdAt: created,
          horseId: 'horse-5',
          horseName: 'Blaze',
          horseOwnerId: 'recipient@example.com',
          horseOwnerName: 'Recipient Name',
        );

        final legacyMessage = original.toLegacyMessage();
        final conversation = Conversation(
          id: original.id,
          parties: original.parties,
          partiesIds: original.partiesIds,
          createdBy: original.senderName,
          createdOn: created,
          lastEditBy: original.senderName,
          lastEditDate: created,
          recentMessage: legacyMessage,
        );
      final restored = ConnectionRequest.fromLegacyMessage(
        legacyMessage,
        conversation: conversation,
      );

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.messageId, original.messageId);
      expect(restored.kind, original.kind);
      expect(restored.senderEmail, original.senderEmail);
      expect(restored.senderName, original.senderName);
      expect(restored.recipientEmail, original.recipientEmail);
      expect(restored.horseId, original.horseId);
      expect(restored.horseName, original.horseName);
      expect(restored.horseOwnerId, original.horseOwnerId);
      expect(restored.horseOwnerName, original.horseOwnerName);
    });
  });
}
