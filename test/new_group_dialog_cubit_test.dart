// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Messages/cubit/new_group_dialog_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:mocktail/mocktail.dart';

class MockMessagesRepository extends Mock implements MessagesRepository {}

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

// Firestore snapshot types are no longer used by repositories.

class ConversationFake extends Fake implements Conversation {}

void main() {
  setUpAll(() {
    registerFallbackValue(ConversationFake());
  });
  group('NewGroupDialogCubit', () {
    late MockMessagesRepository messagesRepo;
    late MockRiderProfileRepository riderRepo;
    late NewGroupDialogCubit cubit;
    late RiderProfile me;

    setUp(() {
      messagesRepo = MockMessagesRepository();
      riderRepo = MockRiderProfileRepository();
      me = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com');
      cubit = NewGroupDialogCubit(
        messagesRepository: messagesRepo,
        riderProfileRepository: riderRepo,
        usersProfile: me,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('initializes with usersProfile', () {
      expect(cubit.state.usersProfile?.email, 'me@example.com');
    });

    test('nameChanged and emailChanged update state', () {
      cubit
        ..nameChanged('Ana')
        ..emailChanged('a@b.com');
      expect(cubit.state.name.value, 'Ana');
      expect(cubit.state.email.value, 'a@b.com');
    });

    test('toggleSearchState toggles between name and email', () {
      expect(cubit.state.searchState, SearchState.name);
      cubit.toggleSearchState();
      expect(cubit.state.searchState, SearchState.email);
      cubit.toggleSearchState();
      expect(cubit.state.searchState, SearchState.name);
    });

    test('searchProfilesByName emits results excluding current user', () async {
      final other = RiderProfile(id: 'o', name: 'Other', email: 'o@x.com');

      final controller = StreamController<List<RiderProfile>>();
      when(() => riderRepo.getProfilesByName(name: any(named: 'name')))
          .thenAnswer((_) => controller.stream);

      cubit
        ..nameChanged('O')
        ..searchProfilesByName();
      controller.add([other, me]);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.searchResult.length, 1);
      expect((cubit.state.searchResult.first!).email, 'o@x.com');

      await controller.close();
    });

    test('getProfileByEmail emits result excluding current user', () async {
      final other = RiderProfile(id: 'o', name: 'Other', email: 'o@x.com');

      final controller = StreamController<RiderProfile?>();
      when(() => riderRepo.getRiderProfile(email: any(named: 'email')))
          .thenAnswer((_) => controller.stream);

      cubit
        ..emailChanged('O@X.COM')
        ..getProfileByEmail();
      controller.add(other);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cubit.state.searchResult.length, 1);
      expect((cubit.state.searchResult.first!).email, 'o@x.com');

      await controller.close();
    });

    blocTest<NewGroupDialogCubit, NewGroupDialogState>(
      'createConversation success emits submitting then success with id',
      build: () {
        when(
          () => messagesRepo.createOrUpdateConversation(
            conversation: any(named: 'conversation'),
          ),
        ).thenAnswer((_) async {});
        return cubit;
      },
      act: (c) async {
        final target = RiderProfile(id: 't', name: 'Target', email: 't@x.com');
        await c.createConversation(target);
      },
      verify: (c) {
        final captured = verify(
          () => messagesRepo.createOrUpdateConversation(
            conversation: captureAny(named: 'conversation'),
          ),
        ).captured.first as Conversation;
        expect(captured.partiesIds, containsAll(['me@example.com', 't@x.com']));
        expect(c.state.id, captured.id);
      },
      expect: () => [
        isA<NewGroupDialogState>().having(
          (s) => s.status,
          'submitting',
          FormStatus.submitting,
        ),
        isA<NewGroupDialogState>().having(
          (s) => s.status,
          'success',
          FormStatus.success,
        ),
      ],
    );

    blocTest<NewGroupDialogCubit, NewGroupDialogState>(
      'createConversation handles FirebaseException',
      build: () {
        when(
          () => messagesRepo.createOrUpdateConversation(
            conversation: any(named: 'conversation'),
          ),
        ).thenThrow(FirebaseException(plugin: 'firestore'));
        return cubit;
      },
      act: (c) async {
        final target = RiderProfile(id: 't', name: 'Target', email: 't@x.com');
        await c.createConversation(target);
      },
      expect: () => [
        isA<NewGroupDialogState>().having(
          (s) => s.status,
          'submitting',
          FormStatus.submitting,
        ),
        isA<NewGroupDialogState>()
            .having((s) => s.status, 'failure', FormStatus.failure)
            .having((s) => s.isError, 'isError', true)
            .having((s) => s.error, 'err', contains('Problem Creating')),
      ],
    );
  });
}
