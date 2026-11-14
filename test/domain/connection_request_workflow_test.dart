// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/TransferHorseDialog/cubit/transfer_horse_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/deny_request_button.dart';

import '../support/app_test_harness.dart';

void main() {
  group('InMemoryConnectionRequestStore', () {
    test(
      'streams pending requests, deduplicates, and updates on dismiss/accept',
      () async {
        final store = InMemoryConnectionRequestStore();
        addTearDown(store.dispose);

        final req = ConnectionRequest(
          id: 'pair_1',
          messageId: 'm1',
          kind: ConnectionRequestKind.instructor,
          senderEmail: 'student@example.com',
          senderName: 'Alex Student',
          recipientEmail: 'coach@example.com',
          recipientName: 'Coach Pat',
          title: 'Instructor Request',
          summary: 'Alex Student wants Coach Pat as instructor',
          partiesIds: const ['student@example.com', 'coach@example.com'],
          createdAt: DateTime(2026, 11, 13, 10),
        );

        final emissions = <List<ConnectionRequest>>[];
        final sub = store
            .watchRequests(userEmail: 'coach@example.com')
            .listen(emissions.add);
        addTearDown(sub.cancel);

        await Future<void>.delayed(Duration.zero);
        expect(emissions.last, isEmpty);

        await store.sendRequest(req);
        await store.sendRequest(req); // idempotent duplicate
        await Future<void>.delayed(Duration.zero);
        expect(emissions.last, hasLength(1));
        expect(emissions.last.single.status, 'pending');

        await store.dismissRequest(
          request: req,
          dismissalNote: 'Declined',
          status: 'declined',
        );
        await Future<void>.delayed(Duration.zero);
        expect(emissions.last, isEmpty);
        expect(store.allRequests.single.status, 'declined');

        final req2 = ConnectionRequest(
          id: 'pair_2',
          messageId: 'm2',
          kind: ConnectionRequestKind.transferHorse,
          senderEmail: 'owner@example.com',
          senderName: 'Owner',
          recipientEmail: 'coach@example.com',
          recipientName: 'Coach Pat',
          title: 'Transfer Horse',
          summary: 'Transfer Starlight',
          partiesIds: const ['owner@example.com', 'coach@example.com'],
          createdAt: DateTime(2026, 11, 13, 11),
          horseId: 'horse-1',
          horseName: 'Starlight',
          connectionId: 'conn-1',
        );
        await store.sendRequest(req2);
        await Future<void>.delayed(Duration.zero);
        expect(emissions.last, hasLength(1));

        await store.markAccepted(req2);
        await Future<void>.delayed(Duration.zero);
        expect(emissions.last, isEmpty);
        expect(store.allRequests.where((r) => r.isAccepted), hasLength(1));
      },
    );
  });

  group('AppCubit request authorization, counts, and duplicate guards', () {
    test(
      'createInstructorRequest blocks self, non-trainer, and duplicates',
      () async {
        final store = InMemoryConnectionRequestStore();
        addTearDown(store.dispose);
        final harness = await AppTestHarness.create(requestStore: store);
        addTearDown(harness.close);

        final rider = RiderProfile(
          id: 'rider@example.com',
          email: 'rider@example.com',
          name: 'Rider One',
        );
        final nonTrainer = RiderProfile(
          id: 'peer@example.com',
          email: 'peer@example.com',
          name: 'Peer Rider',
        );
        final trainer = RiderProfile(
          id: 'coach@example.com',
          email: 'coach@example.com',
          name: 'Coach Pat',
          isTrainer: true,
        );

        harness.cubit.emit(
          harness.cubit.state.copyWith(isGuest: false, usersProfile: rider),
        );
        harness.cubit.getConversations();
        await Future<void>.delayed(Duration.zero);

        await harness.cubit.createInstructorRequest(instructorProfile: rider);
        await harness.cubit.createInstructorRequest(
          instructorProfile: nonTrainer,
        );
        expect(store.allRequests, isEmpty);

        await harness.cubit.createInstructorRequest(instructorProfile: trainer);
        await Future<void>.delayed(Duration.zero);
        expect(store.allRequests, hasLength(1));

        await harness.cubit.createInstructorRequest(instructorProfile: trainer);
        expect(store.allRequests, hasLength(1));
        expect(harness.cubit.state.errorMessage, contains('already sent'));
      },
    );

    test(
      'createStudentRequest and studentHorse require trainer and block duplicates',
      () async {
        final store = InMemoryConnectionRequestStore();
        addTearDown(store.dispose);
        final harness = await AppTestHarness.create(requestStore: store);
        addTearDown(harness.close);

        final nonTrainer = RiderProfile(
          id: 'user@example.com',
          email: 'user@example.com',
          name: 'Regular Rider',
        );
        final trainer = RiderProfile(
          id: 'coach@example.com',
          email: 'coach@example.com',
          name: 'Coach Pat',
          isTrainer: true,
        );
        final student = RiderProfile(
          id: 'student@example.com',
          email: 'student@example.com',
          name: 'Alex Student',
        );
        final horse = HorseProfile(
          id: 'horse-1',
          name: 'Starlight',
          currentOwnerId: 'student@example.com',
          currentOwnerName: 'Alex Student',
        );

        harness.cubit.emit(
          harness.cubit.state.copyWith(
            isGuest: false,
            usersProfile: nonTrainer,
            ownersProfile: student,
            horseProfile: horse,
          ),
        );
        await harness.cubit.createStudentRequest(studentProfile: student);
        await Future<void>.delayed(const Duration(milliseconds: 2));
        harness.cubit.requestToBeStudentHorse();
        expect(store.allRequests, isEmpty);

        harness.cubit.emit(
          harness.cubit.state.copyWith(
            usersProfile: trainer,
            connectionRequests: const [],
          ),
        );
        await harness.cubit.createStudentRequest(studentProfile: student);
        await Future<void>.delayed(const Duration(milliseconds: 2));
        harness.cubit.requestToBeStudentHorse();
        await Future<void>.delayed(Duration.zero);
        expect(store.allRequests, hasLength(2));

        harness.cubit.emit(
          harness.cubit.state.copyWith(connectionRequests: store.allRequests),
        );
        await harness.cubit.createStudentRequest(studentProfile: student);
        await Future<void>.delayed(const Duration(milliseconds: 2));
        harness.cubit.requestToBeStudentHorse();
        expect(store.allRequests, hasLength(2));
      },
    );

    test(
      'pendingRequestCount filters by senderEmail and pending status even with matching names',
      () async {
        final store = InMemoryConnectionRequestStore();
        addTearDown(store.dispose);
        final harness = await AppTestHarness.create(requestStore: store);
        addTearDown(harness.close);

        final me = RiderProfile(
          id: 'me@example.com',
          email: 'me@example.com',
          name: 'Alex',
        );
        final sameNameIncoming = ConnectionRequest(
          id: 'c1',
          messageId: 'm1',
          kind: ConnectionRequestKind.instructor,
          senderEmail: 'other-alex@example.com',
          senderName: 'Alex',
          recipientEmail: 'me@example.com',
          recipientName: 'Alex',
          title: 'Instructor Request',
          summary: 'Same display name, different email',
          partiesIds: const ['other-alex@example.com', 'me@example.com'],
          createdAt: DateTime(2026, 11, 13, 12),
        );
        final myOutgoing = ConnectionRequest(
          id: 'c2',
          messageId: 'm2',
          kind: ConnectionRequestKind.student,
          senderEmail: 'me@example.com',
          senderName: 'Alex',
          recipientEmail: 'other@example.com',
          recipientName: 'Other',
          title: 'Student Request',
          summary: 'Outgoing',
          partiesIds: const ['me@example.com', 'other@example.com'],
          createdAt: DateTime(2026, 11, 13, 12),
        );
        final declinedIncoming = ConnectionRequest(
          id: 'c3',
          messageId: 'm3',
          kind: ConnectionRequestKind.instructor,
          senderEmail: 'third@example.com',
          senderName: 'Third',
          recipientEmail: 'me@example.com',
          recipientName: 'Alex',
          title: 'Instructor Request',
          summary: 'Already declined',
          partiesIds: const ['third@example.com', 'me@example.com'],
          createdAt: DateTime(2026, 11, 13, 12),
          status: 'declined',
        );

        harness.cubit.emit(
          harness.cubit.state.copyWith(
            isGuest: false,
            usersProfile: me,
            connectionRequests: [
              sameNameIncoming,
              myOutgoing,
              declinedIncoming,
            ],
          ),
        );

        expect(harness.cubit.pendingRequestCount(), 1);
        expect(
          harness.cubit.pendingConnectionRequests().single.senderEmail,
          'other-alex@example.com',
        );
      },
    );

    test(
      'acceptConnectionRequest and denyConnectionRequest ignore non-pending requests',
      () async {
        var submitCalls = 0;
        final store = InMemoryConnectionRequestStore();
        addTearDown(store.dispose);
        final harness = await AppTestHarness.create(
          requestStore: store,
          submitCoachingAction: (_) async {
            submitCalls++;
            return {'status': 'pending'};
          },
        );
        addTearDown(harness.close);

        final coach = RiderProfile(
          id: 'coach@example.com',
          email: 'coach@example.com',
          name: 'Coach',
          isTrainer: true,
        );
        harness.cubit.emit(
          harness.cubit.state.copyWith(isGuest: false, usersProfile: coach),
        );

        final alreadyAccepted = ConnectionRequest(
          id: 'c1',
          messageId: 'm1',
          kind: ConnectionRequestKind.instructor,
          senderEmail: 'student@example.com',
          senderName: 'Student',
          recipientEmail: 'coach@example.com',
          recipientName: 'Coach',
          title: 'Instructor Request',
          summary: 'Accepted',
          createdAt: DateTime(2026, 11, 13, 12),
          isAccepted: true,
          status: 'accepted',
        );

        await harness.cubit.acceptConnectionRequest(alreadyAccepted);
        await harness.cubit.denyConnectionRequest(alreadyAccepted);
        expect(submitCalls, 0);
      },
    );

    test(
      'TransferHorseCubit sends transferHorse request via ConnectionRequestStore',
      () async {
        final store = InMemoryConnectionRequestStore();
        addTearDown(store.dispose);
        final harness = await AppTestHarness.create(requestStore: store);
        addTearDown(harness.close);

        final owner = RiderProfile(
          id: 'owner@example.com',
          email: 'owner@example.com',
          name: 'Owner',
        );
        final recipient = RiderProfile(
          id: 'buyer@example.com',
          email: 'buyer@example.com',
          name: 'Buyer',
        );
        final horse = HorseProfile(
          id: 'horse-1',
          name: 'Valero',
          currentOwnerId: 'owner@example.com',
          currentOwnerName: 'Owner',
        );

        final transferCubit = TransferHorseCubit(
          userProfile: owner,
          horseProfile: horse,
          requestRepository: store,
          riderProfileRepository: harness.riders,
        );
        addTearDown(transferCubit.close);

        transferCubit.emit(
          transferCubit.state.copyWith(
            transferProfile: recipient,
            isTransferable: true,
          ),
        );
        await transferCubit.sendTransferRequest();

        expect(store.allRequests, hasLength(1));
        expect(
          store.allRequests.single.kind,
          ConnectionRequestKind.transferHorse,
        );
        expect(store.allRequests.single.horseId, 'horse-1');
      },
    );
  });

  testWidgets('DenyRequestButton disables while acceptStatus is loading', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    harness.cubit.emit(
      harness.cubit.state.copyWith(acceptStatus: AcceptStatus.loading),
    );

    final req = ConnectionRequest(
      id: 'c1',
      messageId: 'm1',
      kind: ConnectionRequestKind.instructor,
      senderEmail: 'student@example.com',
      senderName: 'Student',
      recipientEmail: 'coach@example.com',
      recipientName: 'Coach',
      title: 'Instructor Request',
      summary: 'Pending',
      createdAt: DateTime(2026, 11, 13, 12),
    );

    await tester.pumpWidget(
      BlocProvider<AppCubit>.value(
        value: harness.cubit,
        child: MaterialApp(
          home: Scaffold(body: DenyRequestButton(request: req)),
        ),
      ),
    );

    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('DenyRequestButton')),
    );
    expect(button.onPressed, isNull);
  });
}
