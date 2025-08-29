// ignore_for_file: prefer_const_constructors

import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/message_item.dart';
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

void main() {
  testWidgets('MessageItem shows Accept and Deny for pending request',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
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

    final me = RiderProfile(id: 'me', name: 'Me', email: 'me@example.com');
    cubit.emit(cubit.state.copyWith(usersProfile: me));

    final msg = Message(
      id: 'c1',
      date: DateTime.now(),
      sender: 'Other',
      senderId: 'other@x.com',
      senderProfilePicUrl: 'example.com/profile_pics/other.png',
      subject: 'Instructor Request',
      message: 'Please add as instructor',
      messageId: 'm100',
      recipients: const ['Me', 'Other'],
      messageType: MessageType.INSTRUCTOR_REQUEST,
      requestItem: BaseListItem(id: 'other@x.com', isSelected: false),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AppCubit>.value(
          value: cubit,
          child: Scaffold(
            body: Center(
              child: MessageItem(
                message: msg,
                isCurrentUser: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('AcceptRequestButton')), findsOneWidget);
    expect(find.byKey(const Key('DenyRequestButtonInline')), findsOneWidget);
  });
}
