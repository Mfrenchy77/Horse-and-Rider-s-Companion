import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/TransferHorseDialog/cubit/transfer_horse_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

class FakeConversation extends Fake implements Conversation {}

class FakeMessage extends Fake implements Message {}

void main() {
  late MockRiderProfileRepository riders;
  late MockMessagesRepository messages;
  late TransferHorseCubit cubit;
  final owner = RiderProfile(
    id: 'owner',
    name: 'Owner',
    email: 'owner@example.com',
  );
  final recipient = RiderProfile(
    id: 'new',
    name: 'Recipient',
    email: 'new@example.com',
  );

  setUpAll(() {
    registerFallbackValue(FakeConversation());
    registerFallbackValue(FakeMessage());
  });
  setUp(() {
    riders = MockRiderProfileRepository();
    messages = MockMessagesRepository();
    when(
      () => riders.getRiderProfileByEmail(email: any(named: 'email')),
    ).thenAnswer((_) async => recipient);
    when(
      () => messages.createOrUpdateConversation(
        conversation: any(named: 'conversation'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => messages.createOrUpdateMessage(message: any(named: 'message')),
    ).thenAnswer((_) async {});
    cubit = TransferHorseCubit(
      userProfile: owner,
      horseProfile: HorseProfile(
        id: 'horse',
        name: 'Star',
        currentOwnerId: owner.email,
        currentOwnerName: owner.name,
      ),
      messagesRepository: messages,
      riderProfileRepository: riders,
    );
  });
  tearDown(() => cubit.close());

  test(
    'sending without a selected recipient fails without a write or crash',
    () async {
      await cubit.sendTransferRequest();
      expect(cubit.state.status, TransferHorseStatus.error);
      verifyZeroInteractions(messages);
    },
  );
  test(
    'successful request stores matching message and conversation metadata',
    () async {
      when(
        () => messages.createOrUpdateConversation(
          conversation: any(named: 'conversation'),
        ),
      ).thenAnswer(
        (_) async => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await cubit.getTransferProfile(recipient.email);
      await cubit.sendTransferRequest();
      final conversation =
          verify(
                () => messages.createOrUpdateConversation(
                  conversation: captureAny(named: 'conversation'),
                ),
              ).captured.single
              as Conversation;
      final message =
          verify(
                () => messages.createOrUpdateMessage(
                  message: captureAny(named: 'message'),
                ),
              ).captured.single
              as Message;
      expect(message.id, conversation.id);
      expect(message.messageId, conversation.recentMessage?.messageId);
      expect(message.messageType, MessageType.TRANSFER_HORSE_REQUEST);
      expect(message.requestItem?.id, 'horse');
      expect(conversation.partiesIds, [owner.email, recipient.email]);
      expect(cubit.state.status, TransferHorseStatus.success);
    },
  );
  test('self-transfer is rejected case-insensitively', () async {
    when(
      () => riders.getRiderProfileByEmail(email: any(named: 'email')),
    ).thenAnswer((_) async => owner.copyWith(email: 'OWNER@example.com'));
    await cubit.getTransferProfile(owner.email);
    await cubit.sendTransferRequest();
    expect(cubit.state.status, TransferHorseStatus.error);
    verifyZeroInteractions(messages);
  });
  test('a missing search result clears the previous recipient', () async {
    await cubit.getTransferProfile(recipient.email);
    when(
      () => riders.getRiderProfileByEmail(email: 'missing@example.com'),
    ).thenAnswer((_) async => null);
    await cubit.getTransferProfile('missing@example.com');
    expect(cubit.state.transferProfile, isNull);
    expect(cubit.state.isTransferable, isFalse);
  });
  test('editing email immediately invalidates the old recipient', () async {
    await cubit.getTransferProfile(recipient.email);
    cubit.emailChanged('not an email');
    expect(cubit.state.transferProfile, isNull);
    expect(cubit.state.isTransferable, isFalse);
    await cubit.sendTransferRequest();
    verifyZeroInteractions(messages);
  });
  test('older lookup results cannot replace a newer recipient', () async {
    final old = Completer<RiderProfile?>();
    final newer = Completer<RiderProfile?>();
    when(
      () => riders.getRiderProfileByEmail(email: 'old@example.com'),
    ).thenAnswer((_) => old.future);
    when(
      () => riders.getRiderProfileByEmail(email: recipient.email),
    ).thenAnswer((_) => newer.future);
    final first = cubit.getTransferProfile('old@example.com');
    final second = cubit.getTransferProfile(recipient.email);
    newer.complete(recipient);
    await second;
    old.complete(owner);
    await first;
    expect(cubit.state.transferProfile?.email, recipient.email);
  });
  test('closing cancels a pending debounced lookup', () async {
    cubit.emailChanged(recipient.email);
    await cubit.close();
    await Future<void>.delayed(const Duration(milliseconds: 550));
    verifyZeroInteractions(riders);
  });
  test('conversation failures do not send a message', () async {
    await cubit.getTransferProfile(recipient.email);
    when(
      () => messages.createOrUpdateConversation(
        conversation: any(named: 'conversation'),
      ),
    ).thenAnswer((_) async => throw Exception('offline'));
    await cubit.sendTransferRequest();
    expect(cubit.state.status, TransferHorseStatus.error);
    verifyNever(
      () => messages.createOrUpdateMessage(message: any(named: 'message')),
    );
  });
}
