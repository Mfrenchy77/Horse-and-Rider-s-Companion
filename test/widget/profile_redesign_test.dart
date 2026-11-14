import 'dart:ui' as ui;

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resources_floating_action_button.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';
import 'package:horseandriderscompanion/Theme/classic_blue_gray.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:super_banners/super_banners.dart';

import '../support/app_test_harness.dart';

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const ProfilePage()),
    GoRoute(
      name: AuthPage.name,
      path: '/auth',
      builder: (_, state) =>
          Scaffold(body: Text('Auth ${state.uri.queryParameters['mode']}')),
    ),
    GoRoute(
      name: SkillTreePage.name,
      path: '/skills',
      builder: (_, _) => const Scaffold(body: Text('Public skills')),
    ),
    GoRoute(
      name: ResourcesPage.name,
      path: '/resources',
      builder: (_, _) => const Scaffold(
        body: Text('Public resources'),
        floatingActionButton: ResourcesFloatingActionButton(),
      ),
    ),
    GoRoute(
      name: HorseProfilePage.name,
      path: '/horses/:${HorseProfilePage.pathParams}',
      builder: (_, state) => Scaffold(
        body: Text(
          'Horse ${state.pathParameters[HorseProfilePage.pathParams]}',
        ),
      ),
    ),
  ],
);

void main() {
  for (final width in [390.0, 1250.0]) {
    testWidgets('horse profile uses the shared cover and layout at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final rider = RiderProfile(
        id: 'owner',
        email: 'owner@example.com',
        name: 'Morgan',
      );
      final skill = Skill(
        id: 'turn',
        skillName: 'Turn on the haunches (under saddle)',
        rider: false,
        position: 0,
        lastEditBy: null,
        description: null,
        lastEditDate: null,
        learningDescription: null,
        proficientDescription: null,
        difficulty: DifficultyState.Intermediate,
      );
      final horse = HorseProfile(
        id: 'atlas',
        name: 'Atlas',
        nickname: 'Al',
        breed: 'Andalusian',
        currentOwnerId: rider.email,
        currentOwnerName: rider.name,
        archiveStatus: 'deceased',
        skillLevels: [
          SkillLevel(
            skillId: skill.id,
            skillName: skill.skillName,
            lastEditBy: null,
            lastEditDate: null,
            levelState: LevelState.PROFICIENT,
            verified: true,
          ),
        ],
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          usersProfile: rider,
          horseProfile: horse,
          isGuest: false,
          isForRider: false,
          allSkills: [skill],
        ),
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp(home: HorseProfileView(horseProfile: horse)),
        ),
      );
      await tester.pump();
      final cover = tester.getRect(find.byKey(const Key('horseIdentity')));
      final skills = tester.getRect(find.byKey(const Key('horseSkills')));
      expect(cover.height, inInclusiveRange(220, 380));
      expect(find.text('Archived · Deceased'), findsOneWidget);
      expect(find.text('Owner · Morgan'), findsOneWidget);
      expect(find.text('Andalusian'), findsOneWidget);
      expect(find.text('Date of birth'), findsNothing);
      expect(find.text('Height'), findsNothing);
      expect(find.text("Horse's Log Book"), findsOneWidget);
      final logbook = find.text("Horse's Log Book");
      final about = find.text('About');
      expect(tester.getRect(logbook).top, greaterThan(cover.bottom));
      expect(
        tester.getRect(logbook).bottom,
        lessThan(tester.getRect(about).top),
      );
      expect(find.text('Al'), findsNothing);
      await tester.tap(find.text('Show more details'));
      await tester.pumpAndSettle();
      expect(find.text('Al'), findsOneWidget);
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      expect(find.text('Al'), findsNothing);
      expect(find.widgetWithText(ListTile, skill.skillName), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Proficient'), findsOneWidget);
      if (width < 1024) {
        expect(skills.top, greaterThan(cover.bottom));
      } else {
        expect(skills.left, greaterThan(cover.right));
        expect(skills.top, cover.top);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('horse sale details sit below the cover and above About', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final horse = HorseProfile(
      id: 'atlas',
      name: 'Atlas',
      locationName: 'Bend, Oregon',
      breed: 'Mustang',
      saleListing: (
        price: '100000',
        location: 'Central Oregon',
        description: 'Experienced school horse.',
      ),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp(home: HorseProfileView(horseProfile: horse)),
      ),
    );
    final cover = tester.getRect(find.byKey(const Key('horseIdentity')));
    final ribbon = find.ancestor(
      of: find.text('FOR SALE'),
      matching: find.byType(CornerBanner),
    );
    expect(tester.getTopLeft(ribbon), cover.topLeft);
    expect(tester.getRect(ribbon).bottom, lessThan(cover.bottom));
    expect(cover.contains(tester.getCenter(find.text('Bend, Oregon'))), isTrue);
    expect(
      tester.getTopLeft(find.text('100,000')).dy,
      greaterThan(cover.bottom),
    );
    expect(
      tester.getBottomLeft(find.text('Experienced school horse.')).dy,
      lessThan(tester.getTopLeft(find.text('About')).dy),
    );
    expect(find.text('Central Oregon'), findsOneWidget);
  });

  testWidgets('guest can browse and reach the right account action', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final router = _router();
    addTearDown(router.dispose);
    harness.cubit.emit(
      harness.cubit.state.copyWith(pageStatus: AppPageStatus.loaded),
    );
    await tester.pumpWidget(
      BlocProvider.value(
        value: harness.cubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Horse & Rider’s Companion'), findsOneWidget);
    expect(find.text("Rider's Log Book"), findsNothing);
    expect(find.text('Edit Profile'), findsNothing);
    expect(harness.cubit.isAuthorized(), isFalse);

    for (final (action, destination) in [
      ('Explore Skill Tree', 'Public skills'),
      ('Explore Resources', 'Public resources'),
      ('Create account', 'Auth register'),
      ('Sign in', 'Auth login'),
    ]) {
      await tester.ensureVisible(find.text(action));
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(find.text(destination), findsOneWidget);
      if (destination == 'Public resources') {
        expect(find.byKey(const Key('addResourceButton')), findsNothing);
        await tester.tap(find.text('Sign in to share'));
        await tester.pumpAndSettle();
        expect(find.text('Auth login'), findsOneWidget);
      }
      router.go('/');
      await tester.pumpAndSettle();
    }

    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        user: const User(
          id: 'rider',
          email: 'rider@example.com',
          name: 'Rider',
          isGuest: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Set up profile'), findsOneWidget);
    expect(find.text('Create account'), findsNothing);
  });

  for (final width in [360.0, 1200.0]) {
    testWidgets('rider content and horse navigation at width $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final router = _router();
      addTearDown(router.dispose);
      const photoUrl = 'https://example.com/profile-cover.png';
      const provider = NetworkImage(photoUrl);
      final hasPhoto = width >= RiderProfileView.largeBreakpoint;
      if (hasPhoto) {
        await tester.runAsync(() async {
          final bytes = await rootBundle.load('assets/horse_background.png');
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
          final frame = await codec.getNextFrame();
          codec.dispose();
          PaintingBinding.instance.imageCache.putIfAbsent(
            provider,
            () => OneFrameImageStreamCompleter(
              Future.value(ImageInfo(image: frame.image)),
            ),
          );
        });
      }
      final longBio = width < RiderProfileView.largeBreakpoint;
      const intro = 'I teach groundwork and trail riding.';
      final bio = longBio ? List.filled(12, intro).join(' ') : intro;
      final rider = RiderProfile(
        id: 'rider',
        email: 'rider@example.com',
        name: 'Morgan Rider',
        picUrl: hasPhoto ? photoUrl : null,
        bio: bio,
        locationName: 'Bend, Oregon',
        homeUrl: 'https://example.com',
        students: [
          BaseListItem(
            id: 'student@example.com',
            name: 'Casey',
            isCollapsed: true,
          ),
        ],
        ownedHorses: [
          BaseListItem(id: 'atlas', name: 'Atlas', isCollapsed: false),
        ],
        studentHorses: [
          BaseListItem(id: 'sage', name: 'Sage', isCollapsed: false),
        ],
        instructors: [
          BaseListItem(
            id: 'trainer@example.com',
            name: 'Lee',
            isCollapsed: true,
          ),
        ],
        skillLevels: [
          SkillLevel(
            skillId: 'grooming',
            skillName: 'Grooming',
            lastEditBy: 'Morgan',
            lastEditDate: DateTime.utc(2025),
            levelState: LevelState.LEARNING,
          ),
        ],
      );
      final skill = Skill(
        id: 'grooming',
        skillName: 'Grooming',
        rider: true,
        position: 0,
        lastEditBy: 'Morgan',
        lastEditDate: DateTime.utc(2025),
        description: '',
        learningDescription: '',
        proficientDescription: '',
      );
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          pageStatus: AppPageStatus.loaded,
          isGuest: false,
          usersProfile: rider,
          allSkills: [skill],
        ),
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: harness.cubit,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      for (final content in [
        'Morgan Rider',
        'Bend, Oregon',
        'About',
        bio,
        'Website',
        "Rider's Log Book",
        'Add entry',
        'Atlas',
        'Casey',
        'Sage',
        'Lee',
        'Grooming',
      ]) {
        expect(find.text(content), findsOneWidget);
      }
      expect(
        tester.getRect(find.text("Rider's Log Book")).bottom,
        lessThan(tester.getRect(find.text('About')).top),
      );
      final bioText = find.text(bio);
      if (longBio) {
        expect(tester.widget<Text>(bioText).maxLines, 5);
        await tester.tap(find.text('Read full bio'));
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(bioText).maxLines, isNull);
        await tester.ensureVisible(find.text('Show less'));
        await tester.tap(find.text('Show less'));
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(bioText).maxLines, 5);
      } else {
        expect(find.text('Read full bio'), findsNothing);
      }
      expect(find.text('Sign in'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Grooming'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      final identity = find.byKey(const Key('riderIdentity'));
      final cover = tester.getRect(identity);
      expect(cover.height, greaterThanOrEqualTo(220));
      expect(cover.height, lessThanOrEqualTo(380));
      final name = tester.getRect(find.text('Morgan Rider'));
      final location = tester.getRect(find.text('Bend, Oregon'));
      expect(name.top, greaterThan(cover.center.dy));
      expect(location.bottom, lessThan(cover.bottom));
      expect(find.byKey(const Key('RiderProfileOverFlowMenu')), findsOneWidget);

      if (hasPhoto) {
        final photo = find.byKey(const Key('riderCoverPhoto'));
        expect(tester.getRect(photo), cover);
        final painted = find.descendant(
          of: photo,
          matching: find.byType(RawImage),
        );
        expect(tester.widget<RawImage>(painted).fit, BoxFit.cover);
        expect(tester.widget<RawImage>(painted).image, isNotNull);
        expect(find.byTooltip('View full photo'), findsOneWidget);
      } else {
        expect(cover.height, 220);
        final fallback = find.descendant(
          of: identity,
          matching: find.byType(Image),
        );
        expect(
          tester.widget<Image>(fallback).image,
          const AssetImage('assets/horse_logo.png'),
        );
        expect(
          find.descendant(of: identity, matching: find.byType(CircleAvatar)),
          findsNothing,
        );
      }
      final skills = find.byKey(const Key('riderSkills'));
      if (width < RiderProfileView.largeBreakpoint) {
        expect(
          tester.getTopLeft(skills).dy,
          greaterThan(tester.getBottomLeft(identity).dy),
        );
      } else {
        expect(
          tester.getTopLeft(skills).dx,
          greaterThan(tester.getTopRight(identity).dx),
        );
        expect(
          tester.getSize(skills).width,
          greaterThan(tester.getSize(identity).width),
        );
      }

      await tester.ensureVisible(find.text('Atlas'));
      await tester.tap(find.text('Atlas'));
      await tester.pumpAndSettle();
      expect(find.text('Horse atlas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Classic Blue Gray gradient fills the profile app bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: mainThemeLight,
        home: Scaffold(appBar: ThemedAppBar(title: const Text('My profile'))),
      ),
    );

    final gradient = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).gradient ==
              ClassicBlueGray.appBar,
    );
    expect(gradient, findsOneWidget);
    expect(tester.getSize(gradient), tester.getSize(find.byType(ThemedAppBar)));
  });

  testWidgets(
    'selected theme supplies the card gradient and semantic colors win',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final themes = HorseAndRidersTheme();
      final dark = themes.getDarkTheme();
      final light = themes.getLightTheme();
      final darkGradient = dark.extension<CardGradientTheme>()!.gradient;
      expect(darkGradient.colors.toSet(), hasLength(2));
      expect(
        light.extension<CardGradientTheme>()!.gradient,
        isNot(darkGradient),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: dark,
          home: const Column(
            children: [
              GradientCard(child: Text('Content')),
              GradientCard(color: Colors.red, child: Text('Warning')),
            ],
          ),
        ),
      );
      final decoration =
          tester.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration;
      expect(decoration.gradient, darkGradient);
      expect(tester.widget<Card>(find.byType(Card).last).color, Colors.red);
    },
  );
}
