import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_drawer.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

class _MockApiKeyProvider extends Mock implements ApiKeyProvider {}

class _MockMediaStorageRepository extends Mock
    implements MediaStorageRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySkillTreeV2Store v2Store;

  setUpAll(() async {
    v2Store = await const AssetCurriculumV2Loader().loadInMemoryStore();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
  });

  testWidgets(
    'Own Rider Profile shows Horses empty state with Add Horse, Explore Skill '
    'Tree even with an instructor, and Log Out works in overflow menu',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      when(harness.auth.logOut).thenAnswer((_) async {});

      final rider = RiderProfile(
        id: 'alex@example.com',
        email: 'alex@example.com',
        name: 'Alex Rider',
        instructors: [
          BaseListItem(
            id: 'coach@example.com',
            name: 'Coach Sam',
            isCollapsed: true,
          ),
        ],
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
          isProfileSetup: true,
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
            home: RiderProfileView(profile: rider),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('riderHorsesSection')), findsOneWidget);
      expect(find.byKey(const Key('riderAddHorseButton')), findsOneWidget);
      expect(find.text('Explore Skill Tree'), findsAtLeastNWidgets(1));
      expect(find.text('Open student Skill Tree'), findsNothing);

      final overflow = find.byKey(const Key('RiderProfileOverFlowMenu'));
      expect(overflow, findsOneWidget);
      await tester.tap(overflow);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Log Out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      verify(harness.auth.logOut).called(1);
    },
  );

  testWidgets(
    'Viewed Rider Profile hides owner overflow menu and checks viewer '
    'savedProfilesList for Add/Remove Contact',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final viewer = RiderProfile(
        id: 'viewer@example.com',
        email: 'viewer@example.com',
        name: 'Viewer Rider',
        savedProfilesList: [
          BaseListItem(
            id: 'target@example.com',
            name: 'Target Rider',
            isCollapsed: true,
          ),
        ],
      );
      // Target does NOT have viewer in its savedProfilesList.
      final target = RiderProfile(
        id: 'target@example.com',
        email: 'target@example.com',
        name: 'Target Rider',
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-viewer',
            name: 'Viewer Rider',
            email: 'viewer@example.com',
            emailVerified: true,
          ),
          usersProfile: viewer,
          viewingProfile: target,
          isViewing: true,
          isGuest: false,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

      await tester.pumpWidget(
        BlocProvider<AppCubit>.value(
          value: harness.cubit,
          child: MaterialApp(
            theme: mainThemeDark,
            home: RiderProfileView(profile: target),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('RiderProfileOverFlowMenu')), findsNothing);
      expect(find.text('Remove Contact'), findsOneWidget);
      expect(find.text('Add Contact'), findsNothing);
    },
  );

  testWidgets(
    'HorseProfileView uses HorseProfileOverFlowMenu key and renders '
    'ConnectionPanel for an unlinked trainer viewing an active public horse',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final trainer = RiderProfile(
        id: 'trainer@example.com',
        email: 'trainer@example.com',
        name: 'Coach Sam',
        isTrainer: true,
      );
      final horse = HorseProfile(
        id: 'horse-public-1',
        name: 'Atlas',
        currentOwnerId: 'owner@example.com',
        currentOwnerName: 'Owner Pat',
        isPublic: true,
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-trainer',
            name: 'Coach Sam',
            email: 'trainer@example.com',
            emailVerified: true,
          ),
          usersProfile: trainer,
          horseProfile: horse,
          horseId: horse.id,
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
            home: HorseProfileView(horseProfile: horse),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const Key('HorseProfileOverFlowMenu')), findsOneWidget);
      expect(find.byKey(const Key('RiderProfileOverFlowMenu')), findsNothing);
      expect(find.byType(ConnectionPanel), findsOneWidget);
    },
  );

  testWidgets(
    'Horse Skill Tree enforces owner-only self-assessment and offers horse '
    'selector card when no horse is active',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);
      when(
        harness.resources.getResources,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => harness.resources.getResourcesForSkill(
          skillId: any(named: 'skillId'),
        ),
      ).thenAnswer((_) => const Stream.empty());

      final viewer = RiderProfile(
        id: 'viewer@example.com',
        email: 'viewer@example.com',
        name: 'Viewer Rider',
        ownedHorses: [
          BaseListItem(id: 'my-horse-1', name: 'Comet', isCollapsed: false),
        ],
      );
      final otherOwnersHorse = HorseProfile(
        id: 'other-horse',
        name: 'Atlas',
        currentOwnerId: 'owner@example.com',
        currentOwnerName: 'Owner Pat',
        isPublic: true,
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-viewer',
            name: 'Viewer Rider',
            email: 'viewer@example.com',
            emailVerified: true,
          ),
          usersProfile: viewer,
          horseProfile: otherOwnersHorse,
          horseId: otherOwnersHorse.id,
          isForRider: false,
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
            home: SkillTreeV2View(repository: repo),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Non-owner cannot self-assess another user's horse.
      expect(
        find.text('Only the horse owner can record self-assessments.'),
        findsOneWidget,
      );

      // Clear active horse -> horse selector banner should appear with Comet.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          clearHorseProfile: true,
          isForRider: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('skillTreeHorseSelectorCard')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('skillTreeSelectHorse_my-horse-1')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('skillTreeAddHorseButton')), findsOneWidget);
    },
  );

  testWidgets('EditRiderProfileDialog includes RiderLocation field', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final keys = _MockApiKeyProvider();
    final cloud = _MockMediaStorageRepository();
    when(keys.getZipCodeApiKey).thenAnswer((_) async => '');
    when(keys.getLocationApiKey).thenAnswer((_) async => '');

    final rider = RiderProfile(
      id: 'alex@example.com',
      email: 'alex@example.com',
      name: 'Alex Rider',
      locationName: 'San Diego, CA',
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ApiKeyProvider>.value(value: keys),
          RepositoryProvider<MediaStorageRepository>.value(value: cloud),
          RepositoryProvider<RiderProfileStore>.value(value: harness.riders),
        ],
        child: MaterialApp(
          theme: mainThemeDark,
          home: Scaffold(
            body: EditRiderProfileDialog(
              riderProfile: rider,
              onProfileUpdated: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('riderLocation')), findsOneWidget);
  });

  testWidgets(
    'ViewingProfilePage shows error UI instead of infinite loading on failure',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      when(
        () => harness.riders.getRiderProfileByEmail(
          email: any(named: 'email'),
          serverOnly: any(named: 'serverOnly'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => harness.riders.getPublicRiderProfile(email: any(named: 'email')),
      ).thenAnswer((_) => Stream<RiderProfile?>.value(null));

      await tester.pumpWidget(
        BlocProvider<AppCubit>.value(
          value: harness.cubit,
          child: MaterialApp(
            theme: mainThemeDark,
            home: const ViewingProfilePage(id: 'missing@example.com'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('viewingProfileError')), findsOneWidget);
      expect(find.text('Rider Profile Unavailable'), findsOneWidget);
      expect(
        find.byKey(const Key('viewingProfileRetryButton')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('viewingProfileBackButton')), findsOneWidget);
    },
  );

  testWidgets('UserProfileDrawer renders safely when usersProfile is null', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);

    await tester.pumpWidget(
      BlocProvider<AppCubit>.value(
        value: harness.cubit,
        child: MaterialApp(
          theme: mainThemeDark,
          home: const Scaffold(body: UserProfileDrawer()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(UserProfileDrawer), findsOneWidget);
  });
}
