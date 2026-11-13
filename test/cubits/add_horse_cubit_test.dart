// ignore_for_file: lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockKeys extends Mock implements KeysRepository {}

class MockHorses extends Mock implements HorseProfileRepository {}

class MockRiders extends Mock implements RiderProfileRepository {}

class MockCloud extends Mock implements CloudRepository {}

class MockImagePicker extends Mock implements ImagePicker {}

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
    registerFallbackValue(XFile('test.jpg'));
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
  test(
      'uploading a horse photo preserves horse ID and saves the new picUrl',
      () async {
    await cubit.close();
    final cloud = MockCloud();
    final picker = MockImagePicker();
    const horseId = 'horse-123';
    const uploadedUrl = 'https://example.com/horses/horse-123/photo.jpg';
    final pickedFile = XFile('horse.jpg');

    when(
      () => picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 20,
      ),
    ).thenAnswer((_) async => pickedFile);
    when(
      () => cloud.addHorsePhoto(
        file: any(named: 'file'),
        horseId: any(named: 'horseId'),
      ),
    ).thenAnswer((_) async => uploadedUrl);

    final horse = HorseProfile(
      id: horseId,
      name: 'Star',
      picUrl: 'https://example.com/old.jpg',
      notes: const [],
      currentOwnerId: user.email,
      currentOwnerName: user.name,
    );
    final ownerWithHorse = user.copyWith(
      ownedHorses: [
        BaseListItem(
          id: horseId,
          name: 'Star',
          imageUrl: 'https://example.com/old.jpg',
        ),
      ],
    );

    cubit = AddHorseDialogCubit(
      usersProfile: ownerWithHorse,
      horseProfile: horse,
      keysRepository: keys,
      horseProfileRepository: horses,
      riderProfileRepository: riders,
      cloudRepository: cloud,
      imagePicker: picker,
    );

    await cubit.horsePicButtonClicked();

    verify(
      () => cloud.addHorsePhoto(
        file: pickedFile,
        horseId: horseId,
      ),
    ).called(1);
    expect(cubit.state.horseProfile?.id, horseId);
    expect(cubit.state.horseProfile?.picUrl, uploadedUrl);
    expect(cubit.state.picUrl, uploadedUrl);

    await cubit.editHorseProfile();

    final savedHorse = verify(
      () => horses.createOrUpdateHorseProfile(
        horseProfile: captureAny(named: 'horseProfile'),
      ),
    ).captured.single as HorseProfile;
    expect(savedHorse.id, horseId);
    expect(savedHorse.picUrl, uploadedUrl);

    final savedOwner = verify(
      () => riders.createOrUpdateRiderProfile(
        riderProfile: captureAny(named: 'riderProfile'),
      ),
    ).captured.single as RiderProfile;
    expect(savedOwner.ownedHorses, hasLength(1));
    expect(savedOwner.ownedHorses?.single.id, horseId);
    expect(savedOwner.ownedHorses?.single.imageUrl, uploadedUrl);
  });
  test(
      'cancelling the horse photo picker restores picStatus to nothing without uploading',
      () async {
    await cubit.close();
    final cloud = MockCloud();
    final picker = MockImagePicker();
    const horseId = 'horse-123';
    const existingUrl = 'https://example.com/old.jpg';

    when(
      () => picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 20,
      ),
    ).thenAnswer((_) async => null);

    final horse = HorseProfile(
      id: horseId,
      name: 'Star',
      picUrl: existingUrl,
      notes: const [],
      currentOwnerId: user.email,
      currentOwnerName: user.name,
    );

    cubit = AddHorseDialogCubit(
      usersProfile: user,
      horseProfile: horse,
      keysRepository: keys,
      horseProfileRepository: horses,
      riderProfileRepository: riders,
      cloudRepository: cloud,
      imagePicker: picker,
    );

    await cubit.horsePicButtonClicked();

    expect(cubit.state.picStatus, PictureGetterStatus.nothing);
    expect(cubit.state.horseProfile?.id, horseId);
    expect(cubit.state.horseProfile?.picUrl, existingUrl);
    expect(cubit.state.picUrl, existingUrl);
    verifyNever(
      () => cloud.addHorsePhoto(
        file: any(named: 'file'),
        horseId: any(named: 'horseId'),
      ),
    );
  });
}
