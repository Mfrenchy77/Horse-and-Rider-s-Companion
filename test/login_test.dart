// //Test 1
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';

// import 'package:authentication_repository/authentication_repository.dart';
// import 'package:formz/formz.dart';
// import 'package:open_mail_app/open_mail_app.dart';

// import 'login_cubit.dart';

// class MockAuthenticationRepository extends Mock
//     implements AuthenticationRepository {}

// void main() {
//   LoginCubit cubit;
//   MockAuthenticationRepository mockAuthenticationRepository;

//   setUp(() {
//     mockAuthenticationRepository = MockAuthenticationRepository();
//     cubit = LoginCubit(mockAuthenticationRepository);
//   });

//   test('initial state is correct', () {
//     expect(cubit.state, const LoginState());
//   });

//   group('togglePasswordVisible', () {
//     test('toggles isPasswordVisible', () async {
//       cubit.togglePasswordVisible();

//       expect(cubit.state.isPasswordVisible, isTrue);
//     });
//   });

//   group('gotoLogin', () {
//     test('sets pageStatus to login', () async {
//       cubit.gotoLogin();

//       expect(cubit.state.pageStatus, LoginPageStatus.login);
//     });
//   });

//   group('gotoRegister', () {
//     test('sets pageStatus to register', () async {
//       cubit.gotoRegister();

//       expect(cubit.state.pageStatus, LoginPageStatus.register);
//     });
//   });

//   group('gotoforgot', () {
//     test('sets pageStatus to forgot', () async {
//       cubit.gotoforgot();

//       expect(cubit.state.pageStatus, LoginPageStatus.forgot);
//     });
//   });

//   group('awitingEmailVerification', () {
//     test('sets pageStatus to awitingEmailVerification', () async {
//       cubit.awitingEmailVerification();

//       expect(
//           cubit.state.pageStatus, LoginPageStatus.awitingEmailVerification);
//     });
//   });

//   group('openEmailApp', () {
//     test('opens the users email app', () async {
//       when(mockAuthenticationRepository.signUp(
//         name: 'John Doe',
//         email: 'john@doe.com',
//         password: '123456',
//       )).thenAnswer((_) => Future.value());

//       cubit.nameChanged('John Doe');
//       cubit.emailChanged('john@doe.com');
//       cubit.passwordChanged('123456');
//       cubit.confirmedPasswordChanged('123456');
//       cubit.signUpFormSubmitted();

//       await Future<void>.delayed(const Duration(milliseconds: 100));

//       cubit.openEmailApp(email: 'john@doe.com');

//       verify(
//         mockAuthenticationRepository.signUp(
//           name: 'John Doe',
//           email: 'john@doe.com',
//           password: '123456',
//         ),
//       ).called(1);
//     });
//   });
// }//Test 1
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';

// import 'package:authentication_repository/authentication_repository.dart';
// import 'package:formz/formz.dart';
// import 'package:open_mail_app/open_mail_app.dart';

// import 'login_cubit.dart';

// class MockAuthenticationRepository extends Mock
//     implements AuthenticationRepository {}

// void main() {
//   LoginCubit cubit;
//   MockAuthenticationRepository mockAuthenticationRepository;

//   setUp(() {
//     mockAuthenticationRepository = MockAuthenticationRepository();
//     cubit = LoginCubit(mockAuthenticationRepository);
//   });

//   test('initial state is correct', () {
//     expect(cubit.state, const LoginState());
//   });

//   group('togglePasswordVisible', () {
//     test('toggles isPasswordVisible', () async {
//       cubit.togglePasswordVisible();

//       expect(cubit.state.isPasswordVisible, isTrue);
//     });
//   });

//   group('gotoLogin', () {
//     test('sets pageStatus to login', () async {
//       cubit.gotoLogin();

//       expect(cubit.state.pageStatus, LoginPageStatus.login);
//     });
//   });

//   group('gotoRegister', () {
//     test('sets pageStatus to register', () async {
//       cubit.gotoRegister();

//       expect(cubit.state.pageStatus, LoginPageStatus.register);
//     });
//   });

//   group('gotoforgot', () {
//     test('sets pageStatus to forgot', () async {
//       cubit.gotoforgot();

//       expect(cubit.state.pageStatus, LoginPageStatus.forgot);
//     });
//   });

//   group('awitingEmailVerification', () {
//     test('sets pageStatus to awitingEmailVerification', () async {
//       cubit.awitingEmailVerification();

//       expect(
//           cubit.state.pageStatus, LoginPageStatus.awitingEmailVerification);
//     });
//   });

//   group('openEmailApp', () {
//     test('opens the users email app', () async {
//       when(mockAuthenticationRepository.signUp(
//         name: 'John Doe',
//         email: 'john@doe.com',
//         password: '123456',
//       )).thenAnswer((_) => Future.value());

//       cubit.nameChanged('John Doe');
//       cubit.emailChanged('john@doe.com');
//       cubit.passwordChanged('123456');
//       cubit.confirmedPasswordChanged('123456');
//       cubit.signUpFormSubmitted();

//       await Future<void>.delayed(const Duration(milliseconds: 100));

//       cubit.openEmailApp(email: 'john@doe.com');

//       verify(
//         mockAuthenticationRepository.signUp(
//           name: 'John Doe',
//           email: 'john@doe.com',
//           password: '123456',
//         ),
//       ).called(1);
//     });
//   });
// }
