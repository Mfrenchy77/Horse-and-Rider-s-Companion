import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/skill_tree_view.dart';
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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
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

  tearDown(() => cubit.close());

  Widget app({String? skillId}) => MaterialApp(
    home: BlocProvider.value(
      value: cubit,
      child: SkillTreeView(skillId: skillId),
    ),
  );

  for (final width in [800.0, 1280.0]) {
    testWidgets('shows only skill tabs at width $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app());
      await tester.pump();

      final tabs = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabs.tabs, hasLength(width < 1024 ? 2 : 1));
      expect(find.widgetWithText(Tab, 'Skills'), findsOneWidget);
      expect(
        find.widgetWithText(Tab, 'Detail'),
        width < 1024 ? findsOneWidget : findsNothing,
      );
      expect(find.text('Training Paths'), findsNothing);
      expect(find.text('Path Detail'), findsNothing);
      expect(find.byKey(const Key('createTrainingPathButton')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('resizes skill detail across the split-view breakpoint', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(skillId: 'selected-skill'));
    await tester.pump();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);

    tester.view.physicalSize = const Size(1280, 900);
    await tester.pump();
    expect(tester.widget<TabBar>(find.byType(TabBar)).tabs, hasLength(1));
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);

    tester.view.physicalSize = const Size(500, 900);
    await tester.pump();
    expect(tester.widget<TabBar>(find.byType(TabBar)).tabs, hasLength(2));
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('old training-path tab indices safely fall back to skills', (
    tester,
  ) async {
    cubit.setSkillTreeTabIndex(3);
    await tester.pumpWidget(app());
    await tester.pump();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);

    cubit.setSkillTreeTabIndex(2);
    await tester.pumpAndSettle();
    expect(tester.widget<TabBar>(find.byType(TabBar)).controller!.index, 0);
    expect(tester.takeException(), isNull);
  });
}
