import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart'
    as auth;
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/App/Routes/routes.dart';
import 'package:horseandriderscompanion/App/View/app.dart';
import 'package:horseandriderscompanion/Settings/settings_controller.dart';
import 'package:horseandriderscompanion/Settings/settings_service.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthenticationRepository extends Mock
    implements auth.AuthenticationRepository {}

class MockMessagesRepository extends Mock implements MessagesRepository {}

class MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class MockResourcesRepository extends Mock implements ResourcesRepository {}

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

void main() {
  testWidgets('Shows email verification dialog when user not verified',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final settings = SettingsController(SettingsService());
    await settings.loadSettings();

    final authRepo = MockAuthenticationRepository();
    final messagesRepo = MockMessagesRepository();
    final skillRepo = MockSkillTreeRepository();
    final resourcesRepo = MockResourcesRepository();
    final riderRepo = MockRiderProfileRepository();
    final horseRepo = MockHorseProfileRepository();

    final ctrl = StreamController<auth.User?>.broadcast();
    when(() => authRepo.currentUser).thenReturn(auth.User.empty);
    when(() => authRepo.user).thenAnswer((_) => ctrl.stream);
    when(skillRepo.getSkills).thenAnswer((_) => Stream.value(<Skill>[]));
    when(skillRepo.getAllTrainingPaths)
        .thenAnswer((_) => Stream.value(<TrainingPath>[]));
    when(resourcesRepo.getResources)
        .thenAnswer((_) => Stream.value(<Resource>[]));

    final appCubit = AppCubit(
      messagesRepository: messagesRepo,
      skillTreeRepository: skillRepo,
      resourcesRepository: resourcesRepo,
      horseProfileRepository: horseRepo,
      riderProfileRepository: riderRepo,
      authenticationRepository: authRepo,
    );

    final router =
        Routes().router(settingsContoller: settings, appCubit: appCubit);

    Widget build() => MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: messagesRepo),
            RepositoryProvider.value(value: skillRepo),
            RepositoryProvider.value(value: resourcesRepo),
            RepositoryProvider.value(value: riderRepo),
            RepositoryProvider.value(value: horseRepo),
            RepositoryProvider<auth.AuthenticationRepository>.value(
              value: authRepo,
            ),
          ],
          child: BlocProvider.value(
            value: appCubit,
            child: AppView(settingsController: settings, router: router),
          ),
        );

    await tester.pumpWidget(build());
    await tester.pump();

    // Start unauthenticated
    ctrl.add(null);
    await tester.pump(const Duration(milliseconds: 100));

    // Emit a not-verified user
    ctrl.add(
      const auth.User(
        id: 'u1',
        name: 'U',
        email: 'u@x.com',
        isGuest: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Allow pushNamed scheduled on post-frame
    await tester.pump(const Duration(milliseconds: 400));

    // Dialog route pushed and visible
    expect(find.text('Email Verification Needed'), findsOneWidget);

    await ctrl.close();
    await appCubit.close();
  });
}
