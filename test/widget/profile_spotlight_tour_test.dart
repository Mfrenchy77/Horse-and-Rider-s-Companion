import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/onboarding_prefs.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

class _MockConnectionRepository extends Mock implements ConnectionRepository {}

Future<void> _pumpFrames(
  WidgetTester tester, {
  int count = 8,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(step);
  }
}

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

  group('OnboardingPrefs', () {
    test('separates tours, invite vs completion, and user accounts', () async {
      final newRider = RiderProfile(
        id: 'new@example.com',
        email: 'new@example.com',
        name: 'New Rider',
      );
      final establishedRider = RiderProfile(
        id: 'pro@example.com',
        email: 'pro@example.com',
        name: 'Pro Rider',
        ownedHorses: [
          BaseListItem(id: 'h1', name: 'Atlas', isCollapsed: false),
        ],
      );

      expect(
        OnboardingPrefs.shouldShowProfileInvitation(
          profile: newRider,
          userKey: 'new@example.com',
        ),
        isTrue,
      );
      expect(
        OnboardingPrefs.shouldShowProfileInvitation(
          profile: establishedRider,
          userKey: 'pro@example.com',
        ),
        isFalse,
      );

      // Dismissing for user A does not affect user B or other tours.
      await OnboardingPrefs.setInviteState(
        tour: OnboardingTourId.profile,
        userKey: 'new@example.com',
        state: OnboardingInviteState.deferred,
      );
      expect(
        OnboardingPrefs.shouldShowProfileInvitation(
          profile: newRider,
          userKey: 'new@example.com',
        ),
        isFalse,
      );
      expect(
        OnboardingPrefs.shouldShowProfileInvitation(
          profile: newRider,
          userKey: 'other@example.com',
        ),
        isTrue,
      );
      expect(
        OnboardingPrefs.isCompleted(
          tour: OnboardingTourId.skillTree,
          userKey: 'new@example.com',
        ),
        isFalse,
      );

      await OnboardingPrefs.setCompleted(
        tour: OnboardingTourId.profile,
        userKey: 'new@example.com',
        completed: true,
      );
      expect(
        OnboardingPrefs.isCompleted(
          tour: OnboardingTourId.profile,
          userKey: 'new@example.com',
        ),
        isTrue,
      );
      expect(
        OnboardingPrefs.isCompleted(
          tour: OnboardingTourId.resources,
          userKey: 'new@example.com',
        ),
        isFalse,
      );
    });
  });

  testWidgets(
    'First-visit invitation appears only for own new profile, Not now '
    'persists dismissal, and viewed profiles never show invitation',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);

      final newRider = RiderProfile(
        id: 'new@example.com',
        email: 'new@example.com',
        name: 'New Rider',
      );
      final otherRider = RiderProfile(
        id: 'other@example.com',
        email: 'other@example.com',
        name: 'Other Rider',
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-new',
            name: 'New Rider',
            email: 'new@example.com',
            emailVerified: true,
          ),
          usersProfile: newRider,
          isGuest: false,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

      // Viewing another rider's profile must NOT show invitation.
      await tester.pumpWidget(
        RepositoryProvider<SkillTreeV2Repository>.value(
          value: repo,
          child: BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: RiderProfileView(profile: otherRider),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('profileTourInvitationCard')), findsNothing);

      // Own new profile DOES show the invitation.
      await tester.pumpWidget(
        RepositoryProvider<SkillTreeV2Repository>.value(
          value: repo,
          child: BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: RiderProfileView(profile: newRider),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.byKey(const Key('profileTourInvitationCard')),
        findsOneWidget,
      );
      expect(find.text('Make the most of your profile'), findsOneWidget);

      // Dismiss with Not now -> hidden & persisted.
      await tester.tap(find.byKey(const Key('profileTourInviteDismiss')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('profileTourInvitationCard')), findsNothing);
      expect(
        OnboardingPrefs.inviteState(
          tour: OnboardingTourId.profile,
          userKey: 'new@example.com',
        ),
        OnboardingInviteState.deferred,
      );
    },
  );

  testWidgets(
    'Newly registered Rider with no horses or progress completes full '
    '4-chapter tour on mobile with reduced motion, including Back/Next',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);
      final connRepo = _MockConnectionRepository();
      when(
        () => connRepo.watch('uid-new'),
      ).thenAnswer((_) => Stream.value(const <CoachingConnection>[]));
      final connCubit = ConnectionsCubit(connRepo, harness.cubit);
      addTearDown(connCubit.close);

      final newRider = RiderProfile(
        id: 'new@example.com',
        email: 'new@example.com',
        name: 'New Rider',
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-new',
            name: 'New Rider',
            email: 'new@example.com',
            emailVerified: true,
          ),
          usersProfile: newRider,
          isGuest: false,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        RepositoryProvider<SkillTreeV2Repository>.value(
          value: repo,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AppCubit>.value(value: harness.cubit),
              BlocProvider<ConnectionsCubit>.value(value: connCubit),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                disableAnimations: true,
              ),
              child: MaterialApp(
                theme: mainThemeDark,
                home: RiderProfileView(profile: newRider),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Start tour from first-visit invitation.
      await tester.tap(find.byKey(const Key('profileTourInviteAccept')));
      await _pumpFrames(tester);

      expect(find.text('Profile Identity'), findsOneWidget);

      // Step 2: Edit Profile (overflow menu)
      await tester.tap(find.byKey(const Key('profileTourNextButton')));
      await _pumpFrames(tester);
      expect(find.text('Edit Profile'), findsAtLeastNWidgets(1));

      // Test Back button returns to Profile Identity
      await tester.tap(find.byKey(const Key('profileTourBackButton')));
      await _pumpFrames(tester);
      expect(find.text('Profile Identity'), findsOneWidget);

      // Walk all remaining steps to Finish (13 steps for no-horse profile)
      for (var i = 0; i < 12; i++) {
        await tester.tap(find.byKey(const Key('profileTourNextButton')));
        await _pumpFrames(tester);
      }

      expect(find.text('Tutorial and Help'), findsOneWidget);
      expect(find.text('Finish'), findsOneWidget);

      await tester.tap(find.byKey(const Key('profileTourNextButton')));
      await _pumpFrames(tester);

      expect(
        OnboardingPrefs.isCompleted(
          tour: OnboardingTourId.profile,
          userKey: 'new@example.com',
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'Narrow mobile tour keeps Back and Next buttons inside viewport even on '
    'tall ProfileSkills dashboard target',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);
      final connRepo = _MockConnectionRepository();
      when(
        () => connRepo.watch('uid-tall'),
      ).thenAnswer((_) => Stream.value(const <CoachingConnection>[]));
      final connCubit = ConnectionsCubit(connRepo, harness.cubit);
      addTearDown(connCubit.close);

      // Seed multiple Learning skills so ProfileSkills dashboard is tall.
      final riderSkills = (await repo.fetchSkills())
          .where((s) => s.subject == SkillSubject.rider)
          .take(4)
          .toList();
      for (final skill in riderSkills) {
        await repo.setLevelProgress(
          subject: SkillSubject.rider,
          profileDocId: 'tall@example.com',
          skillId: skill.id,
          level: skill.availableLevels.first,
          state: LevelState.LEARNING,
          actorUid: 'uid-tall',
        );
      }

      final rider = RiderProfile(
        id: 'tall@example.com',
        email: 'tall@example.com',
        name: 'Tall Profile Rider',
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-tall',
            name: 'Tall Profile Rider',
            email: 'tall@example.com',
            emailVerified: true,
          ),
          usersProfile: rider,
          isGuest: false,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        RepositoryProvider<SkillTreeV2Repository>.value(
          value: repo,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AppCubit>.value(value: harness.cubit),
              BlocProvider<ConnectionsCubit>.value(value: connCubit),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                disableAnimations: true,
              ),
              child: MaterialApp(
                theme: mainThemeDark,
                home: RiderProfileView(profile: rider),
              ),
            ),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const Key('profileTourInviteAccept')));
      await _pumpFrames(tester);

      // Walk to Step 9 (Skills & Progress, index 8 on no-horse profile).
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byKey(const Key('profileTourNextButton')));
        await _pumpFrames(tester);
      }
      expect(find.text('Skills & Progress'), findsOneWidget);

      final nextRect = tester.getRect(
        find.byKey(const Key('profileTourNextButton')),
      );
      final backRect = tester.getRect(
        find.byKey(const Key('profileTourBackButton')),
      );
      // Must stay well above bottom nav reserve and inside 640px height.
      expect(nextRect.bottom, lessThanOrEqualTo(640 - 88));
      expect(backRect.bottom, lessThanOrEqualTo(640 - 88));
      expect(nextRect.top, greaterThanOrEqualTo(0));

      await tester.tap(find.byKey(const Key('profileTourSkipButton')));
      await _pumpFrames(tester);
    },
  );

  testWidgets(
    'Desktop Rider with horses, Skill Tree progress, and connections visits '
    'Horse Profile during tour and can restart via Tutorial selector',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final repo = SkillTreeV2Repository(store: v2Store);
      final connRepo = _MockConnectionRepository();
      when(
        () => connRepo.watch('uid-trainer'),
      ).thenAnswer((_) => Stream.value(const <CoachingConnection>[]));
      final connCubit = ConnectionsCubit(connRepo, harness.cubit);
      addTearDown(connCubit.close);

      await repo.setLevelProgress(
        subject: SkillSubject.rider,
        profileDocId: 'pro@example.com',
        skillId: 'rider.husbandry.grooming',
        level: DifficultyState.Introductory,
        state: LevelState.LEARNING,
        actorUid: 'uid-trainer',
      );

      final atlas = HorseProfile(
        id: 'horse-atlas',
        name: 'Atlas',
        currentOwnerId: 'pro@example.com',
        currentOwnerName: 'Pro Trainer',
      );
      final trainer = RiderProfile(
        id: 'pro@example.com',
        email: 'pro@example.com',
        name: 'Pro Trainer',
        isTrainer: true,
        ownedHorses: [
          BaseListItem(id: 'horse-atlas', name: 'Atlas', isCollapsed: false),
        ],
        students: [
          BaseListItem(
            id: 'student@example.com',
            name: 'Student Sam',
            isCollapsed: true,
          ),
        ],
      );

      when(
        () => harness.horses.getHorseProfileById(id: 'horse-atlas'),
      ).thenAnswer((_) => Stream<HorseProfile?>.value(atlas));
      when(
        harness.resources.getResources,
      ).thenAnswer((_) => const Stream.empty());

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'uid-trainer',
            name: 'Pro Trainer',
            email: 'pro@example.com',
            emailVerified: true,
          ),
          usersProfile: trainer,
          isGuest: false,
          isProfileSetup: true,
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
        ),
      );

      final settings = SettingsController(SettingsService());
      await settings.loadSettings();
      addTearDown(settings.dispose);

      final router = Routes().router(
        settingsContoller: settings,
        appCubit: harness.cubit,
      );
      addTearDown(router.dispose);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        SettingsControllerScope(
          controller: settings,
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ResourcesRepository>.value(
                value: harness.resources,
              ),
              RepositoryProvider<SkillTreeV2Repository>.value(value: repo),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AppCubit>.value(value: harness.cubit),
                BlocProvider<ConnectionsCubit>.value(value: connCubit),
              ],
              child: MaterialApp.router(
                theme: mainThemeDark,
                routerConfig: router,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Established user should NOT see unsolicited invitation banner.
      expect(find.byKey(const Key('profileTourInvitationCard')), findsNothing);

      // Open drawer -> tap Tutorial -> verify selector shows 3 tours.
      await tester.tap(find.byKey(const Key('HamburgerIcon')));
      await _pumpFrames(tester);

      final tutorialTile = find.byKey(const Key('drawerTutorialTile'));
      await tester.ensureVisible(tutorialTile);
      await tester.tap(tutorialTile);
      await _pumpFrames(tester);

      expect(find.byKey(const Key('tutorialSelectorDialog')), findsOneWidget);
      expect(find.byKey(const Key('tutorialSelectProfile')), findsOneWidget);
      expect(find.byKey(const Key('tutorialSelectSkillTree')), findsOneWidget);
      expect(find.byKey(const Key('tutorialSelectResources')), findsOneWidget);
      expect(find.text('Coming soon'), findsNWidgets(2));

      // Launch Profile tour from selector.
      await tester.tap(find.byKey(const Key('tutorialSelectProfile')));
      await _pumpFrames(tester);

      expect(find.text('Profile Identity'), findsOneWidget);

      // Advance to Step 7 (Horse Profiles -> navigates to Atlas's
      // HorseProfilePage).
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(const Key('profileTourNextButton')));
        await _pumpFrames(tester, count: 16);
      }
      expect(find.text('Horse Profiles'), findsOneWidget);
      expect(find.byKey(const Key('horseIdentity')), findsOneWidget);

      // Advance to Step 8 (Rider's Log Book -> returns cleanly to
      // RiderProfileView).
      await tester.tap(find.byKey(const Key('profileTourNextButton')));
      await _pumpFrames(tester, count: 16);
      final logBookCard = find.byKey(const Key('profileTourStepCard_7'));
      expect(logBookCard, findsOneWidget);
      expect(
        find.descendant(
          of: logBookCard,
          matching: find.text("Rider's Log Book"),
        ),
        findsOneWidget,
      );

      // Skip mid-tour -> cleans up overlay and does not mark completed.
      await tester.tap(find.byKey(const Key('profileTourSkipButton')));
      await _pumpFrames(tester);
      expect(logBookCard, findsNothing);
      expect(
        OnboardingPrefs.isCompleted(
          tour: OnboardingTourId.profile,
          userKey: 'pro@example.com',
        ),
        isFalse,
      );
    },
  );
}
