import 'package:formz/formz.dart';

/// A Formz input class for validating a Zip code.
///
/// This class uses Formz package functionalities to handle zip code input
/// validation. It's tailored for U.S. Zip codes, which are typically 5 digits
/// but can also include an optional 4-digit extension after
///  a hyphen (ZIP+4 format).
class ZipCode extends FormzInput<String, String> {
  /// Constructor for a pure [ZipCode].
  ///
  /// A pure [ZipCode] is not dirty (i.e., it hasn't been modified by the user).
  /// [value] defaults to an empty string if not provided.
  const ZipCode.pure([super.value = '']) : super.pure();

  /// Constructor for a dirty [ZipCode].
  ///
  /// A dirty [ZipCode] has been modified by the user.
  /// [value] defaults to an empty string if not provided.
  const ZipCode.dirty([super.value = '']) : super.dirty();

  @override
  String? validator(String value) {
    return ZipCodeValidator.dirty(value).error;
  }
}

/// Validator for a Zip code input.
/// must be 5 digits or 5 digits followed by a hyphen and 4 digits.
class ZipCodeValidator extends FormzInput<String, String> {
  const ZipCodeValidator.pure() : super.pure('');

  /// Constructor for a dirty [ZipCodeValidator].
  const ZipCodeValidator.dirty([super.value = '']) : super.dirty();

  static final RegExp _zipCodeRegExp = RegExp(r'^\d{5}(-\d{4})?$');

  @override
  String? validator(String? value) {
    return _zipCodeRegExp.hasMatch(value ?? '') ? null : 'Invalid zip code';
  }
}
