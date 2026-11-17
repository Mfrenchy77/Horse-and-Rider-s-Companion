import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemorySkillTreeV2Store store;
  late SkillTreeV2Repository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    store = await const AssetCurriculumV2Loader().loadInMemoryStore();
    repository = SkillTreeV2Repository(store: store);
  });

  testWidgets(
    'Skill Tree V2 hides duplicate Suggest an Improvement in mobile detail '
    'and keeps Educational Components collapsed by default',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(420, 840);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final settings = SettingsController(SettingsService());
      await settings.loadSettings();
      addTearDown(settings.dispose);

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      // Find a Rider skill in the default realm that has educational
      // components.
      final families = (await store.fetchFamilies())
          .where((f) => f.subject == SkillSubject.rider)
          .toList();
      final defaultRealm = families.first.realm;
      final skills = await store.fetchSkills();
      final sampleSkill = skills.firstWhere(
        (s) =>
            s.subject == SkillSubject.rider &&
            s.realm == defaultRealm &&
            s.levels.isNotEmpty &&
            s.levels.values.every((d) => d.components.isNotEmpty),
      );
      final sampleFamily = families.firstWhere(
        (f) => f.id == sampleSkill.familyId,
      );
      final firstComponent = sampleSkill.levels.values.first.components.first;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(420, 840)),
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

      // General Suggest an Improvement is available on the Skill Tree list.
      await tester.tap(find.byKey(const Key('skillTreeV2AppBarOverflowMenu')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillTreeV2MenuSuggestImprovement')),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(200, 400));
      await tester.pumpAndSettle();

      // Open the sample skill in mobile detail.
      await tester.ensureVisible(find.text(sampleFamily.name));
      await tester.tap(find.text(sampleFamily.name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      await tester.ensureVisible(find.text(sampleSkill.name));
      await tester.tap(find.text(sampleSkill.name));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      // Contextual Suggest Improvement for This Skill is shown.
      expect(
        find.byKey(const Key('skillDetailV2SuggestButton')),
        findsOneWidget,
      );

      // Educational Components is collapsed by default and expands on tap.
      final toggleFinder = find.byKey(
        const Key('educationalComponentsToggle'),
        skipOffstage: false,
      );
      expect(toggleFinder, findsOneWidget);
      expect(find.textContaining(firstComponent.title), findsNothing);

      await tester.ensureVisible(toggleFinder);
      await tester.tap(toggleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.textContaining(firstComponent.title), findsOneWidget);

      await tester.tap(toggleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.textContaining(firstComponent.title), findsNothing);

      // Duplicate general Suggest an Improvement is hidden in mobile detail.
      await tester.tap(find.byKey(const Key('skillTreeV2AppBarOverflowMenu')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillTreeV2MenuSuggestImprovement')),
        findsNothing,
      );
      await tester.tapAt(const Offset(200, 400));
      await tester.pumpAndSettle();

      // Back to list restores general Suggest an Improvement.
      await tester.tap(find.byKey(const Key('skillTreeV2AppBarBackButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.byKey(const Key('skillTreeV2AppBarOverflowMenu')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('skillTreeV2MenuSuggestImprovement')),
        findsOneWidget,
      );
    },
  );
}
