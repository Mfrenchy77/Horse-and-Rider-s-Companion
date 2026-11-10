import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:mocktail/mocktail.dart';

import 'support/app_test_harness.dart';

void main() {
  testWidgets('verification and sign-out transition the same session safely', (
    tester,
  ) async {
    final harness = await AppTestHarness.create();
    addTearDown(harness.close);
    final authEvents = StreamController<User>();
    final profileEvents = StreamController<RiderProfile?>();
    final conversations = StreamController<List<Conversation>>();
    final reload = Completer<void>();
    addTearDown(authEvents.close);
    addTearDown(profileEvents.close);
    addTearDown(conversations.close);
    const email = 'rider@example.com';
    const unverified = User(
      id: 'rider',
      email: email,
      name: '',
      isGuest: false,
    );
    const verified = User(
      id: 'rider',
      email: email,
      name: 'Rider',
      isGuest: false,
      emailVerified: true,
    );
    when(() => harness.auth.user).thenAnswer((_) => authEvents.stream);
    when(harness.auth.reloadCurrentUser).thenAnswer((_) => reload.future);
    when(
      () => harness.riders.getRiderProfile(email: email),
    ).thenAnswer((_) => profileEvents.stream);
    when(
      () => harness.messages.getConversations(userEmail: email),
    ).thenAnswer((_) => conversations.stream);
    final resource = Resource(id: 'guide');
    when(
      harness.resources.getResources,
    ).thenAnswer((_) => Stream.value([resource]));

    final cubit = AppCubit(
      authenticationRepository: harness.auth,
      messagesRepository: harness.messages,
      skillTreeRepository: harness.skills,
      resourcesRepository: harness.resources,
      riderProfileRepository: harness.riders,
      horseProfileRepository: harness.horses,
    );
    addTearDown(cubit.close);
    cubit.loadResourcesIfNeeded();
    authEvents.add(unverified);
    await tester.pump();
    expect(cubit.state.showEmailVerification, isTrue);
    expect(cubit.state.isGuest, isTrue);
    verifyNever(() => harness.riders.getRiderProfile(email: email));

    await tester.pump(const Duration(seconds: 20));
    verify(harness.auth.reloadCurrentUser).called(1);
    authEvents
      ..add(verified)
      ..add(verified);
    reload.complete();
    await tester.pump();
    expect(cubit.state.showEmailVerification, isFalse);
    expect(cubit.state.user, verified);
    verify(() => harness.riders.getRiderProfile(email: email)).called(1);

    profileEvents.add(RiderProfile(id: 'rider', email: email, name: 'Rider'));
    await tester.pump();
    expect(cubit.state.status, AppStatus.authenticated);
    cubit
      ..getConversations()
      ..getConversations();
    verify(() => harness.messages.getConversations(userEmail: email)).called(1);

    when(harness.auth.logOut).thenThrow(LogOutFailure());
    await cubit.logOutRequested();
    expect(cubit.state.usersProfile?.email, email);

    authEvents.add(User.empty);
    await tester.pump(const Duration(seconds: 10));
    verifyNever(harness.auth.reloadCurrentUser);
    expect(cubit.state.isGuest, isTrue);
    expect(cubit.state.user, User.empty);
    expect(cubit.state.usersProfile, isNull);
    expect(cubit.state.resources, [resource]);
    expect(profileEvents.hasListener, isFalse);
    expect(conversations.hasListener, isFalse);
  });
}
