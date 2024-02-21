import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:open_mail_app/open_mail_app.dart';
import 'package:url_launcher/url_launcher.dart';

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
    emit(
      state.copyWith(
        pageStatus: LoginPageStatus.register,
        status: FormzStatus.pure,
      ),
    );
  }

  void gotoforgot() {
    emit(state.copyWith(pageStatus: LoginPageStatus.forgot));
  }

  void awitingEmailVerification() {
    emit(state.copyWith(pageStatus: LoginPageStatus.awitingEmailVerification));
  }

  Future<void> openEmailApp({
    required BuildContext context,
    required String email,
  }) async {
    debugPrint('openEmailApp: $email');
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
      debugPrint('signUpFormSubmitted: ${state.name.value}');
      await _authenticationRepository
          .signUp(
        name: state.name.value,
        email: state.email.value,
        password: state.password.value,
      )
          .then((value) {
        debugPrint('Open Email App for: ${state.email.value}');
        openEmailApp(email: state.email.value, context: context);
        emit(
          state.copyWith(
            status: FormzStatus.submissionInProgress,
            pageStatus: LoginPageStatus.awitingEmailVerification,
            showEmailDialog: true,
          ),
        );
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
            status: FormzStatus.submissionInProgress,
            pageStatus: LoginPageStatus.awitingEmailVerification,
            forgotEmailSent: true,
          ),
        );
      });
    } on ResetPasswordFailure catch (e) {
      debugPrint('ResetPasswordFailure: ${e.message}');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: ${e.message}',
          status: FormzStatus.submissionFailure,
        ),
      );
    } catch (_) {
      debugPrint('ResetPasswordFailure: Unknown');
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
}
