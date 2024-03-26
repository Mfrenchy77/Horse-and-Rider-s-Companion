import 'package:formz/formz.dart';

/// {@template password}
/// Form input for an password input.
/// {@endtemplate}
class Password extends FormzInput<String, String> {
  /// {@macro password}
  const Password.pure() : super.pure('');

  /// {@macro password}
  const Password.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    return PasswordValidator.validate(value, null);
  }
/// {@template confirmed_password}
/// Form input for an confirmed password input.
/// {@endtemplate}
  String? confirmValitator(String? value, String? confirmPassword) {
    return PasswordValidator.validate(value, confirmPassword);
  }
}

/// {@template confirmed_password}
/// Form input for an confirmed password input.
/// {@endtemplate}
class PasswordValidator {
  static const _minLength = 6;

  /// {@macro confirmed_password}
  static String? validate(String? password, String? confirmPassword) {
    if (password == null || password.isEmpty) {
      return 'Please enter some text';
    }
    if (confirmPassword != null && confirmPassword != password) {
      return 'Passwords do not match';
    }

    if (password.length < _minLength) {
      return 'Password must be at least $_minLength characters';
    }
    return null;
  }
}
