import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_primary_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

class _MockConnectionRepository extends Mock implements ConnectionRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
  });

  test('formatHorseAge accounts for birthdays and foals under 1 year', () {
    expect(
      formatHorseAge(DateTime(2020, 10, 15), now: DateTime(2026, 6)),
      '5 years',
    );
    expect(
      formatHorseAge(DateTime(2020, 10, 15), now: DateTime(2026, 10, 15)),
      '6 years',
    );
    expect(
      formatHorseAge(DateTime(2025, 4, 10), now: DateTime(2026, 4, 10)),
      '1 year',
    );
    expect(
      formatHorseAge(DateTime(2026, 1, 10), now: DateTime(2026, 6, 15)),
      '5 months',
    );
    expect(
      formatHorseAge(DateTime(2026, 6), now: DateTime(2026, 6, 15)),
      'Under 1 month',
    );
  });

  testWidgets(
    'Horse Profile shows Public/Private badge only to owner, aligns logbook '
    'buttons, and exposes stable onboarding keys',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final owner = RiderProfile(
        id: 'owner@example.com',
        email: 'owner@example.com',
        name: 'Owner Pat',
      );
      final privateHorse = HorseProfile(
        id: 'horse-1',
        name: 'Atlas',
        currentOwnerId: 'owner@example.com',
        currentOwnerName: 'Owner Pat',
        dateOfBirth: DateTime(2020, 11, 20),
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-owner',
            name: 'Owner Pat',
            email: 'owner@example.com',
            emailVerified: true,
          ),
          usersProfile: owner,
          horseProfile: privateHorse,
          horseId: privateHorse.id,
          isGuest: false,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        BlocProvider<AppCubit>.value(
          value: harness.cubit,
          child: MaterialApp(
            theme: mainThemeDark,
            home: HorseProfileView(horseProfile: privateHorse),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('horseVisibilityBadge')), findsOneWidget);
      expect(find.text('Private profile'), findsOneWidget);
      expect(find.byKey(const Key('logBookButton')), findsOneWidget);
      expect(find.byKey(const Key('horseLogBookButton')), findsOneWidget);
      expect(find.byKey(const Key('horseAddEntryButton')), findsOneWidget);
      expect(find.byKey(const Key('horseSkills')), findsOneWidget);
      expect(find.byKey(const Key('HorseProfileOverFlowMenu')), findsOneWidget);

      // Public visitor should not see the owner visibility badge.
      final publicHorse = privateHorse.copyWith(isPublic: true);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: true,
          clearUsersProfile: true,
          horseProfile: publicHorse,
        ),
      );
      await tester.pumpWidget(
        BlocProvider<AppCubit>.value(
          value: harness.cubit,
          child: MaterialApp(
            theme: mainThemeDark,
            home: HorseProfileView(horseProfile: publicHorse),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('horseVisibilityBadge')), findsNothing);
    },
  );

  testWidgets(
    'ConnectionPanel uses AppSurfaceCard with profileConnectionsSection key '
    'and RiderProfileView respects reduced motion',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final connRepo = _MockConnectionRepository();
      when(
        () => connRepo.watch('uid-alex'),
      ).thenAnswer((_) => Stream.value(const <CoachingConnection>[]));

      final rider = RiderProfile(
        id: 'alex@example.com',
        email: 'alex@example.com',
        name: 'Alex Rider',
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-alex',
            name: 'Alex Rider',
            email: 'alex@example.com',
            emailVerified: true,
          ),
          usersProfile: rider,
          isGuest: false,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

      final connectionsCubit = ConnectionsCubit(connRepo, harness.cubit);
      addTearDown(connectionsCubit.close);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppCubit>.value(value: harness.cubit),
            BlocProvider<ConnectionsCubit>.value(value: connectionsCubit),
          ],
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(1280, 900),
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: mainThemeDark,
              home: RiderProfileView(profile: rider),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(AppScaffoldBackdrop), findsOneWidget);
      expect(find.byType(ConnectionPanel), findsOneWidget);
      expect(
        find.byKey(const Key('profileConnectionsSection')),
        findsOneWidget,
      );
      expect(find.byType(GradientCard), findsNothing);
      expect(find.byKey(const Key('riderSkills')), findsOneWidget);
      expect(find.byKey(const Key('riderHorsesSection')), findsOneWidget);
      expect(find.byKey(const Key('riderAddHorseButton')), findsOneWidget);
      expect(find.byKey(const Key('LogBookButton')), findsOneWidget);
      expect(find.byKey(const Key('AddEntryButton')), findsOneWidget);
    },
  );
}
