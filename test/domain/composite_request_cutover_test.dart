import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/View/app.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/TransferHorseDialog/cubit/transfer_horse_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/requests_badge_button.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessagesStore extends Mock implements MessagesStore {}

class _MockSkillTreeStore extends Mock implements SkillTreeStore {}

class _MockResourcesStore extends Mock implements ResourcesStore {}

class _MockRiderProfileStore extends Mock implements RiderProfileStore {}

class _MockHorseProfileStore extends Mock implements HorseProfileStore {}

class _MockAuthGateway extends Mock implements AuthGateway {}

void main() {
  group('Composite request store cutover & canonical identity', () {
    late FakeFirebaseFirestore fakeFirestore;
    late _MockMessagesStore messagesStore;
    late _MockSkillTreeStore skillTreeStore;
    late _MockResourcesStore resourcesStore;
    late _MockRiderProfileStore riderProfileStore;
    late _MockHorseProfileStore horseProfileStore;
    late _MockAuthGateway authGateway;
    late StreamController<List<Conversation>> conversationsController;

    final owner = RiderProfile(
      id: 'owner@example.com',
      email: 'owner@example.com',
      name: 'Owner Rider',
      picUrl: '',
    );
    final trainer = RiderProfile(
      id: 'trainer@example.com',
      email: 'trainer@example.com',
      name: 'Trainer Rider',
      isTrainer: true,
      picUrl: '',
    );
    final horse = HorseProfile(
      id: 'horse-1',
      name: 'Comet',
      currentOwnerId: owner.email,
      currentOwnerName: owner.name,
    );

    setUpAll(() {
      registerFallbackValue(
        Message(
          id: 'fallback',
          messageId: 'fallback',
          sender: '',
          senderId: '',
          senderProfilePicUrl: '',
          subject: '',
          message: '',
          recipients: const [],
          date: DateTime(2024),
        ),
      );
      registerFallbackValue(
        Conversation(
          id: 'fallback',
          parties: const [],
          partiesIds: const [],
          createdOn: DateTime(2024),
          lastEditDate: DateTime(2024),
          createdBy: '',
          lastEditBy: '',
          recentMessage: Message(
            id: 'fallback',
            messageId: 'fallback',
            sender: '',
            senderId: '',
            senderProfilePicUrl: '',
            subject: '',
            message: '',
            recipients: const [],
            date: DateTime(2024),
          ),
        ),
      );
    });

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      messagesStore = _MockMessagesStore();
      skillTreeStore = _MockSkillTreeStore();
      resourcesStore = _MockResourcesStore();
      riderProfileStore = _MockRiderProfileStore();
      horseProfileStore = _MockHorseProfileStore();
      authGateway = _MockAuthGateway();
      conversationsController =
          StreamController<List<Conversation>>.broadcast();

      when(() => authGateway.currentUser).thenReturn(User.empty);
      when(() => authGateway.user)
          .thenAnswer((_) => const Stream<User?>.empty());
      when(() => skillTreeStore.getSkills())
          .thenAnswer((_) => const Stream<List<Skill>>.empty());
      when(() => resourcesStore.getResources())
          .thenAnswer((_) => const Stream<List<Resource>>.empty());
      when(
        () => messagesStore.getConversations(
          userEmail: any(named: 'userEmail'),
        ),
      ).thenAnswer((_) => conversationsController.stream);
      when(() => messagesStore.createOrUpdateConversation(
            conversation: any(named: 'conversation'),
          )).thenAnswer((_) async {});
      when(() => messagesStore.createOrUpdateMessage(
            message: any(named: 'message'),
          )).thenAnswer((_) async {});
      when(() => riderProfileStore.getRiderProfileByEmail(
            email: any(named: 'email'),
          )).thenAnswer((_) async => null);
    });

    tearDown(() async {
      await conversationsController.close();
    });

    test('App defaults to FirebaseConnectionRequestStore when flag is off', () {
      expect(App.kUseCompositeRequestStore, isFalse);
      final app = App(
        settingsController: SettingsController(SettingsService()),
        messagesRepository: messagesStore,
        skillTreeRepository: skillTreeStore,
        resourcesRepository: resourcesStore,
        riderProfileRepository: riderProfileStore,
        horseProfileRepository: horseProfileStore,
        authenticationRepository: authGateway,
      );
      expect(app.useCompositeRequestStore, isFalse);
    });

    test(
      'App configures CompositeConnectionRequestStore when opted in and '
      'supports rollback',
      () {
        final optedIn = App(
          settingsController: SettingsController(SettingsService()),
          messagesRepository: messagesStore,
          skillTreeRepository: skillTreeStore,
          resourcesRepository: resourcesStore,
          riderProfileRepository: riderProfileStore,
          horseProfileRepository: horseProfileStore,
          authenticationRepository: authGateway,
          useCompositeRequestStore: true,
          firestore: fakeFirestore,
        );
        expect(optedIn.useCompositeRequestStore, isTrue);

        final rolledBack = App(
          settingsController: SettingsController(SettingsService()),
          messagesRepository: messagesStore,
          skillTreeRepository: skillTreeStore,
          resourcesRepository: resourcesStore,
          riderProfileRepository: riderProfileStore,
          horseProfileRepository: horseProfileStore,
          authenticationRepository: authGateway,
        );
        expect(rolledBack.useCompositeRequestStore, isFalse);
      },
    );

    test(
      'CompositeConnectionRequestStore shows legacy + Requests, deduplicates '
      'case-insensitively, and suppresses resolved items',
      () async {
        final primary =
            FirestoreConnectionRequestStore(firestore: fakeFirestore);
        final legacy =
            FirebaseConnectionRequestStore(messagesStore: messagesStore);
        final composite = CompositeConnectionRequestStore(
          primary: primary,
          legacy: legacy,
        );

        final cubit = AppCubit(
          messagesRepository: messagesStore,
          connectionRequestRepository: composite,
          skillTreeRepository: skillTreeStore,
          resourcesRepository: resourcesStore,
          riderProfileRepository: riderProfileStore,
          horseProfileRepository: horseProfileStore,
          authenticationRepository: authGateway,
          submitCoachingAction: (payload) async {
            final docId = payload['requestDocId'] as String?;
            if (docId != null && docId.isNotEmpty) {
              await fakeFirestore.collection('Requests').doc(docId).update({
                'status': 'accepted',
                'isAccepted': true,
              });
            }
            return {'status': 'pending'};
          },
        );

        cubit.emit(cubit.state.copyWith(isGuest: false, usersProfile: trainer));
        cubit.getConversations();
        await pumpEventQueue();

        // 1. Legacy-only request is visible
        final legacyConv = Conversation(
          id: 'conv_legacy_1',
          parties: [owner.name, trainer.name],
          partiesIds: [owner.email, trainer.email],
          createdOn: DateTime(2026),
          lastEditDate: DateTime(2026),
          createdBy: owner.email,
          lastEditBy: owner.email,
          recentMessage: Message(
            id: 'msg-leg-1',
            messageId: 'msg-leg-1',
            sender: owner.name,
            senderId: owner.email,
            senderProfilePicUrl: '',
            recipients: [trainer.name],
            subject: 'Instructor Request',
            message: 'Legacy pending request',
            messageType: MessageType.INSTRUCTOR_REQUEST,
            date: DateTime(2026),
            requestItem: BaseListItem(id: 'req-1'),
          ),
        );

        // 2. Duplicate present in both legacy (mixed-case senderId) & Requests
        final dupConv = Conversation(
          id: 'conv_dup',
          parties: [owner.name, trainer.name],
          partiesIds: [owner.email, trainer.email],
          createdOn: DateTime(2026, 1, 2),
          lastEditDate: DateTime(2026, 1, 2),
          createdBy: owner.email,
          lastEditBy: owner.email,
          recentMessage: Message(
            id: 'msg-dup-1',
            messageId: 'msg-dup-1',
            sender: owner.name,
            senderId: 'Owner@Example.com',
            senderProfilePicUrl: '',
            recipients: [trainer.name],
            subject: 'Instructor Request',
            message: 'Duplicate request',
            messageType: MessageType.INSTRUCTOR_REQUEST,
            date: DateTime(2026, 1, 2),
            requestItem: BaseListItem(id: 'req-dup'),
          ),
        );

        await primary.sendRequest(
          ConnectionRequest(
            id: 'conv_dup',
            messageId: 'msg-dup-1',
            kind: ConnectionRequestKind.instructor,
            senderEmail: owner.email,
            senderName: owner.name,
            recipientEmail: trainer.email,
            recipientName: trainer.name,
            title: 'Instructor Request',
            summary: 'Duplicate request',
            parties: [owner.name, trainer.name],
            partiesIds: [owner.email, trainer.email],
            createdAt: DateTime(2026, 1, 2),
          ),
        );

        // 3. New Requests-only document
        await primary.sendRequest(
          ConnectionRequest(
            id: 'conv_new',
            messageId: 'msg-new-1',
            kind: ConnectionRequestKind.studentHorse,
            senderEmail: owner.email,
            senderName: owner.name,
            recipientEmail: trainer.email,
            recipientName: trainer.name,
            title: 'Student Horse Request',
            summary: 'New Requests-only item',
            parties: [owner.name, trainer.name],
            partiesIds: [owner.email, trainer.email],
            createdAt: DateTime(2026, 1, 3),
            horseId: horse.id,
            horseName: horse.name,
          ),
        );

        conversationsController.add([legacyConv, dupConv]);
        await pumpEventQueue();

        // Expect 3 distinct requests (dupConv deduplicated), badge count = 3
        expect(cubit.pendingConnectionRequests(), hasLength(3));
        expect(cubit.pendingRequestCount(), 3);

        // Accept Requests-backed duplicate; watchResolvedKeys suppresses legacy
        final dupReq = cubit.pendingConnectionRequests().firstWhere(
              (r) => r.messageId == 'msg-dup-1',
            );
        await cubit.acceptConnectionRequest(dupReq);
        await pumpEventQueue();
        expect(cubit.pendingRequestCount(), 2);

        // Deny the Requests-only item
        final newReq = cubit.pendingConnectionRequests().firstWhere(
              (r) => r.messageId == 'msg-new-1',
            );
        await cubit.denyConnectionRequest(newReq);
        await pumpEventQueue();
        expect(cubit.pendingRequestCount(), 1);

        // Remaining item is the legacy-only request
        expect(
          cubit.pendingConnectionRequests().single.messageId,
          'msg-leg-1',
        );

        // Rollback to legacy adapter still reads legacy conversations cleanly
        final legacyFuture =
            legacy.watchRequests(userEmail: trainer.email).first;
        conversationsController.add([legacyConv]);
        final legacyOnly = await legacyFuture;
        expect(legacyOnly.map((r) => r.messageId), contains('msg-leg-1'));

        await cubit.close();
      },
    );

    testWidgets(
      'RequestsBadgeButton reflects CompositeConnectionRequestStore count',
      (tester) async {
        final primary =
            FirestoreConnectionRequestStore(firestore: fakeFirestore);
        final legacy =
            FirebaseConnectionRequestStore(messagesStore: messagesStore);
        final composite = CompositeConnectionRequestStore(
          primary: primary,
          legacy: legacy,
        );
        final cubit = AppCubit(
          messagesRepository: messagesStore,
          connectionRequestRepository: composite,
          skillTreeRepository: skillTreeStore,
          resourcesRepository: resourcesStore,
          riderProfileRepository: riderProfileStore,
          horseProfileRepository: horseProfileStore,
          authenticationRepository: authGateway,
        );
        cubit.emit(cubit.state.copyWith(isGuest: false, usersProfile: trainer));
        cubit.getConversations();
        conversationsController.add(const []);

        await primary.sendRequest(
          ConnectionRequest(
            id: 'badge_conv',
            messageId: 'm-badge-1',
            kind: ConnectionRequestKind.instructor,
            senderEmail: owner.email,
            senderName: owner.name,
            recipientEmail: trainer.email,
            recipientName: trainer.name,
            title: 'Instructor Request',
            summary: 'Badge test',
            parties: [owner.name, trainer.name],
            partiesIds: [owner.email, trainer.email],
            createdAt: DateTime(2026),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AppCubit>.value(
              value: cubit,
              child: const Scaffold(body: RequestsBadgeButton()),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(find.text('1'), findsOneWidget);

        await cubit.close();
      },
    );

    test(
      'TransferHorseCubit preserves canonical connectionId doc ID and '
      'fallback behavior',
      () async {
        final primary =
            FirestoreConnectionRequestStore(firestore: fakeFirestore);
        final legacy =
            FirebaseConnectionRequestStore(messagesStore: messagesStore);
        final composite = CompositeConnectionRequestStore(
          primary: primary,
          legacy: legacy,
        );

        when(
          () => riderProfileStore.getRiderProfileByEmail(
            email: trainer.email,
          ),
        ).thenAnswer((_) async => trainer);

        final cubit = TransferHorseCubit(
          horseProfile: horse,
          userProfile: owner,
          riderProfileRepository: riderProfileStore,
          requestRepository: composite,
          submitCoachingAction: (payload) async {
            expect(payload['action'], 'sendTransfer');
            expect(payload['createRequest'], true);
            return {'id': 'sha256-transfer-id', 'requestCreated': false};
          },
        );

        await cubit.getTransferProfile(trainer.email);
        await cubit.sendTransferRequest();

        expect(cubit.state.status, TransferHorseStatus.success);
        final snap = await fakeFirestore.collection('Requests').get();
        expect(snap.docs, hasLength(1));
        expect(snap.docs.single.data()['connectionId'], 'sha256-transfer-id');
        expect(snap.docs.single.data()['messageId'], 'sha256-transfer-id');
        expect(
          FirestoreConnectionRequestStore.docIdFor(
            ConnectionRequest(
              id: 'sha256-transfer-id',
              messageId: 'sha256-transfer-id',
              kind: ConnectionRequestKind.transferHorse,
              senderEmail: owner.email,
              senderName: owner.name,
              recipientEmail: trainer.email,
              recipientName: trainer.name,
              title: 'Transfer Horse',
              summary: 'Transfer',
              parties: [owner.name, trainer.name],
              partiesIds: [owner.email, trainer.email],
              createdAt: DateTime(2026),
              connectionId: 'sha256-transfer-id',
            ),
          ),
          'sha256-transfer-id',
        );
        await cubit.close();
      },
    );
  });
}
