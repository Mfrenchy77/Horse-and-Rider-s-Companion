import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/TransferHorseDialog/cubit/transfer_horse_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/requests_badge_button.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockMessagesStore extends Mock implements MessagesStore {}

class _MockSkillTreeStore extends Mock implements SkillTreeStore {}

class _MockResourcesStore extends Mock implements ResourcesStore {}

class _MockRiderProfileStore extends Mock implements RiderProfileStore {}

class _MockHorseProfileStore extends Mock implements HorseProfileStore {}

class _MockAuthGateway extends Mock implements AuthGateway {}

class _InMemoryConnectionRequestStore implements ConnectionRequestStore {
  final Map<String, ConnectionRequest> _requests = {};
  final StreamController<List<ConnectionRequest>> _controller =
      StreamController<List<ConnectionRequest>>.broadcast();

  void seed(ConnectionRequest request) {
    _requests[request.id] = request;
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_requests.values.toList());
    }
  }

  @override
  Stream<List<ConnectionRequest>> watchRequests({
    required String userEmail,
  }) {
    final normalized = userEmail.toLowerCase();
    List<ConnectionRequest> filter(Iterable<ConnectionRequest> items) =>
        items.where((r) => r.partiesIds.contains(normalized)).toList();

    return Stream.multi((multi) {
      multi.add(filter(_requests.values));
      final sub = _controller.stream.listen(
        (list) => multi.add(filter(list)),
        onError: multi.addError,
        onDone: multi.close,
      );
      multi.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> sendRequest(ConnectionRequest request) async {
    _requests[request.id] = request;
    _emit();
  }

  @override
  Future<void> dismissRequest({
    required ConnectionRequest request,
    required String dismissalNote,
    String status = 'dismissed',
  }) async {
    _requests.remove(request.id);
    _emit();
  }

  Future<void> dispose() => _controller.close();
}

void main() {
  setUpAll(() {
    final fallbackMessage = Message(
      id: 'fallback',
      messageId: 'fallback',
      sender: '',
      senderId: '',
      senderProfilePicUrl: '',
      message: '',
      subject: '',
      recipients: const [],
      date: DateTime(2024),
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
        recentMessage: fallbackMessage,
      ),
    );
    registerFallbackValue(fallbackMessage);
  });

  group('ConnectionRequestStore', () {
    late _MockMessagesStore messagesStore;
    late _MockSkillTreeStore skillTreeStore;
    late _MockResourcesStore resourcesStore;
    late _MockRiderProfileStore riderProfileStore;
    late _MockHorseProfileStore horseProfileStore;
    late _MockAuthGateway authGateway;
    late _InMemoryConnectionRequestStore requestStore;

    final owner = RiderProfile(
      id: 'owner@example.com',
      email: 'owner@example.com',
      name: 'Owner Rider',
      isTrainer: true,
      picUrl: '',
    );
    final recipient = RiderProfile(
      id: 'recipient@example.com',
      email: 'recipient@example.com',
      name: 'Recipient Rider',
      picUrl: '',
    );
    final horse = HorseProfile(
      id: 'horse-1',
      name: 'Comet',
      currentOwnerId: owner.email,
      currentOwnerName: owner.name,
      picUrl: '',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      messagesStore = _MockMessagesStore();
      skillTreeStore = _MockSkillTreeStore();
      resourcesStore = _MockResourcesStore();
      riderProfileStore = _MockRiderProfileStore();
      horseProfileStore = _MockHorseProfileStore();
      authGateway = _MockAuthGateway();
      requestStore = _InMemoryConnectionRequestStore();

      when(() => authGateway.currentUser).thenReturn(User.empty);
      when(
        () => authGateway.user,
      ).thenAnswer((_) => const Stream<User?>.empty());
      when(
        () => skillTreeStore.getSkills(),
      ).thenAnswer((_) => const Stream<List<Skill>>.empty());
      when(
        () => resourcesStore.getResources(),
      ).thenAnswer((_) => const Stream<List<Resource>>.empty());
      when(
        () => riderProfileStore.getRiderProfile(email: any(named: 'email')),
      ).thenAnswer((_) => Stream<RiderProfile?>.value(recipient));
    });

    tearDown(() async {
      await requestStore.dispose();
    });

    test(
      'TransferHorseCubit sends ConnectionRequest without MessagesStore',
      () async {
        when(
          () => riderProfileStore.getRiderProfileByEmail(
            email: recipient.email,
          ),
        ).thenAnswer((_) async => recipient);

        final cubit = TransferHorseCubit(
          horseProfile: horse,
          userProfile: owner,
          riderProfileRepository: riderProfileStore,
          requestRepository: requestStore,
        );

        await cubit.getTransferProfile(recipient.email);
        await cubit.sendTransferRequest();

        expect(cubit.state.status, TransferHorseStatus.success);
        verifyZeroInteractions(messagesStore);

        final requests = await requestStore
            .watchRequests(userEmail: recipient.email)
            .first;
        expect(requests, hasLength(1));
        expect(requests.single.kind, ConnectionRequestKind.transferHorse);
        expect(requests.single.horseId, horse.id);
        expect(requests.single.senderEmail, owner.email);
        expect(requests.single.recipientEmail, recipient.email);
        await cubit.close();
      },
    );

    test(
      'AppCubit creates, watches, accepts, and denies requests',
      () async {
        final submittedPayloads = <Map<String, Object?>>[];
        final cubit = AppCubit(
          messagesRepository: messagesStore,
          connectionRequestRepository: requestStore,
          skillTreeRepository: skillTreeStore,
          resourcesRepository: resourcesStore,
          riderProfileRepository: riderProfileStore,
          horseProfileRepository: horseProfileStore,
          authenticationRepository: authGateway,
          submitCoachingAction: (payload) async {
            submittedPayloads.add(payload);
            return {'status': 'pending'};
          },
        );

        cubit.emit(
          cubit.state.copyWith(
            isGuest: false,
            usersProfile: recipient,
          ),
        );
        cubit.getConversations();
        await pumpEventQueue();

        final incoming = ConnectionRequest(
          id: 'owner_recipient',
          messageId: 'm1',
          kind: ConnectionRequestKind.instructor,
          senderEmail: owner.email,
          senderName: owner.name,
          recipientEmail: recipient.email,
          recipientName: recipient.name,
          title: 'Instructor Request',
          summary:
              'Owner Rider has requested Recipient Rider to be their '
              'Instructor',
          parties: [owner.name, recipient.name],
          partiesIds: [owner.email, recipient.email],
          createdAt: DateTime(2026),
        );
        requestStore.seed(incoming);
        await pumpEventQueue();

        expect(cubit.pendingRequestCount(), 1);
        expect(cubit.pendingConnectionRequests(), [incoming]);

        await cubit.acceptConnectionRequest(incoming);
        expect(submittedPayloads, [
          {
            'action': 'send',
            'kind': 'rider',
            'learnerEmail': owner.email,
            'coachEmail': recipient.email,
            'requestDocId': 'owner_recipient',
          },
        ]);
        expect(cubit.state.acceptStatus, AcceptStatus.submitted);

        await cubit.denyConnectionRequest(incoming);
        await pumpEventQueue();
        expect(cubit.pendingRequestCount(), 0);
        expect(cubit.state.errorMessage, 'Request denied');

        await cubit.createStudentRequest(studentProfile: owner);
        await pumpEventQueue();
        final afterSend = await requestStore
            .watchRequests(userEmail: recipient.email)
            .first;
        expect(afterSend, hasLength(1));
        expect(afterSend.single.kind, ConnectionRequestKind.student);
        verifyZeroInteractions(messagesStore);

        await cubit.close();
      },
    );

    test(
      'FirebaseConnectionRequestStore delegates send, watch, and dismiss',
      () async {
        final req = ConnectionRequest(
          id: 'conv-1',
          messageId: 'msg-1',
          kind: ConnectionRequestKind.studentHorse,
          senderEmail: owner.email,
          senderName: owner.name,
          recipientEmail: recipient.email,
          recipientName: recipient.name,
          title: 'Student Horse Request',
          summary:
              'Owner Rider has requested to add Comet as a student horse.',
          parties: [owner.name, recipient.name],
          partiesIds: [owner.email, recipient.email],
          createdAt: DateTime(2026, 2),
          horseId: horse.id,
          horseName: horse.name,
          horseOwnerId: recipient.email,
          horseOwnerName: recipient.name,
        );

        when(
          () => messagesStore.createOrUpdateConversation(
            conversation: any(named: 'conversation'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => messagesStore.createOrUpdateMessage(
            message: any(named: 'message'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => messagesStore.getConversations(userEmail: recipient.email),
        ).thenAnswer(
          (_) => Stream.value([
            Conversation(
              id: req.id,
              parties: req.parties,
              partiesIds: req.partiesIds,
              createdOn: req.createdAt,
              lastEditDate: req.createdAt,
              createdBy: req.senderName,
              lastEditBy: req.senderName,
              recentMessage: req.toLegacyMessage(),
            ),
          ]),
        );

        final adapter = FirebaseConnectionRequestStore(
          messagesStore: messagesStore,
        );
        await adapter.sendRequest(req);

        verify(
          () => messagesStore.createOrUpdateConversation(
            conversation: any(named: 'conversation'),
          ),
        ).called(1);
        verify(
          () => messagesStore.createOrUpdateMessage(
            message: any(named: 'message'),
          ),
        ).called(1);

        final watched =
            await adapter.watchRequests(userEmail: recipient.email).first;
        expect(watched, hasLength(1));
        expect(watched.single.kind, ConnectionRequestKind.studentHorse);
        expect(watched.single.horseId, horse.id);

        await adapter.dismissRequest(
          request: req,
          dismissalNote: 'Denied student horse request',
        );
        final dismissed =
            verify(
                  () => messagesStore.createOrUpdateMessage(
                    message: captureAny(named: 'message'),
                  ),
                ).captured.single
                as Message;
        expect(dismissed.messageType, MessageType.CHAT);
        expect(dismissed.message, 'Denied student horse request');
      },
    );

    testWidgets(
      'RequestsBadgeButton accepts ConnectionRequest without MessagesStore',
      (tester) async {
        final submittedPayloads = <Map<String, Object?>>[];
        final cubit = AppCubit(
          messagesRepository: messagesStore,
          connectionRequestRepository: requestStore,
          skillTreeRepository: skillTreeStore,
          resourcesRepository: resourcesStore,
          riderProfileRepository: riderProfileStore,
          horseProfileRepository: horseProfileStore,
          authenticationRepository: authGateway,
          submitCoachingAction: (payload) async {
            submittedPayloads.add(payload);
            return {'status': 'pending'};
          },
        );

        cubit.emit(
          cubit.state.copyWith(
            isGuest: false,
            usersProfile: recipient,
          ),
        );
        requestStore.seed(
          ConnectionRequest(
            id: 'owner_recipient',
            messageId: 'm-widget',
            kind: ConnectionRequestKind.instructor,
            senderEmail: owner.email,
            senderName: owner.name,
            recipientEmail: recipient.email,
            recipientName: recipient.name,
            title: 'Instructor Request',
            summary: 'Owner Rider wants you as Instructor',
            parties: [owner.name, recipient.name],
            partiesIds: [owner.email, recipient.email],
            createdAt: DateTime(2026, 3),
          ),
        );
        cubit.getConversations();

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<AppCubit>.value(
              value: cubit,
              child: const Scaffold(
                body: RequestsBadgeButton(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('RequestsBadgeButton')), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        final icon = tester.widget<IconButton>(
          find.byKey(const Key('RequestsIconButton')),
        );
        icon.onPressed?.call();
        await tester.pumpAndSettle();

        expect(
          find.text('Owner Rider wants you as Instructor'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('Accept_m-widget')));
        await tester.pumpAndSettle();

        expect(submittedPayloads, hasLength(1));
        expect(submittedPayloads.single['learnerEmail'], owner.email);
        expect(submittedPayloads.single['coachEmail'], recipient.email);
        verifyZeroInteractions(messagesStore);

        await tester.pumpWidget(const SizedBox());
        unawaited(cubit.close());
      },
    );

    test(
      'AppCubit accepts transferHorse via connectionHandler with version '
      'and requestDocId',
      () async {
        final requestStore = _InMemoryConnectionRequestStore();
        final submittedPayloads = <Map<String, Object?>>[];
        final cubit = AppCubit(
          messagesRepository: messagesStore,
          connectionRequestRepository: requestStore,
          skillTreeRepository: skillTreeStore,
          resourcesRepository: resourcesStore,
          riderProfileRepository: riderProfileStore,
          horseProfileRepository: horseProfileStore,
          authenticationRepository: authGateway,
          fetchConnection: (id) async => {
            'id': id,
            'version': 'v-42',
            'status': 'pending',
          },
          submitCoachingAction: (payload) async {
            submittedPayloads.add(payload);
            return {'id': payload['id'], 'status': 'accepted'};
          },
        );
        cubit.emit(
          cubit.state.copyWith(usersProfile: recipient, isGuest: false),
        );

        final transferReq = ConnectionRequest(
          id: 'owner_recipient_m-xfer',
          messageId: 'm-xfer',
          kind: ConnectionRequestKind.transferHorse,
          senderEmail: owner.email,
          senderName: owner.name,
          recipientEmail: recipient.email,
          recipientName: recipient.name,
          title: 'Transfer Horse',
          summary: 'Transfer Atlas',
          parties: [owner.name, recipient.name],
          partiesIds: [owner.email, recipient.email],
          createdAt: DateTime(2026, 4),
          horseId: 'atlas',
          horseName: 'Atlas',
          connectionId: 'transfer_atlas_u1_u2',
        );

        await cubit.acceptConnectionRequest(transferReq);
        expect(submittedPayloads, hasLength(1));
        expect(submittedPayloads.single, {
          'action': 'accept',
          'id': 'transfer_atlas_u1_u2',
          'version': 'v-42',
          'requestDocId': 'owner_recipient_m-xfer',
        });
        expect(cubit.state.acceptStatus, AcceptStatus.submitted);
        expect(cubit.state.isError, isFalse);

        unawaited(cubit.close());
      },
    );

    test(
      'TransferHorseCubit calls sendTransfer before creating Requests doc',
      () async {
        final requestStore = _InMemoryConnectionRequestStore();
        final submitted = <Map<String, Object?>>[];
        final horse = HorseProfile(
          id: 'atlas',
          name: 'Atlas',
          currentOwnerId: owner.email,
          currentOwnerName: owner.name,
          lastEditBy: owner.name,
          lastEditDate: DateTime(2026),
        );
        final transferCubit = TransferHorseCubit(
          userProfile: owner,
          horseProfile: horse,
          requestRepository: requestStore,
          riderProfileRepository: riderProfileStore,
          submitCoachingAction: (payload) async {
            submitted.add(payload);
            return {'id': 'transfer_atlas_u1_u2', 'status': 'pending'};
          },
        );
        transferCubit.emit(
          transferCubit.state.copyWith(
            transferProfile: recipient,
            isTransferable: true,
          ),
        );

        await transferCubit.sendTransferRequest();
        expect(submitted, hasLength(1));
        expect(submitted.single['action'], 'sendTransfer');
        expect(submitted.single['horseId'], 'atlas');
        final items = await requestStore
            .watchRequests(userEmail: recipient.email)
            .first;
        expect(items.single.connectionId, 'transfer_atlas_u1_u2');
        unawaited(transferCubit.close());
      },
    );
  });
}
