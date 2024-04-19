import 'package:formz/formz.dart';

/// {@template name}
/// Form input for an name input.
/// Uses [NameValidator] as the validator.
/// {@endtemplate}
class Name extends FormzInput<String, String> {
  /// {@macro name}
  const Name.pure() : super.pure('');

  /// {@macro name}
  const Name.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    return NameValidator.dirty(value).error;
  }
}

/// name search validator, must have at least 3 characters and first letter
/// capitalized and no special characters
class NameValidator extends FormzInput<String, String> {
  /// {@macro name_validator}
  const NameValidator.pure() : super.pure('');

  /// {@macro name_validator}
  const NameValidator.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (value.contains(RegExp(r'[!@#<>?":_`~;[\]\\|=+)(*&^%0-9-]'))) {
      return 'Name must not contain special characters';
    }
    if (value[0] != value[0].toUpperCase()) {
      return 'Name must start with a capital letter';
    }
    return null;
  }
}
