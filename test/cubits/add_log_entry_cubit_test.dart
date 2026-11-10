import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddLogEntryDialog/Cubit/add_log_entry_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:mocktail/mocktail.dart';

class MockHorseRepository extends Mock implements HorseProfileRepository {}

class MockRiderRepository extends Mock implements RiderProfileRepository {}

void main() {
  late MockHorseRepository horses;
  late MockRiderRepository riders;
  late RiderProfile rider;
  late AddLogEntryCubit cubit;
  setUpAll(() {
    registerFallbackValue(HorseProfile(id: 'fallback', name: 'Horse'));
    registerFallbackValue(
      RiderProfile(id: 'fallback', name: 'Rider', email: 'r@example.com'),
    );
  });
  setUp(() {
    horses = MockHorseRepository();
    riders = MockRiderRepository();
    rider = RiderProfile(id: 'r', name: 'Rider', email: 'r@example.com');
    cubit = AddLogEntryCubit(
      horseProfileRepository: horses,
      riderProfileRepository: riders,
      usersProfile: rider,
    )..logEntryChanged(value: 'Practiced transitions');
  });
  tearDown(() => cubit.close());

  test('does not save an empty entry', () async {
    cubit.logEntryChanged(value: '   ');
    await cubit.addLogEntry(horseProfile: null);
    expect(cubit.state.status, FormStatus.failure);
    verifyZeroInteractions(riders);
  });

  test('rider entry copies existing notes and records date, author and tag',
      () async {
    when(
      () => riders.createOrUpdateRiderProfile(
        riderProfile: any(named: 'riderProfile'),
      ),
    ).thenAnswer((_) async {});
    final date = DateTime.utc(2025);
    cubit
      ..dateChanged(entryDate: date)
      ..logTagChanged(tag: LogTag.Training);
    await cubit.addLogEntry(horseProfile: null);
    final saved = verify(
      () => riders.createOrUpdateRiderProfile(
        riderProfile: captureAny(named: 'riderProfile'),
      ),
    ).captured.single as RiderProfile;
    expect(saved.notes?.single.name, 'Practiced transitions');
    expect(saved.notes?.single.parentId, rider.email);
    expect(saved.notes?.single.date, date);
    expect(saved.notes?.single.imageUrl, LogTag.Training.toString());
    expect(rider.notes, isEmpty);
    expect(cubit.state.status, FormStatus.success);
  });

  test('waits for horse persistence before reporting success', () async {
    final pending = Completer<void>();
    when(
      () => horses.createOrUpdateHorseProfile(
        horseProfile: any(named: 'horseProfile'),
      ),
    ).thenAnswer((_) => pending.future);
    final horse = HorseProfile(id: 'h', name: 'Horse', notes: const []);
    final saving = cubit.addLogEntry(horseProfile: horse);
    expect(cubit.state.status, FormStatus.submitting);
    expect(horse.notes, isEmpty);
    pending.complete();
    await saving;
    expect(cubit.state.status, FormStatus.success);
  });

  for (final forHorse in [true, false]) {
    test('reports asynchronous ${forHorse ? 'horse' : 'rider'} write failures',
        () async {
      final pending = Completer<void>();
      if (forHorse) {
        when(
          () => horses.createOrUpdateHorseProfile(
            horseProfile: any(named: 'horseProfile'),
          ),
        ).thenAnswer((_) => pending.future);
      } else {
        when(
          () => riders.createOrUpdateRiderProfile(
            riderProfile: any(named: 'riderProfile'),
          ),
        ).thenAnswer((_) => pending.future);
      }
      final saving = cubit.addLogEntry(
        horseProfile: forHorse ? HorseProfile(id: 'h', name: 'Horse') : null,
      );
      pending.completeError(Exception('offline'));
      await saving;
      expect(cubit.state.status, FormStatus.failure);
      expect(rider.notes, isEmpty);
    });
  }
}
