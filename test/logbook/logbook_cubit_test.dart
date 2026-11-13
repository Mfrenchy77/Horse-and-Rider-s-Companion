import 'package:bloc_test/bloc_test.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Logbook/cubit/logbook_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockConnectionRepository extends Mock implements ConnectionRepository {}

class _MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue(BaseListItem());
  });

  group('LogbookCubit', () {
    late ConnectionRepository connectionRepository;
    late RiderProfileRepository riderProfileRepository;

    setUp(() {
      connectionRepository = _MockConnectionRepository();
      riderProfileRepository = _MockRiderProfileRepository();
    });

    blocTest<LogbookCubit, LogbookState>(
      'deleteEntry submits deleteJournal and emits feedback',
      build: () {
        when(
          () => connectionRepository.submit(any()),
        ).thenAnswer((_) async => {});
        return LogbookCubit(
          connectionRepository: connectionRepository,
          riderProfileRepository: riderProfileRepository,
        );
      },
      act: (cubit) => cubit.deleteEntry(
        BaseListItem(
          id: 'e1',
          riderLog: const RiderLogDetails(
            type: RiderLogType.lesson,
            shared: true,
          ),
        ),
      ),
      expect: () => [
        const LogbookState(actionInProgress: true),
        const LogbookState(feedback: 'Entry deleted.'),
      ],
      verify: (_) {
        verify(
          () => connectionRepository.submit({
            'action': 'deleteJournal',
            'id': 'e1',
            'shared': true,
          }),
        ).called(1);
      },
    );

    test('fetchStudentHorseOptions returns normalized map', () async {
      when(() => connectionRepository.submit(any())).thenAnswer(
        (_) async => {
          'horses': [
            {'id': 'h1', 'name': 'Comet'},
            {'id': 'h2', 'name': 'Mango'},
          ],
        },
      );
      final cubit = LogbookCubit(
        connectionRepository: connectionRepository,
        riderProfileRepository: riderProfileRepository,
      );
      final student = CoachingConnection('c1', {
        'version': 'v1',
        'kind': 'rider',
        'status': 'accepted',
        'sender': 'a',
        'recipient': 'b',
        'learner': 'a',
        'coach': 'b',
        'learnerName': 'A',
        'coachName': 'B',
      });
      final result = await cubit.fetchStudentHorseOptions(student);
      expect(result, {'horse:h1': 'Comet', 'horse:h2': 'Mango'});
    });

    test('saveLocalEntry delegates to RiderProfileRepository', () async {
      when(
        () => riderProfileRepository.saveRiderLogEntry(
          email: any(named: 'email'),
          isEdit: any(named: 'isEdit'),
          entry: any(named: 'entry'),
        ),
      ).thenAnswer((_) async {});

      final cubit = LogbookCubit(
        connectionRepository: connectionRepository,
        riderProfileRepository: riderProfileRepository,
      );
      final rider = RiderProfile(
        id: 'id',
        email: 'r@example.com',
        name: 'Rider',
      );
      final entry = BaseListItem(id: 'e2', name: 'notes');
      final msg = await cubit.saveLocalEntry(
        rider: rider,
        isEdit: false,
        entry: entry,
      );
      expect(msg, 'Saved.');

      verify(
        () => riderProfileRepository.saveRiderLogEntry(
          email: 'r@example.com',
          isEdit: false,
          entry: entry,
        ),
      ).called(1);
    });

    test('throws ConnectionFailure when connection repo is missing', () async {
      final cubit = LogbookCubit(
        connectionRepository: null,
        riderProfileRepository: riderProfileRepository,
      );
      expect(
        () => cubit.deleteEntry(BaseListItem(id: 'e3')),
        throwsA(isA<ConnectionFailure>()),
      );
    });
  });
}
