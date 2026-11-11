import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/skill_level_card.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Guest/Widgets/guest_profile_skills.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateSkillDialog/Cubit/skill_create_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_prerequisite_diagram.dart';
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
  late MockResources resources;
  late MockSkills skills;
  final date = DateTime.utc(2025);
  final rider = RiderProfile(
    id: 'rider',
    name: 'Rider',
    email: 'r@example.com',
  );

  Skill skill({List<String> prerequisites = const ['base']}) => Skill(
    id: 'target',
    skillName: 'Target skill',
    rider: true,
    position: 1,
    lastEditBy: rider.email,
    lastEditDate: date,
    description: 'A skill description',
    learningDescription: 'Practice this skill',
    proficientDescription: 'Perform it independently',
    prerequisites: prerequisites,
  );

  setUpAll(() => registerFallbackValue(skill()));
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final auth = MockAuth();
    skills = MockSkills();
    resources = MockResources();
    when(() => auth.currentUser).thenReturn(User.empty);
    when(() => auth.user).thenAnswer((_) => const Stream.empty());
    when(skills.getSkills).thenAnswer((_) => const Stream.empty());
    when(resources.getResources).thenAnswer((_) => const Stream.empty());
    when(
      () => resources.getResourcesForSkill(skillId: 'target'),
    ).thenAnswer((_) => Stream.value(<Resource>[]));
    cubit = AppCubit(
      authenticationRepository: auth,
      skillTreeRepository: skills,
      resourcesRepository: resources,
      messagesRepository: MockMessages(),
      riderProfileRepository: MockRiders(),
      horseProfileRepository: MockHorses(),
    );
  });
  tearDown(() => cubit.close());

  Widget app(Widget child) => BlocProvider.value(
    value: cubit,
    child: RepositoryProvider<ResourcesRepository>.value(
      value: resources,
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );

  for (final forRider in [true, false]) {
    test(
      'ignores prerequisite checks for ${forRider ? 'riders' : 'horses'}',
      () {
        cubit.emit(
          cubit.state.copyWith(
            isForRider: forRider,
            usersProfile: rider,
            allSkills: [skill()],
          ),
        );
        expect(cubit.hasUnmetPrerequisites('target'), isFalse);
        expect(cubit.hasUnmetPrerequisites('missing'), isFalse);
      },
    );
  }

  for (final prerequisites in [
    <String>[],
    ['base'],
  ]) {
    testWidgets(
      '''
skill details hide prerequisite and base-skill sections for $prerequisites''',
      (tester) async {
        final selected = skill(prerequisites: prerequisites);
        cubit.emit(
          cubit.state.copyWith(
            isGuest: false,
            isForRider: true,
            usersProfile: rider,
            skill: selected,
            allSkills: [selected],
          ),
        );
        await tester.pumpWidget(app(const SkillLevelView(skillId: 'target')));
        await tester.pump();

        expect(find.text('Prerequisites'), findsNothing);
        expect(find.text('Base Skill'), findsNothing);
        expect(find.byType(SkillPrerequisiteDiagram), findsNothing);
        expect(find.text('Target skill'), findsOneWidget);
        expect(find.text('Learning'), findsOneWidget);
        expect(find.text('Proficient'), findsOneWidget);
        expect(find.text('Resources'), findsOneWidget);
        await tester.tap(find.text('Mark as learning'));
        await tester.pumpAndSettle();
        expect(find.text('Confirm Skill Level'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'legacy badge input does not show a warning or block skill taps',
    (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        app(
          Center(
            child: SkillLevelCard(
              hasUnmetPrerequisites: true,
              category: SkillCategory.Mounted,
              difficulty: DifficultyState.Introductory,
              skillLevel: SkillLevel(
                skillId: 'target',
                skillName: 'Target skill',
                lastEditBy: rider.email,
                lastEditDate: date,
              ),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.error_outlined), findsNothing);
      await tester.tap(find.text('Target skill'));
      expect(tapped, isTrue);
    },
  );

  testWidgets('guest example skills do not display prerequisite badges', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const SingleChildScrollView(child: GuestProfileSkills())),
    );
    expect(find.byType(SkillLevelCard), findsWidgets);
    expect(find.byIcon(Icons.error_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final editing in [true, false]) {
    test(
      '''
${editing ? 'editing preserves saved' : 'creating omits'} prerequisite links''',
      () async {
        final original = skill();
        final editor = CreateSkillDialogCubit(
          skill: editing ? original : null,
          allSkills: [original],
          isForRider: true,
          usersProfile: rider,
          skillsRepository: skills,
        );
        addTearDown(editor.close);
        when(
          () => skills.createOrEditSkill(skill: any(named: 'skill')),
        ).thenAnswer((_) async {});
        editor
          ..skillNameChanged('Renamed skill')
          ..emit(editor.state.copyWith(prerequisites: ['disabled-draft-link']));
        if (editing) {
          await editor.editSkill(editedSkill: original);
        } else {
          await editor.createSkill(0);
        }
        final saved =
            verify(
                  () => skills.createOrEditSkill(
                    skill: captureAny(named: 'skill'),
                  ),
                ).captured.single
                as Skill;
        expect(saved.skillName, 'Renamed skill');
        expect(saved.prerequisites, editing ? ['base'] : isEmpty);
        expect(original.prerequisites, ['base']);
      },
    );
  }
}
