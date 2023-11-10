import 'package:formz/formz.dart';

///Validation Error for the[Url] [FormzInput]
enum UrlValidationError {
  ///genric invalid error
  invalid
}

///  {@template url}
///   Form input for a url input
///   {@endtemplate}
class Url extends FormzInput<String, UrlValidationError> {
  /// {@macro url}
  const Url.pure() : super.pure('');

  /// {@macro url}
  const Url.dirty([super.value = '']) : super.dirty();
  

  @override
  UrlValidationError? validator(String? value) {
    if (value != null) {
      return Uri.parse(value).host.isNotEmpty
          ? null
          : UrlValidationError.invalid;
    } else {
      return UrlValidationError.invalid;
    }
  }
}
