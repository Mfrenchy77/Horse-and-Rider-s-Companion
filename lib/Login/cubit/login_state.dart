part of 'login_cubit.dart';

enum LoginPageStatus {
  login,
  register,
  forgot,
  awitingEmailVerification,
}

class LoginState extends Equatable {
  const LoginState({
    this.mailAppResult,
    this.isError = false,
    this.errorMessage = '',
    this.forgotEmailSent = false,
    this.showEmailDialog = false,
    this.isPasswordVisible = false,
    this.status = FormzStatus.pure,
    this.name = const Name.pure(),
    this.email = const Email.pure(),
    this.password = const Password.pure(),
    this.pageStatus = LoginPageStatus.login,
    this.confirmedPassword = const ConfirmedPassword.pure(),
  });

  /// Used the name of the user while Registering
  final Name name;

  /// Used the email of the user while Registering or Logging in
  final Email email;

  /// If true, an error message will be shown
  final bool isError;

  /// The password of the user for logging in registered account
  ///  and confirming the password while registering
  final Password password;

  /// The status of the form
  final FormzStatus status;

  /// The error message to be shown
  final String errorMessage;

  /// If true, the forgot password email has been sent
  final bool forgotEmailSent;

  /// If true, the email dialog will be shown
  final bool showEmailDialog;

  /// If true, the password will be visible
  final bool isPasswordVisible;

  /// The different page statuses:
  ///  login, register, forgot, awitingEmailVerification
  final LoginPageStatus pageStatus;

  /// The result of opening the mail app for mobile useres
  final OpenMailAppResult? mailAppResult;

  /// The confirmed password of the user while registering
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
