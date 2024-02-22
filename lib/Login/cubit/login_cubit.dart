import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:open_mail_app/open_mail_app.dart';
import 'package:url_launcher/url_launcher.dart';

part 'login_state.dart';

/// {@template login_cubit}
/// A Cubit that manages the state of the login flow.
///
/// It handles user input for login, registration, and password reset,
/// as well as toggling password visibility and navigating between
/// authentication pages.
/// {@endtemplate}
class LoginCubit extends Cubit<LoginState> {
  /// {@macro login_cubit}
  LoginCubit(this._authenticationRepository) : super(const LoginState());
  final AuthenticationRepository _authenticationRepository;

  /// Toggles the visibility of the password field.
  void togglePasswordVisible() {
    emit(state.copyWith(isPasswordVisible: !state.isPasswordVisible));
  }

  /// Updates the state to navigate to the login page.
  void gotoLogin() {
    emit(state.copyWith(pageStatus: LoginPageStatus.login));
  }

  /// Updates the state to navigate to the registration page.
  void gotoRegister() {
    emit(
      state.copyWith(
        pageStatus: LoginPageStatus.register,
        status: FormzStatus.pure,
      ),
    );
  }

  /// Updates the state to navigate to the forgot password page.
  void gotoforgot() {
    emit(state.copyWith(pageStatus: LoginPageStatus.forgot));
  }

  /// Updates the state to indicate that email verification is pending.
  void awitingEmailVerification() {
    emit(state.copyWith(pageStatus: LoginPageStatus.awitingEmailVerification));
  }

  /// Opens the default email application for the provided email address.
  Future<void> openEmailApp({
    required String email,
  }) async {
    final emailUri = Uri(scheme: 'mailto', path: email);

    if (!await canLaunchUrl(emailUri)) {
      emit(
        state.copyWith(
          showEmailDialog: false,
          isError: true,
          errorMessage: 'Unable to open email app',
        ),
      );
      return;
    }

    try {
      await launchUrl(emailUri);
    } catch (e) {
      emit(
        state.copyWith(
          showEmailDialog: false,
          isError: true,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Clears the flag indicating that the email dialog should be shown.
  void clearEmailDialog() {
    // ignore: avoid_redundant_argument_values
    emit(state.copyWith(showEmailDialog: false, mailAppResult: null));
  }

  /// Clears any error messages.
  void clearError() {
    emit(state.copyWith(isError: false, errorMessage: ''));
  }

  /// Updates the state with the new name value.
  void nameChanged(String value) {
    final name = Name.dirty(value);
    emit(
      state.copyWith(
        name: name,
        status: Formz.validate(
          [name, state.email, state.password, state.confirmedPassword],
        ),
      ),
    );
  }

  /// Updates the state with the new email value.
  void emailChanged(String value) {
    final email = Email.dirty(value);
    emit(
      state.copyWith(
        email: email,
        status: Formz.validate([email, state.password]),
      ),
    );
  }

  /// Updates the state with the new password value.
  void passwordChanged(String value) {
    final password = Password.dirty(value);
    emit(
      state.copyWith(
        password: password,
        status: Formz.validate([state.email, password]),
      ),
    );
  }

  /// Updates the state with the new confirmed password value.
  void confirmedPasswordChanged(String value) {
    final confirmedPassword =
        ConfirmedPassword.dirty(password: state.password.value, value: value);
    emit(
      state.copyWith(
        confirmedPassword: confirmedPassword,
        status: Formz.validate(
          [state.email, state.password, state.name, confirmedPassword],
        ),
      ),
    );
  }

  /// Submits the sign-up form.
  Future<void> signUpFormSubmitted({required BuildContext context}) async {
    if (!state.status.isValidated) return;
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    try {
      await _authenticationRepository.signUp(
        name: state.name.value,
        email: state.email.value,
        password: state.password.value,
      );
      await openEmailApp(email: state.email.value);
      emit(
        state.copyWith(
          status: FormzStatus.submissionInProgress,
          pageStatus: LoginPageStatus.awitingEmailVerification,
          showEmailDialog: true,
        ),
      );
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

  /// Logs in with the provided email and password.
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

  /// Logs in with Google authentication.
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

  /// Logs in as a guest.
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

  /// Sends a forgot password email.
  Future<void> sendForgotPasswordEmail() async {
    if (!state.email.valid) return;
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    try {
      await _authenticationRepository.forgotPassword(email: state.email.value);
      emit(
        state.copyWith(
          status: FormzStatus.submissionInProgress,
          pageStatus: LoginPageStatus.awitingEmailVerification,
          forgotEmailSent: true,
        ),
      );
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

  /// Clears the flag indicating a forgot email has been sent.
  void clearForgotEmailSent() {
    emit(state.copyWith(forgotEmailSent: false, email: const Email.pure()));
  }
}
