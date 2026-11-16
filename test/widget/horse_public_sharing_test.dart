import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

HorseProfile _buildHorse({
  bool isPublic = false,
  HorseSaleListing? saleListing,
}) {
  return HorseProfile(
    id: 'horse-starlight',
    name: 'Starlight',
    breed: 'Quarter Horse',
    gender: 'Mare',
    color: 'Bay',
    locationName: 'Austin, TX',
    currentOwnerId: 'owner@example.com',
    currentOwnerName: 'Secret Owner',
    purchasePrice: 12000,
    isPublic: isPublic,
    saleListing: saleListing,
    instructors: [
      BaseListItem(id: 'trainer@example.com', name: 'Trainer Bob'),
    ],
    skillLevels: [
      SkillLevel(
        skillId: 's1',
        skillName: 'Lead at the walk',
        levelState: LevelState.PROFICIENT,
        lastEditBy: 'owner@example.com',
        lastEditDate: DateTime(2026),
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_buildHorse());
  });

  test('HorseProfile defaults isPublic to false and round-trips it', () {
    final horse = _buildHorse();
    expect(horse.isPublic, isFalse);
    expect(horse.toMap()['isPublic'], isFalse);

    final publicHorse = horse.copyWith(isPublic: true);
    expect(publicHorse.isPublic, isTrue);
    expect(HorseProfile.fromMap(publicHorse.toMap()).isPublic, isTrue);
    expect(
      HorseProfileFirestoreMapper.toFirestore(publicHorse)['isPublic'],
      isTrue,
    );
  });

  testWidgets('private horse hides identifying info from guest visitors', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);

    final horse = _buildHorse(
      saleListing: (
        price: '9500',
        location: 'Austin, TX',
        description: 'Hidden sale description',
      ),
    );

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    harness.cubit.emit(
      harness.cubit.state.copyWith(horseProfile: horse, isGuest: true),
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp(
          theme: mainThemeDark,
          home: HorseProfileView(horseProfile: horse),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('horsePrivateNotice')), findsOneWidget);
    expect(find.text('Starlight'), findsNothing);
    expect(find.text('Quarter Horse'), findsNothing);
    expect(find.text('Hidden sale description'), findsNothing);
    expect(find.byKey(const Key('horseSkills')), findsNothing);
    expect(find.byKey(const Key('logBookButton')), findsNothing);
  });

  testWidgets(
    'public horse shows public details and sale listing to guests '
    'without private fields',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final horse = _buildHorse(
        isPublic: true,
        saleListing: (
          price: '9500',
          location: 'Austin, TX',
          description: 'Calm trail partner with solid groundwork.',
        ),
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(horseProfile: horse, isGuest: true),
      );

      await tester.pumpWidget(
        BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp(
            theme: mainThemeDark,
            home: HorseProfileView(horseProfile: horse),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('horsePrivateNotice')), findsNothing);
      expect(find.text('Starlight'), findsOneWidget);
      expect(find.text('Quarter Horse'), findsOneWidget);
      expect(
        find.text('Calm trail partner with solid groundwork.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('currentOwner')), findsNothing);
      expect(find.textContaining('Secret Owner'), findsNothing);
      expect(find.byKey(const Key('logBookButton')), findsNothing);
      expect(find.text('Instructors'), findsNothing);
      expect(find.text('Trainer Bob'), findsNothing);
      expect(find.byKey(const Key('horseSkills')), findsNothing);
    },
  );

  testWidgets(
    'owner can toggle public sharing from overflow menu '
    'independently of sale listing',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final horse = _buildHorse(
        saleListing: (
          price: '9500',
          location: 'Austin, TX',
          description: 'Calm trail partner.',
        ),
      );
      when(
        () => harness.horses.createOrUpdateHorseProfile(
          horseProfile: any(named: 'horseProfile'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => harness.horses.getPublicHorseProfileById(id: horse.id),
      ).thenAnswer((_) => Stream.value(horse.copyWith(isPublic: true)));
      final owner = RiderProfile(
        id: 'owner@example.com',
        email: 'owner@example.com',
        name: 'Owner Name',
      );
      const authUser = User(
        id: 'owner-uid',
        name: 'Owner Name',
        email: 'owner@example.com',
        emailVerified: true,
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: authUser,
          usersProfile: owner,
          horseProfile: horse,
          isGuest: false,
        ),
      );

      await tester.pumpWidget(
        BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp(
            theme: mainThemeDark,
            home: Scaffold(
              appBar: AppBar(
                actions: const [
                  HorseProfileOverFlowMenu(
                    key: Key('RiderProfileOverFlowMenu'),
                  ),
                ],
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('RiderProfileOverFlowMenu')));
      await tester.pumpAndSettle();

      expect(find.text('Enable public sharing'), findsOneWidget);
      await tester.tap(find.text('Enable public sharing'));
      await tester.pumpAndSettle();

      expect(harness.cubit.state.horseProfile?.isPublic, isTrue);
      expect(harness.cubit.state.horseProfile?.saleListing, isNotNull);
    },
  );
}
