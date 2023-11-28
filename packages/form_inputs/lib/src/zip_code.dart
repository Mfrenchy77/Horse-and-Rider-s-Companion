import 'package:formz/formz.dart';

/// Validation errors for the [ZipCode] form input.
enum ZipCodeValidationError {
  /// Represents an invalid zip code error.
  invalid
}

/// A Formz input class for validating a Zip code.
///
/// This class uses Formz package functionalities to handle zip code input
/// validation. It's tailored for U.S. Zip codes, which are typically 5 digits
/// but can also include an optional 4-digit extension after
///  a hyphen (ZIP+4 format).
class ZipCode extends FormzInput<String, ZipCodeValidationError> {
  /// Constructor for a pure [ZipCode].
  ///
  /// A pure [ZipCode] is not dirty (i.e., it hasn't been modified by the user).
  /// [value] defaults to an empty string if not provided.
  const ZipCode.pure([String value = '']) : super.pure(value);

  /// Constructor for a dirty [ZipCode].
  ///
  /// A dirty [ZipCode] has been modified by the user.
  /// [value] defaults to an empty string if not provided.
  const ZipCode.dirty([String value = '']) : super.dirty(value);

  // Regular expression to validate a U.S. Zip code.
  static final _zipCodeRegExp = RegExp(r'^\d{5}(-\d{4})?$');

  @override
  ZipCodeValidationError? validator(String value) {
    // Validates the input value and returns a corresponding error
    // if the validation fails.
    return _zipCodeRegExp.hasMatch(value)
        ? null
        : ZipCodeValidationError.invalid;
  }
}
