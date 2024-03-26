import 'package:formz/formz.dart';

/// {@template email}
/// Form input for an email input.
/// {@endtemplate}
class Email extends FormzInput<String, String> {
  /// {@macro email}
  const Email.pure() : super.pure('');

  /// {@macro email}
  const Email.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    return EmailValidator.dirty(value).error;
  }
}

/// {@template email_validator}
/// Form input for an email input.
/// {@endtemplate}
class EmailValidator extends FormzInput<String, String> {
  /// {@macro email_validator}
  const EmailValidator.pure() : super.pure('');

  /// {@macro email_validator}
  const EmailValidator.dirty([super.value = '']) : super.dirty();

  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );

  @override
  String? validator(String? value) {
    return _emailRegExp.hasMatch(value ?? '') ? null : 'Invalid email address';
  }
}
