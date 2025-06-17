// ignore_for_file: constant_identifier_names, non_constant_identifier_names

//firebase url keys
class StringConstants {
  static const String HORSEANDRIDERCOMPANIONEMAIL =
      'HorseAndRidersCompanion@gmail.com';
  static const String HORSEANDRIDERCOMPANIONNAME =
      "Horse And Rider's Companion";

  ///Breakpoint for split screen mode
  static const double splitScreenBreakpoint = 1024;
}

///List of Authorized Emails for global editing
class AuthorizedEmails {
  static const List<String> emails = [
    'horseandriderscompanion@gmail.com',
    'frenchfriedtechnology@gmail.com',
    'mfrenchy77@gmail.com',
  ];
}

/// enum for Form status
enum FormStatus {
  /// Form is in the initial state
  initial,

  /// Form is submitting
  submitting,

  /// Form has been submitted successfully
  success,

  /// Form submission failed
  failure,
}
