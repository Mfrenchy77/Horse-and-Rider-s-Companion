import 'dart:io';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/generated/l10n.dart';
import 'package:open_mail_app/open_mail_app.dart';
import 'package:url_launcher/url_launcher_string.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authenticationRepository) : super(const LoginState());

  final AuthenticationRepository _authenticationRepository;

  void togglePasswordVisible() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  void gotoLogin() {
    emit(state.copyWith(pageStatus: LoginPageStatus.login));
  }

  void gotoRegister() {
    emit(state.copyWith(pageStatus: LoginPageStatus.register));
  }

  void gotoforgot() {
    emit(state.copyWith(pageStatus: LoginPageStatus.forgot));
  }

  void awitingEmailVerification() {
    emit(state.copyWith(pageStatus: LoginPageStatus.awitingEmailVerification));
  }

  //mehtod that opens a users email app
  Future<void> openEmailApp({
    required BuildContext context,
    required String email,
  }) async {
    debugPrint('openEmailApp: $email');

    if (Platform.isAndroid || Platform.isIOS) {
      await OpenMailApp.openMailApp().then((value) {
        if (!value.didOpen && !value.canOpen) {
          // ignore: use_build_context_synchronously
          emit(
            state.copyWith(
              isError: true,
              errorMessage: S.of(context).login_page_open_email_app_error,
            ),
          );
        } else if (!value.didOpen && value.canOpen) {
          emit(state.copyWith(showEmailDialog: true, mailAppResult: value));
        }
      });
    } else {
      final url = 'mailto:$email';
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        emit(
          state.copyWith(
            isError: true,
            errorMessage: 'Could not launch $url',
          ),
        );
      }
    }
  }

  void clearEmailDialog() {
    // ignore: avoid_redundant_argument_values
    emit(state.copyWith(showEmailDialog: false, mailAppResult: null));
  }

  void clearError() {
    emit(state.copyWith(isError: false, errorMessage: ''));
  }

  void nameChanged(String value) {
    final name = Name.dirty(value);
    emit(
      state.copyWith(
        name: name,
        status: Formz.validate([
          name,
          state.email,
          state.password,
          state.confirmedPassword,
        ]),
      ),
    );
  }

  void emailChanged(String value) {
    final email = Email.dirty(value);
    emit(
      state.copyWith(
        email: email,
        status: Formz.validate([email, state.password]),
      ),
    );
  }

  void passwordChanged(String value) {
    final password = Password.dirty(value);
    emit(
      state.copyWith(
        password: password,
        status: Formz.validate([state.email, password]),
      ),
    );
  }

  void confirmedPasswordChanged(String value) {
    final confirmedPassword = ConfirmedPassword.dirty(
      password: state.password.value,
      value: value,
    );
    emit(
      state.copyWith(
        confirmedPassword: confirmedPassword,
        status: Formz.validate([
          state.email,
          state.password,
          state.name,
          confirmedPassword,
        ]),
      ),
    );
  }

  Future<void> signUpFormSubmitted({required BuildContext context}) async {
    if (!state.status.isValidated) return;
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    try {
      await _authenticationRepository
          .signUp(
        name: state.name.value,
        email: state.email.value,
        password: state.password.value,
      )
          .then((value) {
        openEmailApp(email: state.email.value, context: context);
        emit(state.copyWith(status: FormzStatus.submissionSuccess));
      });
    } on SignUpWithEmailAndPasswordFailure catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: ${e.message}',
          status: FormzStatus.submissionFailure,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormzStatus.submissionFailure,
        ),
      );
    }
  }

  Future<void> logInWithCredentials() async {
    if (!state.status.isValidated) return;
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    try {
      await _authenticationRepository.logInWithEmailAndPassword(
        email: state.email.value,
        password: state.password.value,
      );
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } on LogInWithEmailAndPasswordFailure catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: ${e.message}',
          status: FormzStatus.submissionFailure,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormzStatus.submissionFailure,
        ),
      );
    }
  }

  Future<void> logInWithGoogle() async {
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    try {
      await _authenticationRepository.logInWithGoogle();
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } on LogInWithGoogleFailure catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: ${e.message}',
          status: FormzStatus.submissionFailure,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormzStatus.submissionFailure,
        ),
      );
    }
  }

  /// Login as a guest
  Future<void> logInAsGuest() async {
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    try {
      await _authenticationRepository.signInAsGuest();
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } on LogInAsGuestFailure catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: ${e.message}',
          status: FormzStatus.submissionFailure,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormzStatus.submissionFailure,
        ),
      );
    }
  }

  Future<void> sendForgotPasswordEmail() async {
    if (!state.email.valid) return;
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    try {
      await _authenticationRepository
          .forgotPassword(email: state.email.value)
          .then((value) {
        // openEmailApp(email: state.email.value);
        emit(
          state.copyWith(
            status: FormzStatus.submissionSuccess,
            forgotEmailSent: true,
          ),
        );
      });
    } on ResetPasswordFailure catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: ${e.message}',
          status: FormzStatus.submissionFailure,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormzStatus.submissionFailure,
        ),
      );
    }
  }

  void clearForgotEmailSent() {
    emit(
      state.copyWith(
        forgotEmailSent: false,
        email: const Email.pure(),
      ),
    );
  }

  void showNoMailAppsDialog(BuildContext context) {
    showDialog<AlertDialog>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Open Mail App'),
          content: const Text('No mail apps installed'),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      ).closed.then((value) {
        clearError();
      });
  }
}
