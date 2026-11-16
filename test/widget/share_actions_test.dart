import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/Widgets/horse_profile_overflow_menu.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/share_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

HorseProfile _horse({
  bool isPublic = false,
  String archiveStatus = 'active',
}) {
  return HorseProfile(
    id: 'horse-starlight',
    name: 'Starlight',
    breed: 'Quarter Horse',
    currentOwnerId: 'owner@example.com',
    currentOwnerName: 'Owner Name',
    purchasePrice: 12000,
    isPublic: isPublic,
    archiveStatus: archiveStatus,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySkillTreeV2Store store;
  late SkillTreeV2Repository repository;
  String? lastCopiedClipboard;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    store = await const AssetCurriculumV2Loader().loadInMemoryStore();
    repository = SkillTreeV2Repository(store: store);
    debugNativeShareOverride = null;
    lastCopiedClipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<dynamic, dynamic>?;
            lastCopiedClipboard = args?['text'] as String?;
          }
          return null;
        });
  });

  tearDown(() {
    debugNativeShareOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'public horse shares canonical URL via native share or Copy Link fallback '
    'for both owner and guest without exposing owner toggle to non-owners',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final horse = _horse(isPublic: true);

      // 1. Guest visitor on public horse sees Share Profile only.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(horseProfile: horse, isGuest: true),
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
      expect(find.byKey(const Key('horseMenuShareProfile')), findsOneWidget);
      expect(find.text('Enable public sharing'), findsNothing);
      expect(find.text('Make profile private'), findsNothing);
      expect(find.text('Edit'), findsNothing);

      // Copy Link fallback when native share is unavailable.
      await tester.tap(find.byKey(const Key('horseMenuShareProfile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('shareLinkDialog')), findsOneWidget);
      expect(
        find.text(
          'https://horse-and-riders-compani-d2bd4.web.app/Profile/Horse_Profile/horse-starlight',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('shareCopyLinkButton')));
      await tester.pumpAndSettle();
      expect(
        lastCopiedClipboard,
        'https://horse-and-riders-compani-d2bd4.web.app/Profile/Horse_Profile/horse-starlight',
      );
      expect(find.text('Link copied to clipboard'), findsOneWidget);

      // Native share when supported skips Copy Link dialog.
      String? sharedUrl;
      debugNativeShareOverride = ({
        required title,
        required url,
        text,
      }) async {
        sharedUrl = url;
        return true;
      };
      await tester.tap(find.byKey(const Key('RiderProfileOverFlowMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('horseMenuShareProfile')));
      await tester.pumpAndSettle();
      expect(
        sharedUrl,
        'https://horse-and-riders-compani-d2bd4.web.app/Profile/Horse_Profile/horse-starlight',
      );
      expect(find.byKey(const Key('shareLinkDialog')), findsNothing);
    },
  );

  testWidgets(
    'private horse hides overflow menu from guests and prompts owner to '
    'enable public sharing before sharing',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final horse = _horse();

      // 1. Guest cannot open overflow menu on private horse.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(horseProfile: horse, isGuest: true),
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
      expect(find.byType(PopupMenuButton<String>), findsNothing);

      // 2. Owner sees explanation + Enable & Share on private horse.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'owner-uid',
            name: 'Owner Name',
            email: 'owner@example.com',
            emailVerified: true,
          ),
          usersProfile: RiderProfile(
            id: 'owner@example.com',
            email: 'owner@example.com',
            name: 'Owner Name',
          ),
          horseProfile: horse,
          isGuest: false,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('RiderProfileOverFlowMenu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('horseMenuShareProfile')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('horseSharePrivateDialog')), findsOneWidget);
      expect(
        find.byKey(const Key('horseEnablePublicAndShareButton')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('horseEnablePublicAndShareButton')),
      );
      await tester.pumpAndSettle();

      expect(harness.cubit.state.horseProfile?.isPublic, isTrue);
      expect(find.byKey(const Key('shareLinkDialog')), findsOneWidget);
    },
  );

  testWidgets(
    'Skill Tree 2.0 overflow menu exposes Share Skill for signed-out '
    'visitors on desktop and mobile when a skill is selected',
    (tester) async {
      final families = (await store.fetchFamilies())
          .where((f) => f.subject == SkillSubject.rider)
          .toList();
      final defaultRealm = families.first.realm;
      final skills = await store.fetchSkills();
      final sampleSkill = skills.firstWhere(
        (s) => s.subject == SkillSubject.rider && s.realm == defaultRealm,
      );
      final sampleFamily = families.firstWhere(
        (f) => f.id == sampleSkill.familyId,
      );

      final settings = SettingsController(SettingsService());
      await settings.loadSettings();
      addTearDown(settings.dispose);

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      // Signed-out visitor (isGuest: true).
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(harness.cubit.state.copyWith(isGuest: true));

      // 1. Desktop layout: select a skill and share via overflow menu.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 860);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1280, 860)),
          child: SettingsControllerScope(
            controller: settings,
            child: BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MaterialApp(
                theme: mainThemeDark,
                home: SkillTreeV2View(repository: repository),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Expand family and select skill on desktop.
      await tester.ensureVisible(find.text(sampleFamily.name));
      await tester.tap(find.text(sampleFamily.name));
      await tester.pump();
      await tester.ensureVisible(find.text(sampleSkill.name).first);
      await tester.tap(find.text(sampleSkill.name).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byKey(const Key('skillTreeV2AppBarOverflowMenu')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillTreeV2MenuShareSkill')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('skillTreeV2MenuShareSkill')));
      await tester.pumpAndSettle();

      final expectedUrl =
          'https://horse-and-riders-compani-d2bd4.web.app/SkillTree?skillId='
          '${Uri.encodeComponent(sampleSkill.id)}';
      expect(find.byKey(const Key('shareLinkDialog')), findsOneWidget);
      expect(find.text(expectedUrl), findsOneWidget);
      await tester.tap(find.byKey(const Key('shareCopyLinkButton')));
      await tester.pumpAndSettle();
      expect(lastCopiedClipboard, expectedUrl);

      // 2. Mobile layout: Share Skill appears when skill is selected.
      tester.view.physicalSize = const Size(420, 840);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(420, 840)),
          child: SettingsControllerScope(
            controller: settings,
            child: BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MaterialApp(
                theme: mainThemeDark,
                home: SkillTreeV2View(
                  repository: repository,
                  initialSkillId: sampleSkill.id,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byKey(const Key('skillTreeV2AppBarOverflowMenu')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillTreeV2MenuShareSkill')),
        findsOneWidget,
      );
    },
  );
}
