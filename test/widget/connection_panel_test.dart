import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_view.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_test_harness.dart';

class _Repository extends Mock implements ConnectionRepository {}

void main() {
  testWidgets(
    'the profile panel exposes incoming actions and accepted coaching',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      const email = 'coach@example.com';
      final rider = RiderProfile(
        id: 'coach',
        email: email,
        name: 'Coach',
        isTrainer: true,
      );
      final stream = StreamController<List<CoachingConnection>>();
      final repo = _Repository();
      when(() => repo.watch('coach')).thenAnswer((_) => stream.stream);
      when(
        () => repo.submit(any()),
      ).thenAnswer((_) async => {'status': 'accepted'});
      final cubit = ConnectionsCubit(repo, harness.cubit);
      addTearDown(() async {
        await cubit.close();
        await stream.close();
      });

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ConnectionRepository>.value(value: repo),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: harness.cubit),
              BlocProvider.value(value: cubit),
            ],
            child: MaterialApp(
              home: Scaffold(body: ConnectionPanel(rider: rider)),
            ),
          ),
        ),
      );
      expect(find.text('Connections and requests'), findsNothing);
      verifyNever(() => repo.watch(any()));

      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          usersProfile: rider,
          user: const User(
            id: 'coach',
            email: email,
            name: 'Coach',
            isGuest: false,
          ),
        ),
      );
      await tester.pump();
      CoachingConnection link(String status) => CoachingConnection('link', {
        'version': 'version',
        'kind': 'rider',
        'status': status,
        'sender': 'student@example.com',
        'recipient': email,
        'learner': 'student@example.com',
        'coach': email,
        'coachName': 'Coach',
        'learnerName': 'Rider',
      });
      stream.add([link('pending')]);
      await tester.pumpAndSettle();
      expect(find.text('Connections and requests (1 new)'), findsOneWidget);
      expect(find.text('Requested by Rider'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Add lesson record'), findsNothing);
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      verify(
        () => repo.submit({
          'action': 'accept',
          'id': 'link',
          'version': 'version',
        }),
      ).called(1);

      stream.add([link('accepted')]);
      await tester.pumpAndSettle();
      expect(find.text('Add lesson record'), findsOneWidget);
      expect(find.text('End connection'), findsOneWidget);
      verify(() => repo.watch('coach')).called(1);
    },
  );
  testWidgets('a recipient can accept a transfer from their profile', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    const email = 'buyer@example.com';
    final rider = RiderProfile(id: 'buyer', email: email, name: 'Buyer');
    harness.cubit.emit(
      harness.cubit.state.copyWith(
        isGuest: false,
        usersProfile: rider,
        user: const User(
          id: 'buyer',
          email: email,
          name: 'Buyer',
          isGuest: false,
        ),
      ),
    );
    final repo = _Repository();
    final stream = StreamController<List<CoachingConnection>>();
    when(() => repo.watch('buyer')).thenAnswer((_) => stream.stream);
    when(
      () => repo.submit(any()),
    ).thenAnswer((_) async => {'status': 'accepted'});
    final connections = ConnectionsCubit(repo, harness.cubit);
    addTearDown(() async {
      await connections.close();
      await stream.close();
    });
    await tester.pumpWidget(
      RepositoryProvider<ConnectionRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: harness.cubit),
            BlocProvider.value(value: connections),
          ],
          child: MaterialApp(
            home: Scaffold(body: ConnectionPanel(rider: rider)),
          ),
        ),
      ),
    );
    final data = {
      'version': 'v1',
      'kind': 'transfer',
      'sender': 'owner@example.com',
      'recipient': email,
      'learner': 'owner@example.com',
      'coach': email,
      'learnerName': 'Owner',
      'coachName': 'Buyer',
      'horseId': 'atlas',
      'horseName': 'Atlas',
    };
    stream.add([
      CoachingConnection('offer', {...data, 'status': 'pending'}),
    ]);
    await tester.pumpAndSettle();
    expect(find.textContaining('Atlas ownership transfer'), findsOneWidget);
    await tester.tap(find.text('Accept transfer'));
    await tester.pumpAndSettle();
    verify(
      () => repo.submit({
        'action': 'accept',
        'id': 'offer',
        'version': 'v1',
        'transfer': true,
      }),
    ).called(1);
    stream.add([
      CoachingConnection('offer', {...data, 'status': 'accepted'}),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Ownership transferred.'), findsOneWidget);
    expect(find.text('Add training record'), findsNothing);
  });
  testWidgets(
    'selected student skill verifies without opening the lesson editor',
    (tester) async {
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);
      const coach = 'coach@example.com';
      const learner = 'student@example.com';
      final app = harness.cubit;
      final skill = Skill(
        id: 'leading',
        rider: true,
        position: 0,
        skillName: 'Lead at the walk',
        lastEditBy: null,
        lastEditDate: null,
        description: null,
        learningDescription: null,
        proficientDescription: null,
      );
      app.emit(
        app.state.copyWith(
          isGuest: false,
          isViewing: true,
          isForRider: true,
          index: 1,
          pageStatus: AppPageStatus.skillTree,
          user: const User(id: 'coach', email: coach, name: 'Coach'),
          usersProfile: RiderProfile(id: 'coach', email: coach, name: 'Coach'),
          viewingProfile: RiderProfile(
            id: 'student',
            email: learner,
            name: 'Testy',
          ),
          skill: skill,
          allSkills: [skill],
        ),
      );
      final updated = app.state.viewingProfile!.copyWith(
        skillLevels: [
          SkillLevel(
            skillId: skill.id,
            skillName: skill.skillName,
            verified: true,
            lastEditBy: coach,
            lastEditDate: DateTime.utc(2026),
            levelState: LevelState.PROFICIENT,
          ),
        ],
      );
      var persisted = app.state.viewingProfile!;
      when(
        () => harness.riders.getRiderProfileByEmail(
          email: learner,
          serverOnly: true,
        ),
      ).thenAnswer((_) async => persisted);
      final repo = _Repository();
      final links = StreamController<List<CoachingConnection>>();
      when(() => repo.watch('coach')).thenAnswer((_) => links.stream);
      when(() => repo.submit(any())).thenAnswer((_) async {
        persisted = updated;
        return {'verified': true};
      });
      when(
        () => harness.resources.getResourcesForSkill(skillId: skill.id),
      ).thenAnswer((_) => const Stream.empty());
      final connections = ConnectionsCubit(repo, app);
      addTearDown(() async {
        await connections.close();
        await links.close();
      });
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ConnectionRepository>.value(value: repo),
            RepositoryProvider<RiderProfileRepository>.value(
              value: harness.riders,
            ),
            RepositoryProvider<ResourcesRepository>.value(
              value: harness.resources,
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: app),
              BlocProvider.value(value: connections),
            ],
            child: MaterialApp(
              home: Scaffold(body: SkillLevelView(skillId: skill.id)),
            ),
          ),
        ),
      );
      expect(find.text('Verify as proficient'), findsNothing);
      links.add([
        CoachingConnection('link', {
          'kind': 'rider',
          'status': 'accepted',
          'version': 'v1',
          'coach': coach,
          'coachName': 'Coach',
          'learner': learner,
          'learnerName': 'Testy',
          'sender': learner,
          'recipient': coach,
        }),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Progress · Testy'), findsOneWidget);
      await tester.tap(find.text('Verify as proficient'));
      await tester.pumpAndSettle();
      expect(find.text('Verify skill'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tester.tap(find.text('Confirm verification'));
      await tester.pumpAndSettle();
      final payload =
          verify(() => repo.submit(captureAny())).captured.single
              as Map<String, Object?>;
      expect(payload['action'], 'verifySkill');
      expect(payload['skillId'], skill.id);
      expect(payload['level'], 'PROFICIENT');
      expect(payload.containsKey('notes'), isFalse);

      expect(find.byType(SkillLevelView), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(app.state.index, 1);
      expect(app.state.pageStatus, AppPageStatus.skillTree);
      expect(app.state.skill?.id, skill.id);
    },
  );
}
