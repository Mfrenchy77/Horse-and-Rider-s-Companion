import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_controller_scope.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Settings/skill_tree_layout.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuth extends Mock implements AuthenticationRepository {}

class MockSkills extends Mock implements SkillTreeRepository {}

class MockResources extends Mock implements ResourcesRepository {}

class MockMessages extends Mock implements MessagesRepository {}

class MockRiders extends Mock implements RiderProfileRepository {}

class MockHorses extends Mock implements HorseProfileRepository {}

void main() {
  late AppCubit cubit;
  late SettingsController settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    settings = SettingsController(SettingsService());
    await settings.loadSettings();
    final auth = MockAuth();
    final skills = MockSkills();
    final resources = MockResources();
    when(() => auth.currentUser).thenReturn(User.empty);
    when(() => auth.user).thenAnswer((_) => const Stream.empty());
    when(skills.getSkills).thenAnswer((_) => const Stream.empty());
    when(resources.getResources).thenAnswer((_) => const Stream.empty());
    // Intentionally do not stub training paths: startup must not request them.
    cubit = AppCubit(
      authenticationRepository: auth,
      skillTreeRepository: skills,
      resourcesRepository: resources,
      messagesRepository: MockMessages(),
      riderProfileRepository: MockRiders(),
      horseProfileRepository: MockHorses(),
    );
  });

  tearDown(() {
    settings.dispose();
    return cubit.close();
  });

  Widget app(SkillTreeLayout layout) => MaterialApp(
    home: SettingsControllerScope(
      controller: settings,
      child: SkillTreeLayoutScope(
        layout: layout,
        child: BlocProvider.value(value: cubit, child: const SkillTreeView()),
      ),
    ),
  );

  testWidgets('overflow menu changes and persists the Skill Tree layout', (
    tester,
  ) async {
    cubit.emit(cubit.state.copyWith(skillTreeTabIndex: 0));
    await tester.pumpWidget(app(SkillTreeLayout.library));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('Skill Tree layout'), findsOneWidget);
    expect(find.text('Skill library'), findsOneWidget);
    expect(find.text('Expand in place'), findsOneWidget);
    expect(find.text('Progress board'), findsOneWidget);

    final progressBoard = find.byKey(
      const ValueKey('skillTreeLayout-progressBoard'),
    );
    await tester.ensureVisible(progressBoard);
    await tester.tap(progressBoard);
    await tester.pumpAndSettle();
    expect(settings.skillTreeLayout, SkillTreeLayout.progressBoard);

    final restored = SettingsController(SettingsService());
    await restored.loadSettings();
    expect(restored.skillTreeLayout, SkillTreeLayout.progressBoard);
    restored.dispose();
  });

  for (final layout in SkillTreeLayout.values) {
    for (final width in [390.0, 1280.0]) {
      testWidgets(
        '${layout.label} opens skill details and resources at $width',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 900);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final skill = Skill(
            id: 'leading',
            rider: true,
            position: 0,
            skillName: 'Lead at the walk',
            difficulty: DifficultyState.Intermediate,
            category: SkillCategory.In_Hand,
            lastEditBy: 'editor',
            lastEditDate: DateTime.utc(2025),
            description: 'Lead on a loose rope.',
            learningDescription: 'Practice a calm halt.',
            proficientDescription: 'Change direction with light cues.',
          );
          cubit.emit(
            cubit.state.copyWith(
              isForRider: true,
              allSkills: [skill],
              sortedSkills: [skill],
              hasResourceCatalogue: true,
              resources: [
                Resource(
                  id: 'linked',
                  name: 'Leading practice guide',
                  skillTreeIds: ['leading'],
                ),
                Resource(
                  id: 'other',
                  name: 'Unlinked article',
                  skillTreeIds: ['other'],
                ),
              ],
            ),
          );
          await tester.pumpWidget(app(layout));
          await tester.pumpAndSettle();
          expect(
            find.byKey(
              Key(switch (layout) {
                SkillTreeLayout.library =>
                  width < 740 ? 'skillLibraryCompact' : 'skillLibraryWide',
                SkillTreeLayout.expandInPlace => 'skillExpandInPlace',
                SkillTreeLayout.progressBoard => 'skillProgressBoard',
              }),
            ),
            findsOneWidget,
          );
          expect(find.byType(TabBar), findsNothing);
          expect(find.text('Training Paths'), findsNothing);
          expect(
            find.byKey(const Key('createTrainingPathButton')),
            findsNothing,
          );
          expect(find.text('Intermediate'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('library-skill-leading')));
          await tester.pumpAndSettle();
          expect(find.text('Lead on a loose rope.'), findsOneWidget);
          expect(find.text('Practice a calm halt.'), findsOneWidget);
          expect(find.text('In Hand · Intermediate'), findsOneWidget);
          final row = tester.getRect(
            find.byKey(const ValueKey('library-skill-leading')),
          );
          final detail = tester.getRect(find.text('Lead on a loose rope.'));
          if (layout == SkillTreeLayout.library && width >= 740) {
            expect(detail.left, greaterThan(row.right));
          } else {
            expect(detail.top, greaterThan(row.bottom));
          }
          expect(find.text('Leading practice guide'), findsOneWidget);
          expect(find.text('Unlinked article'), findsNothing);
          expect(
            find.byKey(const ValueKey('library-skill-leading')),
            findsOneWidget,
          );
          await tester.tap(find.text('Close details'));
          await tester.pumpAndSettle();
          expect(find.text('Lead on a loose rope.'), findsNothing);
          expect(
            find.byKey(const ValueKey('library-skill-leading')),
            findsOneWidget,
          );
          final difficulty = find.byType(
            DropdownButtonFormField<DifficultySortState>,
          );
          await tester.ensureVisible(difficulty);
          await tester.tap(difficulty);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Advanced').last);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('library-skill-leading')),
            findsNothing,
          );
          await tester.tap(difficulty);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Intermediate').last);
          await tester.pumpAndSettle();
          final tile = find.byKey(const ValueKey('library-skill-leading'));
          expect(tile, findsOneWidget);

          cubit.emit(
            cubit.state.copyWith(
              usersProfile: RiderProfile(
                id: 'rider',
                email: 'rider@example.com',
                name: 'Rider',
                skillLevels: [
                  SkillLevel(
                    skillId: skill.id,
                    skillName: skill.skillName,
                    lastEditBy: null,
                    lastEditDate: null,
                    levelState: LevelState.LEARNING,
                  ),
                ],
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            layout == SkillTreeLayout.progressBoard
                ? find.descendant(
                    of: find.byKey(const ValueKey(LevelState.LEARNING)),
                    matching: tile,
                  )
                : find.descendant(of: tile, matching: find.text('Learning')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
