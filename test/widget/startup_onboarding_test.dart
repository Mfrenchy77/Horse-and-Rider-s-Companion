// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/onboarding_dialog.dart';
import 'package:mocktail/mocktail.dart';

class MockMessagesRepository extends Mock implements MessagesRepository {}

class MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class MockResourcesRepository extends Mock implements ResourcesRepository {}

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

class TestAppCubit extends AppCubit {
  TestAppCubit({
    required super.messagesRepository,
    required super.skillTreeRepository,
    required super.resourcesRepository,
    required super.riderProfileRepository,
    required super.horseProfileRepository,
    required super.authenticationRepository,
  });

  Map<String, String>? lastProfileData;

  @override
  Future<void> completeProfileFromOnboarding(Map<String, String> data) async {
    // Record the data and mark onboarding complete in state
    // (no repository calls here)
    lastProfileData = Map.from(data);
    final profile = RiderProfile(
      id: data['email'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
    emit(
      state.copyWith(
        usersProfile: profile,
        isProfileSetup: true,
        showOnboarding: false,
      ),
    );
  }
}

void main() {
  testWidgets(
      'Onboarding dialog shown on startup and completing profile calls cubit',
      (tester) async {
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

    final cubit = TestAppCubit(
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
                    await showDialog<Map<String, String>?>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => OnboardingDialog(
                        onProfileComplete: cubit.completeProfileFromOnboarding,
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

    // Trigger onboarding presentation
    cubit.emit(cubit.state.copyWith(showOnboarding: true));
    await tester.pumpAndSettle();

    // Dialog should be shown
    expect(find.byKey(const Key('onboarding_dialog')), findsOneWidget);

    // Switch to Signed In tab and tap Complete Profile
    await tester.tap(find.text('Signed In'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('onboarding_complete_profile_button')),
      findsOneWidget,
    );
    await tester
        .tap(find.byKey(const Key('onboarding_complete_profile_button')));
    await tester.pumpAndSettle();

    // Complete profile dialog should appear
    expect(find.byKey(const Key('complete_profile_dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('complete_profile_name')),
      'Startup User',
    );
    await tester.enterText(
      find.byKey(const Key('complete_profile_email')),
      'startup@example.com',
    );
    await tester.tap(find.byKey(const Key('complete_profile_save')));
    await tester.pumpAndSettle();

    // Our TestAppCubit should have recorded the
    // profile data and onboarding cleared
    expect(cubit.lastProfileData, isNotNull);
    expect(cubit.lastProfileData!['name'], 'Startup User');
    expect(cubit.lastProfileData!['email'], 'startup@example.com');
    expect(cubit.state.showOnboarding, isFalse);
    expect(cubit.state.isProfileSetup, isTrue);
  });
}
