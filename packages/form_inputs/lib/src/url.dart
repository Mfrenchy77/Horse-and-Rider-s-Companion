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
    try {
      final uri = Uri.tryParse(value ?? '');
      return uri != null &&
              (uri.scheme == 'http' || uri.scheme == 'https') &&
              uri.host.isNotEmpty
          ? null
          : UrlValidationError.invalid;
    } on FormatException {
      return UrlValidationError.invalid;
    }
  }
}
