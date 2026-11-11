import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_panel.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_repository.dart';
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
}
