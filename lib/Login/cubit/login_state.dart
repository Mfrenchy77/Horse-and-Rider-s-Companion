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

  final Name name;
  final Email email;
  final bool isError;
  final Password password;
  final FormzStatus status;
  final String errorMessage;
  final bool forgotEmailSent;
  final bool showEmailDialog;
  final bool isPasswordVisible;
  final LoginPageStatus pageStatus;
  final OpenMailAppResult? mailAppResult;
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
