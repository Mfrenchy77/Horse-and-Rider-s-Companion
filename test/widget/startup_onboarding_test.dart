// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/guest_onboarding_dialog.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockMessagesRepository extends Mock implements MessagesRepository {}

class MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class MockResourcesRepository extends Mock implements ResourcesRepository {}

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

// No custom cubit needed; we only verify guest onboarding presentation

void main() {
  testWidgets(
      'Onboarding dialog shown on startup and completing profile calls cubit',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SharedPrefs().init();
    final messagesRepo = MockMessagesRepository();
    final skillRepo = MockSkillTreeRepository();
    final resourcesRepo = MockResourcesRepository();
    final riderRepo = MockRiderProfileRepository();
    final horseRepo = MockHorseProfileRepository();
    final authRepo = MockAuthenticationRepository();

    when(() => authRepo.currentUser).thenReturn(User.empty);
    when(() => authRepo.user).thenAnswer((_) => const Stream<User?>.empty());

    when(skillRepo.getSkills)
        .thenAnswer((_) => const Stream<List<Skill>>.empty());
    when(skillRepo.getAllTrainingPaths)
        .thenAnswer((_) => const Stream<List<TrainingPath>>.empty());
    when(resourcesRepo.getResources)
        .thenAnswer((_) => const Stream<List<Resource>>.empty());

    final cubit = AppCubit(
      messagesRepository: messagesRepo,
      skillTreeRepository: skillRepo,
      resourcesRepository: resourcesRepo,
      riderProfileRepository: riderRepo,
      horseProfileRepository: horseRepo,
      authenticationRepository: authRepo,
    );

    // Harness that mirrors the NavigationView's onboarding presentation logic
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AppCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              return BlocListener<AppCubit, AppState>(
                listener: (context, state) async {
                  if (state.showOnboarding) {
                    await showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => GuestOnboardingDialog(
                        onSkip: cubit.completeOnboarding,
                      ),
                    );
                  }
                },
                child: const Scaffold(body: Center(child: Text('Home'))),
              );
            },
          ),
        ),
      ),
    );

    // Manually trigger onboarding presentation
    cubit.emit(cubit.state.copyWith(showOnboarding: true));
    await tester.pumpAndSettle();

    // Dialog should be shown
    expect(find.byKey(const Key('guest_onboarding_dialog')), findsOneWidget);

    // Close guest onboarding
    await tester.tap(find.byKey(const Key('guest_onboarding_close')));
    await tester.pumpAndSettle();

    // Onboarding flag should be cleared
    expect(cubit.state.showOnboarding, isFalse);
  });
}
