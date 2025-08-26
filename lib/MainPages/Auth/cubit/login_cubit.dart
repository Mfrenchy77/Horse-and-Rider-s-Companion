import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
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
    debugPrint('Toggle Password Visibility');
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
        status: FormStatus.initial,
      ),
    );
  }

  /// Updates the state to navigate to the forgot password page.
  void gotoforgot() {
    emit(state.copyWith(pageStatus: LoginPageStatus.forgot));
  }

  /// Updates the state to indicate that email verification is pending.
  void awitingEmailVerification() {
    debugPrint('Waiting Email Verification');
  }

  /// Opens the default email application for the provided email address.
  Future<void> openEmailApp({
    required String email,
  }) async {
    final emailUri = Uri(path: email);

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
    emit(state.copyWith(showEmailDialog: false));
  }

  /// Updates the state with the new name value.
  void nameChanged(String value) {
    final name = Name.dirty(value);
    emit(
      state.copyWith(name: name),
    );
  }

  /// Updates the state with the new email value.
  void emailChanged(String value) {
    final email = Email.dirty(value);
    emit(
      state.copyWith(email: email),
    );
  }

  /// Return true if email and password are valid
  bool isEmailAndPasswordValid() {
    return state.email.isValid && state.password.isValid;
  }

  /// Updates the state with the new password value.
  void passwordChanged(String value) {
    final password = Password.dirty(value);
    emit(
      state.copyWith(password: password),
    );
  }

  /// Updates the state with the new confirmed password value.
  void confirmedPasswordChanged(String value) {
    final confirmedPassword =
        ConfirmedPassword.dirty(password: state.password.value, value: value);
    emit(
      state.copyWith(confirmedPassword: confirmedPassword),
    );
  }

  /// Submits the sign-up form.
  Future<void> signUpFormSubmitted({required BuildContext context}) async {
    emit(state.copyWith(status: FormStatus.submitting));
    try {
      await _authenticationRepository
          .signUp(
        name: state.name.value,
        email: state.email.value,
        password: state.password.value,
      )
          .then((value) async {
        if (value == null) {
          debugPrint('User not created');
          emit(
            state.copyWith(
              isError: true,
              status: FormStatus.failure,
              errorMessage: 'Error: User not created',
            ),
          );
          clearError();
        } else if (value.emailVerified) {
          emit(
            state.copyWith(
              isMessage: true,
              status: FormStatus.success,
              errorMessage: 'Welcome ${value.name}!',
            ),
          );
          clearError();
        } else {
          debugPrint('Email not verified');
          //await openEmailApp(email: state.email.value);
          emit(
            state.copyWith(
              status: FormStatus.success,
              isMessage: true,
              errorMessage: 'Welcome, please check your email to verify',
            ),
          );
          clearError();
        }
      });
    } on SignUpWithEmailAndPasswordFailure catch (e) {
      debugPrint('Error: ${e.message}');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: ${e.message}',
          status: FormStatus.failure,
        ),
      );
      clearError();
    } catch (_) {
      debugPrint('Submission Failure');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormStatus.failure,
        ),
      );
      clearError();
    }
  }

  /// Logs in with the provided email and password.
  Future<void> logInWithCredentials() async {
    emit(state.copyWith(status: FormStatus.submitting));
    try {
      await _authenticationRepository
          .logInWithEmailAndPassword(
        email: state.email.value,
        password: state.password.value,
      )
          .then((value) {
        if (value == null) {
          debugPrint('User not created');
          emit(
            state.copyWith(
              isError: true,
              errorMessage: 'Error: User not created',
              status: FormStatus.failure,
            ),
          );
          clearError();
        } else {
          emit(
            state.copyWith(
              isMessage: true,
              status: FormStatus.success,
              errorMessage: 'Welcome ${value.name}!',
            ),
          );
          clearError();
        }
      });
    } on LogInWithEmailAndPasswordFailure catch (e) {
      debugPrint('Error: ${e.message}');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: ${e.message}',
          status: FormStatus.failure,
        ),
      );
      clearError();
    } catch (_) {
      debugPrint('Submission Failure');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormStatus.failure,
        ),
      );
      clearError();
    }
  }

  /// Logs in with Google authentication.
  Future<void> logInWithGoogle() async {
    debugPrint('Log in with Google');
    emit(state.copyWith(status: FormStatus.submitting));
    try {
      await _authenticationRepository.logInWithGoogle().then((value) {
        if (value == null) {
          debugPrint('User not created');
          emit(
            state.copyWith(
              isError: true,
              status: FormStatus.failure,
              errorMessage: 'Error: User not created',
            ),
          );
          clearError();
        } else {
          emit(
            state.copyWith(
              isMessage: true,
              status: FormStatus.success,
              errorMessage: 'Welcome, ${value.name}!',
            ),
          );
          clearError();
        }
      });
    } on LogInWithGoogleFailure catch (e) {
      debugPrint('Error: ${e.message}');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: ${e.message}',
          status: FormStatus.failure,
        ),
      );
      clearError();
    } catch (_) {
      debugPrint('Submission Failure');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormStatus.failure,
        ),
      );
      clearError();
    }
  }

  /// Logs in as a guest.
  Future<void> logInAsGuest() async {
    debugPrint('Log in as Guest');
    emit(state.copyWith(status: FormStatus.submitting));
    try {
      await _authenticationRepository.signInAsGuest().then((value) {
        if (value == null) {
          debugPrint('User not created');
          emit(
            state.copyWith(
              isError: true,
              errorMessage: 'Error: User not created',
              status: FormStatus.failure,
            ),
          );
          clearError();
        } else {
          // debugPrint('Success Login, go to HomePage');
          emit(
            state.copyWith(
              isGuest: true,
              isMessage: true,
              status: FormStatus.success,
              errorMessage: 'Welcome, Guest!',
            ),
          );
          clearError();
        }
      });
    } catch (_) {
      debugPrint('Submission Failure');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormStatus.failure,
        ),
      );
      clearError();
    }
  }

  /// Sends a forgot password email.
  Future<void> sendForgotPasswordEmail() async {
    debugPrint('Send Forgot Password Email');
    emit(state.copyWith(status: FormStatus.submitting));
    try {
      await _authenticationRepository.forgotPassword(email: state.email.value);
      emit(
        state.copyWith(
          isMessage: true,
          forgotEmailSent: true,
          status: FormStatus.initial,
          pageStatus: LoginPageStatus.login,
          errorMessage: 'Reset email sent to ${state.email.value}',
        ),
      );
      clearError();
    } on ResetPasswordFailure catch (e) {
      debugPrint('Error: ${e.message}');
      emit(
        state.copyWith(
          isError: true,
          status: FormStatus.failure,
          errorMessage: 'Error: ${e.message}',
        ),
      );
      clearError();
    } catch (_) {
      debugPrint('Submission Failure');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Submission Failure',
          status: FormStatus.failure,
        ),
      );
      clearError();
    }
  }

  /// Clears the flag indicating a forgot email has been sent.
  void clearForgotEmailSent() {
    emit(state.copyWith(forgotEmailSent: false, email: const Email.pure()));
  }

  /// Clears any error messages.
  void clearError() {
    emit(
      state.copyWith(
        isError: false,
        isMessage: false,
        errorMessage: '',
      ),
    );
  }
}
