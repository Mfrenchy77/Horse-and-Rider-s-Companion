import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class MockMessagesRepository extends Mock implements MessagesRepository {}

class MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class MockResourcesRepository extends Mock implements ResourcesRepository {}

class MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

class RiderProfileFake extends Fake implements RiderProfile {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SharedPrefs().init();
    registerFallbackValue(RiderProfileFake());
  });

  test('SharedPrefs onboarding default true and set false', () async {
    final prefs = SharedPrefs();
    await prefs.init();
    expect(prefs.showOnboarding(), isTrue);
    prefs.setShowOnboarding(show: false);
    expect(prefs.showOnboarding(), isFalse);
  });

  test('AppCubit.completeProfileFromOnboarding saves profile and updates state',
      () async {
    final riderRepo = MockRiderProfileRepository();
    final messagesRepo = MockMessagesRepository();
    final skillRepo = MockSkillTreeRepository();
    final resourcesRepo = MockResourcesRepository();
    final horseRepo = MockHorseProfileRepository();
    final authRepo = MockAuthenticationRepository();

    // stub stream-returning repository methods so
    // AppCubit can listen without error
    when(skillRepo.getSkills)
        .thenAnswer((_) => const Stream<List<Skill>>.empty());
    when(skillRepo.getAllTrainingPaths)
        .thenAnswer((_) => const Stream<List<TrainingPath>>.empty());
    when(resourcesRepo.getResources)
        .thenAnswer((_) => const Stream<List<Resource>>.empty());

    when(() => authRepo.currentUser).thenReturn(User.empty);
    when(() => authRepo.user).thenAnswer((_) => const Stream<User?>.empty());
    when(
      () => riderRepo.createOrUpdateRiderProfile(
        riderProfile: any(named: 'riderProfile'),
      ),
    ).thenAnswer((_) async {});

    final cubit = AppCubit(
      messagesRepository: messagesRepo,
      skillTreeRepository: skillRepo,
      resourcesRepository: resourcesRepo,
      riderProfileRepository: riderRepo,
      horseProfileRepository: horseRepo,
      authenticationRepository: authRepo,
    );

    final data = {'name': 'New User', 'email': 'new@example.com'};
    await cubit.completeProfileFromOnboarding(data);

    verify(
      () => riderRepo.createOrUpdateRiderProfile(
        riderProfile: any(named: 'riderProfile'),
      ),
    ).called(1);
    expect(cubit.state.isProfileSetup, isTrue);
    expect(cubit.state.showOnboarding, isFalse);
  });
}
