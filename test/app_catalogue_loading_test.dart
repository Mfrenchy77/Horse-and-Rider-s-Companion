import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_resources_list.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockMessagesRepository extends Mock implements MessagesRepository {}

class _MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class _MockResourcesRepository extends Mock implements ResourcesRepository {}

class _MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class _MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class _MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  late _MockMessagesRepository messages;
  late _MockSkillTreeRepository skills;
  late _MockResourcesRepository resources;
  late _MockRiderProfileRepository riders;
  late _MockHorseProfileRepository horses;
  late _MockAuthenticationRepository auth;

  setUp(() {
    messages = _MockMessagesRepository();
    skills = _MockSkillTreeRepository();
    resources = _MockResourcesRepository();
    riders = _MockRiderProfileRepository();
    horses = _MockHorseProfileRepository();
    auth = _MockAuthenticationRepository();

    when(() => auth.currentUser).thenReturn(User.empty);
    when(() => auth.user).thenAnswer((_) => const Stream<User?>.empty());
    when(
      () => skills.getSkills(),
    ).thenAnswer((_) => const Stream<List<Skill>>.empty());
  });

  test(
    'resources are fetched once when the page requests them, for guests too',
    () async {
      final resource = Resource(id: 'resource-1', name: 'Groundwork guide');
      when(
        () => resources.getResources(),
      ).thenAnswer((_) => Stream.value([resource]));

      final cubit = AppCubit(
        messagesRepository: messages,
        skillTreeRepository: skills,
        resourcesRepository: resources,
        riderProfileRepository: riders,
        horseProfileRepository: horses,
        authenticationRepository: auth,
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isGuest, isTrue);
      verifyNever(() => resources.getResources());

      cubit
        ..changeIndex(2)
        ..changeIndex(2);
      await Future<void>.delayed(Duration.zero);

      verify(() => resources.getResources()).called(1);
      expect(cubit.state.resources, [resource]);
      await cubit.close();
    },
  );

  testWidgets('skill details reuse a loaded catalogue for every linked skill', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final linked = Resource(
      id: 'linked',
      name: 'Linked guide',
      skillTreeIds: ['first', 'second'],
      lastEditDate: DateTime.utc(2024),
    );
    final unrelated = linked.copyWith(id: 'other', skillTreeIds: ['unrelated']);
    when(
      resources.getResources,
    ).thenAnswer((_) => Stream.value([linked, unrelated]));
    when(
      () => resources.getResourcesForSkill(skillId: 'first'),
    ).thenAnswer((_) => Stream.value([linked]));
    final cubit = AppCubit(
      messagesRepository: messages,
      skillTreeRepository: skills,
      resourcesRepository: resources,
      riderProfileRepository: riders,
      horseProfileRepository: horses,
      authenticationRepository: auth,
    );
    addTearDown(cubit.close);

    Future<void> showSkill(String id) => tester.pumpWidget(
      RepositoryProvider<ResourcesRepository>.value(
        value: resources,
        child: BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            home: Scaffold(body: SkillResouresList(skillId: id)),
          ),
        ),
      ),
    );

    await showSkill('first');
    await tester.pump();
    verify(() => resources.getResourcesForSkill(skillId: 'first')).called(1);
    verifyNever(resources.getResources);
    expect(
      tester.widget<ResourcesItem>(find.byType(ResourcesItem)).resource.id,
      'linked',
    );

    cubit.loadResourcesIfNeeded();
    await tester.pump();
    await showSkill('second');
    expect(
      tester.widget<ResourcesItem>(find.byType(ResourcesItem)).resource.id,
      'linked',
    );
    verifyNever(() => resources.getResourcesForSkill(skillId: 'second'));
  });
}
