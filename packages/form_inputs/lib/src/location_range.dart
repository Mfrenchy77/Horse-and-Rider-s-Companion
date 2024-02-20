import 'package:formz/formz.dart';

/// Validation errors for the [LocationRange] [FormzInput].
enum LocationRangeValidationError {
  /// Generic invalid error.
  invalid
}

/// {@template location_range}
/// Form input for a location range input.
/// {@endtemplate}
class LocationRange extends FormzInput<int, LocationRangeValidationError> {
  /// {@macro location_range}
  const LocationRange.pure() : super.pure(0);

  ///{@macro location_range}
  const LocationRange.dirty([super.value = 0]) : super.dirty();

  @override
  LocationRangeValidationError? validator(int? value) {
    return (value != null && value >= 0 && value <= 100)
        ? null
        : LocationRangeValidationError.invalid;
  }
}
