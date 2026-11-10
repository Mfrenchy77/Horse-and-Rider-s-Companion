// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:mocktail/mocktail.dart';

class MockKeys extends Mock implements KeysRepository {}

class MockHorses extends Mock implements HorseProfileRepository {}

class MockRiders extends Mock implements RiderProfileRepository {}

void main() {
  late MockKeys keys;
  late MockHorses horses;
  late MockRiders riders;
  late RiderProfile user;
  late AddHorseDialogCubit cubit;
  setUpAll(() {
    registerFallbackValue(HorseProfile(id: 'h', name: 'Horse'));
    registerFallbackValue(
      RiderProfile(id: 'r', name: 'Rider', email: 'r@example.com'),
    );
  });
  setUp(() {
    keys = MockKeys();
    horses = MockHorses();
    riders = MockRiders();
    user = RiderProfile(id: 'r', name: 'Rider', email: 'r@example.com');
    when(keys.getZipCodeApiKey).thenAnswer((_) async => '');
    when(keys.getLocationApiKey).thenAnswer((_) async => '');
    when(
      () => horses.createOrUpdateHorseProfile(
        horseProfile: any(named: 'horseProfile'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => riders.createOrUpdateRiderProfile(
        riderProfile: any(named: 'riderProfile'),
      ),
    ).thenAnswer((_) async {});
    cubit = AddHorseDialogCubit(
      usersProfile: user,
      horseProfile: null,
      keysRepository: keys,
      horseProfileRepository: horses,
      riderProfileRepository: riders,
    );
  });
  tearDown(() => cubit.close());

  test('creates horse with selected birth date and adds ownership to rider',
      () async {
    final birth = DateTime.utc(2020, 5);
    cubit.horseNameChanged('  Star  ');
    await cubit.horseDateOfBirthChanged(birth);
    await cubit.createHorseProfile();
    final saved = verify(
      () => horses.createOrUpdateHorseProfile(
        horseProfile: captureAny(named: 'horseProfile'),
      ),
    ).captured.single as HorseProfile;
    expect(saved.name, 'Star');
    expect(saved.dateOfBirth, birth);
    expect(saved.currentOwnerId, user.email);
    expect(saved.notes?.any((n) => n.name == 'Star was Born'), isTrue);
    final updated = verify(
      () => riders.createOrUpdateRiderProfile(
        riderProfile: captureAny(named: 'riderProfile'),
      ),
    ).captured.single as RiderProfile;
    expect(updated.ownedHorses?.single.id, saved.id);
    expect(user.ownedHorses, isEmpty);
    expect(cubit.state.status, FormStatus.success);
  });
  test('new horse write failures are reported', () async {
    cubit.horseNameChanged('Star');
    when(
      () => horses.createOrUpdateHorseProfile(
        horseProfile: any(named: 'horseProfile'),
      ),
    ).thenAnswer((_) async => throw Exception('offline'));
    await cubit.createHorseProfile();
    expect(cubit.state.status, FormStatus.failure);
    verifyNever(
      () => riders.createOrUpdateRiderProfile(
        riderProfile: any(named: 'riderProfile'),
      ),
    );
  });
  test(
      'editing preserves training and instructors without mutating original notes',
      () async {
    await cubit.close();
    final horse = HorseProfile(
      id: 'h',
      name: 'Star',
      notes: const [],
      currentOwnerId: user.email,
      currentOwnerName: user.name,
      instructors: [BaseListItem(id: 'trainer')],
      skillLevels: [
        SkillLevel(
          skillId: 's',
          skillName: 'Leading',
          lastEditBy: user.email,
          lastEditDate: DateTime.utc(2025),
          levelState: LevelState.LEARNING,
        ),
      ],
    );
    cubit = AddHorseDialogCubit(
      usersProfile: user,
      horseProfile: horse,
      keysRepository: keys,
      horseProfileRepository: horses,
      riderProfileRepository: riders,
    )..horseNameChanged('New name');
    await cubit.editHorseProfile();
    final saved = verify(
      () => horses.createOrUpdateHorseProfile(
        horseProfile: captureAny(named: 'horseProfile'),
      ),
    ).captured.single as HorseProfile;
    expect(saved.name, 'New name');
    expect(saved.skillLevels?.single.skillId, 's');
    expect(saved.instructors?.single.id, 'trainer');
    expect(saved.notes, hasLength(1));
    expect(horse.notes, isEmpty);
    expect(user.notes, isEmpty);
  });
  test('height and purchase price updates are reflected in state', () {
    cubit
      ..horseHeightChanged(150)
      ..incrementHeightByCentimeter();
    expect(cubit.state.height, 151);
    cubit.decrementHeightByCentimeter();
    expect(cubit.state.height, 150);
    cubit.horsePurchasePriceChanged(1000);
    expect(cubit.state.purchasePrice.isValid, isTrue);
  });
}
