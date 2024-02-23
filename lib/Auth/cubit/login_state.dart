part of 'login_cubit.dart';

/// Enum defining the different pages or states the login flow can be in.
enum LoginPageStatus {
  login,
  forgot,
  register,
  awitingEmailVerification,
}

/// {@template login_state}
/// The state of the login flow, including form inputs, validation status,
/// error messages, and the current page status.
/// {@endtemplate}
class LoginState extends Equatable {
  /// Creates a [LoginState].
  const LoginState({
    this.mailAppResult,
    this.isError = false,
    this.errorMessage = '',
    this.forgotEmailSent = false,
    this.showEmailDialog = false,
    this.name = const Name.pure(),
    this.isPasswordVisible = false,
    this.status = FormzStatus.pure,
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.pageStatus = LoginPageStatus.login,
    this.confirmedPassword = const ConfirmedPassword.pure(),
  });

  /// The name entered by the user, mainly used during registration.
  final Name name;

  /// The email entered by the user, used for both login and registration.
  final Email email;

  /// Indicates if an error has occurred.
  final bool isError;

  /// The password entered by the user, used for login.
  final Password password;

  /// The current form validation status.
  final FormzStatus status;

  /// Error message to display to the user.
  final String errorMessage;

  /// Indicates if the password reset email has been sent.
  final bool forgotEmailSent;

  /// Controls whether the email dialog is shown.
  final bool showEmailDialog;

  /// Toggles the visibility of the password input.
  final bool isPasswordVisible;

  /// The current page status in the login flow.
  final LoginPageStatus pageStatus;

  /// Result of attempting to open the mail app, used in email verification.
  final OpenMailAppResult? mailAppResult;

  /// The confirmed password entered by the user, used for registration.
  final ConfirmedPassword confirmedPassword;

  @override
  List<Object?> get props => [
        name,
        email,
        status,
        isError,
        password,
        pageStatus,
        errorMessage,
        mailAppResult,
        forgotEmailSent,
        showEmailDialog,
        isPasswordVisible,
        confirmedPassword,
      ];

  /// Returns a copy of this [LoginState] with the given fields replaced with
  /// the new values.
  LoginState copyWith({
    Name? name,
    Email? email,
    bool? isError,
    Password? password,
    FormzStatus? status,
    String? errorMessage,
    bool? forgotEmailSent,
    bool? showEmailDialog,
    bool? isPasswordVisible,
    LoginPageStatus? pageStatus,
    OpenMailAppResult? mailAppResult,
    ConfirmedPassword? confirmedPassword,
  }) {
    return LoginState(
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      password: password ?? this.password,
      pageStatus: pageStatus ?? this.pageStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      mailAppResult: mailAppResult ?? this.mailAppResult,
      forgotEmailSent: forgotEmailSent ?? this.forgotEmailSent,
      showEmailDialog: showEmailDialog ?? this.showEmailDialog,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      confirmedPassword: confirmedPassword ?? this.confirmedPassword,
    );
  }
}