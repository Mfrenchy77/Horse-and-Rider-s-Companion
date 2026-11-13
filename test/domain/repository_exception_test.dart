import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Messages/cubit/new_group_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessagesRepository extends Mock implements MessagesRepository {}

class _MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class _MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class _MockKeysRepository extends Mock implements KeysRepository {}

class _FakeConversation extends Fake implements Conversation {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeConversation());
    registerFallbackValue(
      HorseProfile(id: 'h', name: 'H', currentOwnerId: 'e'),
    );
    registerFallbackValue(RiderProfile(id: 'r', name: 'R', email: 'e'));
  });

  group('RepositoryException translation', () {
    test('maps FirebaseException codes to backend-neutral failure kinds', () {
      expect(
        RepositoryException.fromFirebase(
          FirebaseException(
            plugin: 'firestore',
            code: 'permission-denied',
            message: 'Missing or insufficient permissions.',
          ),
        ),
        isA<RepositoryException>()
            .having(
              (e) => e.kind,
              'kind',
              RepositoryFailureKind.permissionDenied,
            )
            .having((e) => e.code, 'code', 'permission-denied')
            .having(
              (e) => e.message,
              'message',
              'Missing or insufficient permissions.',
            ),
      );
      expect(
        RepositoryException.fromFirebase(
          FirebaseException(plugin: 'firestore', code: 'unavailable'),
        ).kind,
        RepositoryFailureKind.unavailable,
      );
      expect(
        RepositoryException.fromFirebase(
          FirebaseException(plugin: 'firestore', code: 'not-found'),
        ).kind,
        RepositoryFailureKind.notFound,
      );
      expect(
        RepositoryException.fromFirebase(
          FirebaseException(plugin: 'firestore', code: 'unauthenticated'),
        ).kind,
        RepositoryFailureKind.unauthenticated,
      );
      expect(
        RepositoryException.fromFirebase(
          FirebaseException(plugin: 'firestore', code: 'invalid-argument'),
        ).kind,
        RepositoryFailureKind.invalidArgument,
      );
      expect(
        RepositoryException.fromFirebase(
          FirebaseException(plugin: 'firestore', code: 'unknown-code'),
        ).kind,
        RepositoryFailureKind.unexpected,
      );
    });

    test(
      'guardFirebase translates FirebaseException into RepositoryException',
      () async {
        await expectLater(
          () => guardFirebase<void>(
            () async => throw FirebaseException(
              plugin: 'firestore',
              code: 'unavailable',
              message: 'Service unavailable',
            ),
          ),
          throwsA(
            isA<RepositoryException>()
                .having(
                  (e) => e.kind,
                  'kind',
                  RepositoryFailureKind.unavailable,
                )
                .having((e) => e.message, 'message', 'Service unavailable'),
          ),
        );
      },
    );
  });

  group('Cubit RepositoryException handling', () {
    test('NewGroupDialogCubit handles RepositoryException', () async {
      final messagesRepo = _MockMessagesRepository();
      when(
        () => messagesRepo.createOrUpdateConversation(
          conversation: any(named: 'conversation'),
        ),
      ).thenThrow(
        const RepositoryException(
          kind: RepositoryFailureKind.permissionDenied,
          message: 'Permission denied',
          code: 'permission-denied',
        ),
      );
      final cubit = NewGroupDialogCubit(
        messagesRepository: messagesRepo,
        riderProfileRepository: _MockRiderProfileRepository(),
        usersProfile: RiderProfile(
          id: 'u1',
          name: 'Alex',
          email: 'alex@example.com',
        ),
      );
      addTearDown(cubit.close);

      await cubit.createConversation(
        RiderProfile(id: 'u2', name: 'Sam', email: 'sam@example.com'),
      );

      expect(cubit.state.status, FormStatus.failure);
      expect(cubit.state.isError, isTrue);
      expect(cubit.state.error, contains('Permission denied'));
    });

    test('AddHorseDialogCubit handles RepositoryException on delete', () async {
      final horseRepo = _MockHorseProfileRepository();
      final riderRepo = _MockRiderProfileRepository();
      final keysRepo = _MockKeysRepository();
      when(keysRepo.getZipCodeApiKey).thenAnswer((_) async => '');
      when(keysRepo.getLocationApiKey).thenAnswer((_) async => '');
      when(
        () => horseRepo.deleteHorseProfile(id: any(named: 'id')),
      ).thenThrow(
        const RepositoryException(
          kind: RepositoryFailureKind.notFound,
          message: 'Horse not found',
          code: 'not-found',
        ),
      );
      final cubit = AddHorseDialogCubit(
        usersProfile: RiderProfile(
          id: 'u1',
          name: 'Alex',
          email: 'alex@example.com',
        ),
        horseProfile: HorseProfile(
          id: 'h1',
          name: 'Star',
          currentOwnerId: 'alex@example.com',
        ),
        keysRepository: keysRepo,
        horseProfileRepository: horseRepo,
        riderProfileRepository: riderRepo,
      );
      addTearDown(cubit.close);

      await cubit.deleteHorseProfile(
        horseProfile: HorseProfile(
          id: 'h1',
          name: 'Star',
          currentOwnerId: 'alex@example.com',
        ),
      );

      expect(cubit.state.status, FormStatus.failure);
      expect(cubit.state.error, 'Horse not found');
    });
  });
}
