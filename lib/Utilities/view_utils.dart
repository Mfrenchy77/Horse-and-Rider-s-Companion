// ignore_for_file: lines_longer_than_80_chars

import 'dart:math';

// ignore_for_file: constant_identifier_names
class ViewUtils {
  
  final RegExp _numeric = RegExp(r'^-?[0-9]+$');
  static const String _AB =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

  static final Random _rnd = Random();

 

  static String revertPathToEmail(String path) {
    var convertedEmail = path.replaceAll('666', '.');
    convertedEmail = convertedEmail.replaceAll('999', '@');
    convertedEmail = convertedEmail.replaceAll('5', 'f');
    convertedEmail = convertedEmail.replaceAll('1', 'e');
    convertedEmail = convertedEmail.replaceAll('2', 'g');
    convertedEmail = convertedEmail.replaceAll('!', 'm');
    convertedEmail = convertedEmail.replaceAll('p', 'a');
    convertedEmail = convertedEmail.replaceAll('a', 'i');
    convertedEmail = convertedEmail.replaceAll('l', 'co');

    return convertedEmail;
  }

  static int convertIdToNumber(String id) {
    final converted = int.parse(id);

    return converted;
  }

  static String createId() {
    const length = 28;
    final randomStringBuilder = StringBuffer(length);
    for (var i = 0; i < length; i++) {
      randomStringBuilder.write(_AB[_rnd.nextInt(_AB.length)]);
    }
    return randomStringBuilder.toString();
  }

  static int createLongId() {
    final random = Random();
    return random.nextInt(28);
  }

  //Checks of String contains a number
  //
  //@param s string to check
  // @return true if a digit is detected

  bool containsLetter(String string) {
    if (_numeric.hasMatch(string)) {
      return false;
    } else {
      return true;
    }
  }

  static bool isEmailValid(String email) {
    final emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);

    return emailValid;
  }
}


   String convertEmailToPath(String email) {
    var convertedEmail = email.replaceAll('.', '666');
    convertedEmail = convertedEmail.replaceAll('@', '999');
    convertedEmail = convertedEmail.replaceAll('f', '5');
    convertedEmail = convertedEmail.replaceAll('e', '1');
    convertedEmail = convertedEmail.replaceAll('g', '2');
    convertedEmail = convertedEmail.replaceAll('m', '');
    convertedEmail = convertedEmail.replaceAll('a', 'p');
    convertedEmail = convertedEmail.replaceAll('i', 'a');
    convertedEmail = convertedEmail.replaceAll('co', 'l');

    return convertedEmail;
  }
