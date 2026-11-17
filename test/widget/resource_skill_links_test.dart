import 'dart:async';

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resource_comment_page.dart';
import 'package:horseandriderscompanion/MainPages/Resources/resources_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_page.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/asset_curriculum_v2_loader.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_harness.dart';

void main() {
  late SkillTreeV2Repository v2Repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final v2Store = await const AssetCurriculumV2Loader().loadInMemoryStore();
    v2Repo = SkillTreeV2Repository(store: v2Store);
  });
  testWidgets('empty associated skills show a single message', (tester) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final app = harness.cubit;

    for (final ids in [<String>[], ['missing-skill']]) {
      final resource = Resource(
        id: 'guide',
        name: 'Leading guide',
        skillTreeIds: ids,
      );
      app.emit(
        app.state.copyWith(
          isGuest: true,
          resource: resource,
          resources: [resource],
        ),
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: app,
          child: MaterialApp(
            theme: mainThemeDark,
            home: const ResourceCommentPage(id: 'guide'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Associated skills').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          ids.isEmpty
              ? 'No associated skills yet.'
              : 'No associated skills to display.',
        ),
        findsOneWidget,
      );
      expect(find.text('Linked skills'), findsNothing);
      expect(find.byKey(const Key('manageSkillLinksButton')), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('comments dialog displays an already associated skill', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    const email = 'owner@example.com';
    final resource = Resource(
      id: 'guide',
      name: 'Leading guide',
      authorId: email,
      skillTreeIds: ['leading'],
    );
    final skill = Skill(
      id: 'leading',
      rider: true,
      position: 0,
      skillName: 'Lead at the walk',
      lastEditBy: 'editor',
      lastEditDate: DateTime.utc(2025),
      description: '',
      learningDescription: '',
      proficientDescription: '',
    );
    final app = harness.cubit;
    app.emit(
      app.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(id: 'owner', email: email, name: 'Owner'),
        allSkills: [skill],
        resource: resource,
        resources: [resource],
      ),
    );
    await tester.pumpWidget(
      RepositoryProvider<ResourcesRepository>.value(
        value: harness.resources,
        child: BlocProvider.value(
          value: app,
          child: MaterialApp(
            theme: mainThemeDark,
            home: const ResourceCommentPage(id: 'guide'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Associated skills').last);
    await tester.pump();
    final surface = find.byType(AppGlassSurface);
    expect(surface, findsOneWidget);
    expect(
      find.ancestor(of: surface, matching: find.byType(ScaleTransition)),
      findsOneWidget,
    );
    await tester.pumpAndSettle();

    final linkedRow = find.ancestor(
      of: find.descendant(of: surface, matching: find.byIcon(Icons.link)),
      matching: find.byType(ListTile),
    );
    expect(tester.widget<ListTile>(linkedRow).onTap, isNotNull);
    expect(
      find.descendant(of: linkedRow, matching: find.text('Lead at the walk')),
      findsOneWidget,
    );
    // Starts in compact read-only state (editing controls hidden).
    expect(find.text('Search skills'), findsNothing);
    expect(find.byKey(const ValueKey('resource-skill-leading')), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Update'), findsNothing);
    expect(find.byKey(const Key('manageSkillLinksButton')), findsOneWidget);

    // Selecting Manage Links reveals editing controls.
    await tester.tap(find.byKey(const Key('manageSkillLinksButton')));
    await tester.pumpAndSettle();

    final link = find.byKey(const ValueKey('resource-skill-leading'));
    expect(link, findsOneWidget);
    expect(
      find.descendant(of: link, matching: find.text('Lead at the walk')),
      findsOneWidget,
    );
    expect(tester.widget<CheckboxListTile>(link).value, isTrue);

    // Done returns to the compact read-only state.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('resource-skill-leading')), findsNothing);
    expect(find.byKey(const Key('manageSkillLinksButton')), findsOneWidget);
  });

  testWidgets('resource owner can link a skill from the comments dialog', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    const email = 'owner@example.com';
    final resource = Resource(
      id: 'guide',
      name: 'Leading guide',
      authorId: email,
    );
    final skill = Skill(
      id: 'leading',
      rider: true,
      position: 0,
      skillName: 'Lead at the walk',
      lastEditBy: 'editor',
      lastEditDate: DateTime.utc(2025),
      description: '',
      learningDescription: '',
      proficientDescription: '',
    );
    final app = harness.cubit;
    app.emit(
      app.state.copyWith(
        isGuest: false,
        usersProfile: RiderProfile(id: 'owner', email: email, name: 'Owner'),
        allSkills: [skill],
        resource: resource,
        resources: [resource],
      ),
    );
    when(
      () => harness.resources.updateSkillLinks(
        id: 'guide',
        added: any(named: 'added'),
        removed: any(named: 'removed'),
      ),
    ).thenAnswer((invocation) async {
      final links = invocation.namedArguments[#added] as Set<String>;
      final updated = resource.copyWith(skillTreeIds: links.toList());
      app.emit(app.state.copyWith(resource: updated, resources: [updated]));
    });
    await tester.pumpWidget(
      RepositoryProvider<ResourcesRepository>.value(
        value: harness.resources,
        child: BlocProvider.value(
          value: app,
          child: const MaterialApp(home: ResourceCommentPage(id: 'guide')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Associated skills').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manageSkillLinksButton')));
    await tester.pumpAndSettle();
    final update = find.widgetWithText(FilledButton, 'Update');
    expect(tester.widget<FilledButton>(update).onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'lead');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resource-skill-leading')));
    await tester.pumpAndSettle();
    await tester.tap(update);
    await tester.pumpAndSettle();

    verify(
      () => harness.resources.updateSkillLinks(
        id: 'guide',
        added: {'leading'},
        removed: {},
      ),
    ).called(1);
    expect(find.text('Associated skills'), findsNothing);
    expect(app.state.resource?.skillTreeIds, ['leading']);
  });

  testWidgets('resource skill links open details in the cached Skill Tree', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final settings = SettingsController(SettingsService());
    addTearDown(settings.dispose);
    await settings.loadSettings();
    final app = harness.cubit;
    final router = Routes().router(settingsContoller: settings, appCubit: app);
    addTearDown(router.dispose);
    final resource = Resource(
      id: 'guide',
      name: 'Leading guide',
      skillTreeIds: ['rider.in_hand.leading'],
    );
    final skill = Skill(
      id: 'rider.in_hand.leading',
      rider: true,
      position: 0,
      skillName: 'Leading',
      lastEditBy: null,
      lastEditDate: null,
      description: 'Linked skill description',
      learningDescription: '',
      proficientDescription: '',
    );
    app.emit(
      app.state.copyWith(
        isGuest: true,
        allSkills: [skill],
        resources: [resource],
        resource: resource,
      ),
    );

    when(
      () => harness.resources.getResourcesForSkill(
        skillId: any(named: 'skillId'),
      ),
    ).thenAnswer((_) => const Stream.empty());
    router.goNamed(SkillTreePage.name);
    await tester.pumpWidget(
      SettingsControllerScope(
        controller: settings,
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ResourcesRepository>.value(
              value: harness.resources,
            ),
            RepositoryProvider<SkillTreeV2Repository>.value(value: v2Repo),
          ],
          child: BlocProvider.value(
            value: app,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    router.goNamed(ResourcesPage.name);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.widgetWithText(ActionChip, skill.skillName));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    void expectSkillOpen() {
      final uri = router.routeInformationProvider.value.uri;
      expect(uri.path, SkillTreePage.path);
      expect(uri.queryParameters['skillId'], skill.id);
      expect(find.byKey(Key('skillDetailV2_${skill.id}')), findsOneWidget);
    }

    expectSkillOpen();
    router.goNamed(ResourcesPage.name);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    unawaited(
      router.pushNamed<void>(
        ResourceCommentPage.name,
        pathParameters: {ResourceCommentPage.pathParams: 'guide'},
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('Associated skills').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.widgetWithText(ListTile, skill.skillName));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expectSkillOpen();
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets(
    'unauthorized viewer cannot access Manage Links and owner can cancel '
    'or remove links from three-dot menu',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      final resource = Resource(
        id: 'guide',
        name: 'Leading guide',
        authorId: 'owner@example.com',
        skillTreeIds: ['leading'],
      );
      final skill = Skill(
        id: 'leading',
        rider: true,
        position: 0,
        skillName: 'Lead at the walk',
        lastEditBy: 'editor',
        lastEditDate: DateTime.utc(2025),
        description: '',
        learningDescription: '',
        proficientDescription: '',
      );
      final app = harness.cubit;
      app.emit(
        app.state.copyWith(
          isGuest: false,
          usersProfile: RiderProfile(
            id: 'viewer',
            email: 'viewer@example.com',
            name: 'Viewer',
          ),
          allSkills: [skill],
          resource: resource,
          resources: [resource],
        ),
      );
      when(
        () => harness.resources.updateSkillLinks(
          id: 'guide',
          added: any(named: 'added'),
          removed: any(named: 'removed'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        RepositoryProvider<ResourcesRepository>.value(
          value: harness.resources,
          child: BlocProvider.value(
            value: app,
            child: const MaterialApp(home: ResourceCommentPage(id: 'guide')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unauthorized user does not see Edit Resource or Manage Skill Links.
      await tester.tap(
        find.byKey(const Key('resourceOverflowMenu_guide')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit Resource'), findsNothing);
      expect(find.text('Manage Skill Links'), findsNothing);
      expect(find.text('Report'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Unauthorized user sees compact read-only dialog with no Manage Links.
      await tester.tap(find.byTooltip('Associated skills').last);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ListTile, 'Lead at the walk'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('manageSkillLinksButton')), findsNothing);
      expect(find.text('Search skills'), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Switch to resource owner: overflow menu exposes Edit Resource (not
      // Manage Skill Links), and Associated skills dialog exposes Manage Links.
      app.emit(
        app.state.copyWith(
          usersProfile: RiderProfile(
            id: 'owner',
            email: 'owner@example.com',
            name: 'Owner',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('resourceOverflowMenu_guide')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit Resource'), findsOneWidget);
      expect(find.text('Manage Skill Links'), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Associated skills').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('manageSkillLinksButton')));
      await tester.pumpAndSettle();

      // Uncheck skill, then Cancel returns to compact view without saving.
      final skillCheckbox = find.byKey(
        const ValueKey('resource-skill-leading'),
      );
      await tester.ensureVisible(skillCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(skillCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('manageSkillLinksButton')), findsOneWidget);
      verifyNever(
        () => harness.resources.updateSkillLinks(
          id: any(named: 'id'),
          added: any(named: 'added'),
          removed: any(named: 'removed'),
        ),
      );

      // Re-enter Manage Links, remove link, and Update.
      await tester.tap(find.byKey(const Key('manageSkillLinksButton')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(skillCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(skillCheckbox);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Update'));
      await tester.pumpAndSettle();

      verify(
        () => harness.resources.updateSkillLinks(
          id: 'guide',
          added: {},
          removed: {'leading'},
        ),
      ).called(1);
    },
  );
}
