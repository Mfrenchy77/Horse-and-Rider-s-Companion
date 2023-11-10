import 'package:formz/formz.dart';

///   Validation Error for [SingleWord] Formz
enum WordValidationError {
  /// Error condition
  empty
}

///Formz inpu for a single word
class SingleWord extends FormzInput<String, WordValidationError> {
  ///{@macro word}
  const SingleWord.pure() : super.pure('');

  ///{@macro word}
  const SingleWord.dirty([super.value = '']) : super.dirty();
  @override
  WordValidationError? validator(String value) {
    return value.isEmpty ? WordValidationError.empty : null;
  }
}
