import 'dart:async';

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

  test(
    'linking a resource updates the catalogue and selected comments view',
    () async {
      final snapshots = StreamController<List<Resource>>();
      when(resources.getResources).thenAnswer((_) => snapshots.stream);
      final cubit = AppCubit(
        messagesRepository: messages,
        skillTreeRepository: skills,
        resourcesRepository: resources,
        riderProfileRepository: riders,
        horseProfileRepository: horses,
        authenticationRepository: auth,
      );
      addTearDown(() async {
        await cubit.close();
        await snapshots.close();
      });
      Resource resource(List<String> skillIds) => Resource(
        id: 'guide',
        name: 'Leading guide',
        skillTreeIds: skillIds,
        lastEditDate: DateTime.utc(2025),
        comments: [
          Comment(
            id: 'comment',
            user: BaseListItem(id: 'rider', name: 'Rider'),
            date: DateTime.utc(2025),
            rating: null,
            comment: 'Helpful guide',
            parentId: null,
            editedDate: null,
            resourceId: 'guide',
            usersWhoRated: null,
          ),
        ],
      );
      Future<void> publish(Resource snapshot) async {
        snapshots.add([snapshot]);
        await Future<void>.delayed(Duration.zero);
      }

      cubit.setResource();
      final original = resource([]);
      await publish(original);
      cubit.getResourceById('guide');
      await publish(resource([]));
      expect(cubit.state.resources.single, same(original));

      final linked = resource(['leading']);
      await publish(linked);
      expect(cubit.state.resources.single.skillTreeIds, ['leading']);
      expect(cubit.state.resource, same(linked));
      expect(cubit.state.resourceComments.single.comment, 'Helpful guide');

      await publish(resource([]));
      expect(cubit.state.resource?.skillTreeIds, isEmpty);
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
    final linkedResources = StreamController<List<Resource>>();
    addTearDown(linkedResources.close);
    when(
      () => resources.getResourcesForSkill(skillId: 'first'),
    ).thenAnswer((_) => linkedResources.stream);
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
            home: Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [SkillResouresList(skillId: id)],
              ),
            ),
          ),
        ),
      ),
    );

    await showSkill('first');
    final indicator = find.byType(CircularProgressIndicator);
    expect(tester.getSize(indicator), const Size.square(24));
    linkedResources.add([linked]);
    await tester.pump();
    expect(indicator, findsNothing);
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
