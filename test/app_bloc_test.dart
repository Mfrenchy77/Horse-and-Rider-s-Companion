import 'package:test/test.dart';
import 'package:authentication_repository/authentication_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/App/Bloc/app_bloc.dart';
import 'package:mockito/mockito.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('AppBloc', () {
    late AuthenticationRepository authenticationRepository;
    late AppBloc appBloc;

    setUp(() {
      authenticationRepository = MockAuthenticationRepository();
      appBloc = AppBloc(authenticationRepository: authenticationRepository);
    });

    test('initial state is correct', () {
      expect(appBloc.state, equals(const AppState.unauthenticated()));
    });

    test('emits [authenticated] when user is logged in', () {
      const user = User(
        id: '123',
        name: 'Joe Schmoe',
        email: 'test@test.com',
        emailVerfified: true,
      );
      expectLater(
        appBloc.stream,
        emitsInOrder([
          const AppState.unauthenticated(),
          const AppState.authenticated(user),
        ]),
      );
      when(authenticationRepository.currentUser).thenReturn(user);
      appBloc.add(const AppUserChanged(user));
    });

    test('emits [unauthenticated] when user logs out', () {
      expectLater(
        appBloc.stream,
        emitsInOrder([
          const AppState.unauthenticated(),
        ]),
      );
      appBloc.add(AppLogoutRequested());
    });

    test('emits [unauthenticated] when user is not verified', () {
      const user =
          User(id: '123', name: 'Jolene Schmoe', email: 'test@test.com');
      expectLater(
        appBloc.stream,
        emitsInOrder([
          const AppState.unauthenticated(),
        ]),
      );
      appBloc.add(const AppUserChanged(user));
    });

    // test('emits [unauthenticated] when user is null', () {
    //   expectLater(
    //     appBloc.stream,
    //     emitsInOrder([
    //       const AppState.unauthenticated(),
    //     ]),
    //   );
    //   appBloc.add(const AppUserChanged(null));
    // });

    // tearDown(() {
    //   authenticationRepository.close();
    // });
  });
}
