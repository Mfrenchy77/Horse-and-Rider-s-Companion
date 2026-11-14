import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

class MockSkillTreeRepository extends Mock implements SkillTreeRepository {}

class MockResourcesRepository extends Mock implements ResourcesRepository {}

class MockRiderProfileRepository extends Mock
    implements RiderProfileRepository {}

class MockHorseProfileRepository extends Mock
    implements HorseProfileRepository {}

class MockMessagesRepository extends Mock implements MessagesRepository {}

class MockAccountDeletionRepository extends Mock
    implements AccountDeletionRepository {}

/// An offline harness for app-state tests.
///  Each instance owns its subscriptions.
class AppTestHarness {
  AppTestHarness._();

  final auth = MockAuthenticationRepository();
  final skills = MockSkillTreeRepository();
  final resources = MockResourcesRepository();
  final riders = MockRiderProfileRepository();
  final horses = MockHorseProfileRepository();
  final messages = MockMessagesRepository();
  final accountDeletion = MockAccountDeletionRepository();
  late final AppCubit cubit;

  static Future<AppTestHarness> create({
    Future<Map<String, dynamic>> Function(Map<String, Object?>)?
    submitCoachingAction,
    ConnectionRequestStore? requestStore,
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      SharedPrefs.PREF_SHOW_ONBOARDING: false,
      SharedPrefs.PREF_IS_FIRST_LAUNCH: false,
    });
    await SharedPrefs().init();
    final harness = AppTestHarness._();
    when(() => harness.auth.currentUser).thenReturn(User.empty);
    when(() => harness.auth.user).thenAnswer((_) => const Stream.empty());
    when(harness.auth.logOut).thenAnswer((_) async {});
    when(harness.accountDeletion.deleteCurrentAccount).thenAnswer(
      (_) async => const AccountDeletionResult(
        status: AccountDeletionStatus.completed,
      ),
    );
    when(harness.skills.getSkills).thenAnswer((_) => const Stream.empty());
    when(
      harness.resources.getResources,
    ).thenAnswer((_) => const Stream.empty());
    harness.cubit = AppCubit(
      authenticationRepository: harness.auth,
      skillTreeRepository: harness.skills,
      resourcesRepository: harness.resources,
      riderProfileRepository: harness.riders,
      horseProfileRepository: harness.horses,
      messagesRepository: harness.messages,
      connectionRequestRepository: requestStore,
      accountDeletionRepository: harness.accountDeletion,
      submitCoachingAction: submitCoachingAction,
    );
    return harness;
  }

  Future<void> close() => cubit.close();
}
