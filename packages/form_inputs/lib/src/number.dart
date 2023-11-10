import 'package:formz/formz.dart';

/// Validation Error for [Numberz] form
enum NumberValidationError {
  ///   Error condition
  empty
}

///   Formz input for a number
class Numberz extends FormzInput<int, NumberValidationError> {
  ///{@macro number}
  const Numberz.pure() : super.pure(0);

  ///{@macro number}
  const Numberz.dirty([super.value = 0]) : super.dirty();

  @override
  NumberValidationError? validator(int value) {
    return value >= 0 ? NumberValidationError.empty : null;
  }
}
