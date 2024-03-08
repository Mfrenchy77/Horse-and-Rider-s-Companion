// ignore_for_file: lines_longer_than_80_chars
// // GENERATED CODE - DO NOT MODIFY BY HAND
// // ignore_for_file: always_use_package_imports

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'intl/messages_all.dart';

// // **************************************************************************
// // Generator: Flutter Intl IDE plugin
// // Made by Localizely
// // **************************************************************************

// // ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// // ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// // ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

// class S {
//   S();

//   static S? _current;

//   static S get current {
//     assert(
//       _current != null,
//       'No instance of S was loaded. Try to initialize the S delegate before a
//     );ccessing S.current.',
//     return _current!;
//   }

//   static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

//   static Future<S> load(Locale locale) {
//     final name = (locale.countryCode?.isEmpty ?? false)
//         ? locale.languageCode
//         : locale.toString();
//     final localeName = Intl.canonicalizedLocale(name);
//     return initializeMessages(localeName).then((_) {
//       Intl.defaultLocale = localeName;
//       final instance = S();
//       S._current = instance;

//       return instance;
//     });
//   }

//   static S of(BuildContext context) {
//     final instance = S.maybeOf(context);
//     assert(
//       instance != null,
//       'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
//     );
//     return instance!;
//   }

//   static S? maybeOf(BuildContext context) {
//     return Localizations.of<S>(context, S);
//   }

//   /// `Horse & Rider's Companion`
//   String get appTitle {
//     return Intl.message(
//       'Horse & Rider\'s Companion',
//       name: 'appTitle',
//       desc: 'Title of our Application',
//       args: [],
//     );
//   }

//   /// `Horses`
//   String get horses_text {
//     return Intl.message(
//       'Horses',
//       name: 'horses_text',
//       desc: 'the word Horses',
//       args: [],
//     );
//   }

//   /// `Instructors`
//   String get instructors_text {
//     return Intl.message(
//       'Instructors',
//       name: 'instructors_text',
//       desc: 'The word "Instructors"',
//       args: [],
//     );
//   }

//   /// `Log Book`
//   String get log_book_text {
//     return Intl.message(
//       'Log Book',
//       name: 'log_book_text',
//       desc: 'The words "Log Book"',
//       args: [],
//     );
//   }

//   /// `Confirm password`
//   String get login_page_confirm_password_label {
//     return Intl.message(
//       'Confirm password',
//       name: 'login_page_confirm_password_label',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Create an account`
//   String get login_page_create_account {
//     return Intl.message(
//       'Create an account',
//       name: 'login_page_create_account',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Email`
//   String get login_page_email_label {
//     return Intl.message(
//       'Email',
//       name: 'login_page_email_label',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Cancel`
//   String get login_page_email_sent_dialog_cancel {
//     return Intl.message(
//       'Cancel',
//       name: 'login_page_email_sent_dialog_cancel',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Continue`
//   String get login_page_email_sent_dialog_continue {
//     return Intl.message(
//       'Continue',
//       name: 'login_page_email_sent_dialog_continue',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Do you want to open mail app to continue?`
//   String get login_page_email_sent_dialog_message {
//     return Intl.message(
//       'Do you want to open mail app to continue?',
//       name: 'login_page_email_sent_dialog_message',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Open mail app`
//   String get login_page_email_sent_dialog_title {
//     return Intl.message(
//       'Open mail app',
//       name: 'login_page_email_sent_dialog_title',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Email verification error!`
//   String get login_page_email_verification_error {
//     return Intl.message(
//       'Email verification error!',
//       name: 'login_page_email_verification_error',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Email verification failed.`
//   String get login_page_email_verification_failed {
//     return Intl.message(
//       'Email verification failed.',
//       name: 'login_page_email_verification_failed',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Email verification in progress...`
//   String get login_page_email_verification_in_progress {
//     return Intl.message(
//       'Email verification in progress...',
//       name: 'login_page_email_verification_in_progress',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Resend verification email`
//   String get login_page_email_verification_resend {
//     return Intl.message(
//       'Resend verification email',
//       name: 'login_page_email_verification_resend',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Retry`
//   String get login_page_email_verification_retry {
//     return Intl.message(
//       'Retry',
//       name: 'login_page_email_verification_retry',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Email verification sent!`
//   String get login_page_email_verification_sent {
//     return Intl.message(
//       'Email verification sent!',
//       name: 'login_page_email_verification_sent',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Please check your email and click on the verification link to continue.`
//   String get login_page_email_verification_subtitle {
//     return Intl.message(
//       'Please check your email and click on the verification link to continue.',
//       name: 'login_page_email_verification_subtitle',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Email verification success!`
//   String get login_page_email_verification_success {
//     return Intl.message(
//       'Email verification success!',
//       name: 'login_page_email_verification_success',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Email verification`
//   String get login_page_email_verification_title {
//     return Intl.message(
//       'Email verification',
//       name: 'login_page_email_verification_title',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Error`
//   String get login_page_error {
//     return Intl.message(
//       'Error',
//       name: 'login_page_error',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Error: {error}`
//   String login_page_error_message(Object error) {
//     return Intl.message(
//       'Error: $error',
//       name: 'login_page_error_message',
//       desc: '',
//       args: [error],
//     );
//   }

//   /// `Forgot password?`
//   String get login_page_forgot_password {
//     return Intl.message(
//       'Forgot password?',
//       name: 'login_page_forgot_password',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Sign in with Google`
//   String get login_page_google_login_button {
//     return Intl.message(
//       'Sign in with Google',
//       name: 'login_page_google_login_button',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Name`
//   String get login_page_name_label {
//     return Intl.message(
//       'Name',
//       name: 'login_page_name_label',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `No mail apps installed`
//   String get login_page_open_email_app_error {
//     return Intl.message(
//       'No mail apps installed',
//       name: 'login_page_open_email_app_error',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Could not launch`
//   String get login_page_open_email_app_error_message {
//     return Intl.message(
//       'Could not launch',
//       name: 'login_page_open_email_app_error_message',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Password`
//   String get login_page_password_label {
//     return Intl.message(
//       'Password',
//       name: 'login_page_password_label',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Register an account`
//   String get login_page_register_account {
//     return Intl.message(
//       'Register an account',
//       name: 'login_page_register_account',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Sign In`
//   String get login_page_sign_in_button {
//     return Intl.message(
//       'Sign In',
//       name: 'login_page_sign_in_button',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Sign Up`
//   String get login_page_sign_up_button {
//     return Intl.message(
//       'Sign Up',
//       name: 'login_page_sign_up_button',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Submit`
//   String get login_page_submit_button {
//     return Intl.message(
//       'Submit',
//       name: 'login_page_submit_button',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Submission Failure`
//   String get login_page_submit_failure {
//     return Intl.message(
//       'Submission Failure',
//       name: 'login_page_submit_failure',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Submission in progress...`
//   String get login_page_submit_in_progress {
//     return Intl.message(
//       'Submission in progress...',
//       name: 'login_page_submit_in_progress',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Submission Success`
//   String get login_page_submit_success {
//     return Intl.message(
//       'Submission Success',
//       name: 'login_page_submit_success',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Login`
//   String get login_page_title {
//     return Intl.message(
//       'Login',
//       name: 'login_page_title',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `No Messages`
//   String get messages_none {
//     return Intl.message(
//       'No Messages',
//       name: 'messages_none',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Messages`
//   String get messages_text {
//     return Intl.message(
//       'Messages',
//       name: 'messages_text',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Unknown`
//   String get messages_unknown {
//     return Intl.message(
//       'Unknown',
//       name: 'messages_unknown',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `You`
//   String get messages_you_text {
//     return Intl.message(
//       'You',
//       name: 'messages_you_text',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Owned Horses`
//   String get owned_horses_text {
//     return Intl.message(
//       'Owned Horses',
//       name: 'owned_horses_text',
//       desc: 'The words "Owned Horses"',
//       args: [],
//     );
//   }

//   /// `Dark Theme`
//   String get settings_dark {
//     return Intl.message(
//       'Dark Theme',
//       name: 'settings_dark',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Light Theme`
//   String get settings_light {
//     return Intl.message(
//       'Light Theme',
//       name: 'settings_light',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Disable seasonal theme?`
//   String get settings_seasonal_disable {
//     return Intl.message(
//       'Disable seasonal theme?',
//       name: 'settings_seasonal_disable',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Enable seasonal theme?`
//   String get settings_seasonal_enable {
//     return Intl.message(
//       'Enable seasonal theme?',
//       name: 'settings_seasonal_enable',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `System Theme`
//   String get settings_system {
//     return Intl.message(
//       'System Theme',
//       name: 'settings_system',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Settings`
//   String get settings_text {
//     return Intl.message(
//       'Settings',
//       name: 'settings_text',
//       desc: 'The word "Settings"',
//       args: [],
//     );
//   }

//   /// `Choose a theme`
//   String get settings_theme_picker {
//     return Intl.message(
//       'Choose a theme',
//       name: 'settings_theme_picker',
//       desc: '',
//       args: [],
//     );
//   }

//   /// `Student Horses`
//   String get student_horses_text {
//     return Intl.message(
//       'Student Horses',
//       name: 'student_horses_text',
//       desc: 'The word "Student Horses"\n',
//       args: [],
//     );
//   }

//   /// `Students`
//   String get student_text {
//     return Intl.message(
//       'Students',
//       name: 'student_text',
//       desc: 'The words "Student Text"',
//       args: [],
//     );
//   }
// }

// class AppLocalizationDelegate extends LocalizationsDelegate<S> {
//   const AppLocalizationDelegate();

//   List<Locale> get supportedLocales {
//     return const <Locale>[
//       Locale.fromSubtags(languageCode: 'en'),
//       Locale.fromSubtags(languageCode: 'es'),
//       Locale.fromSubtags(languageCode: 'fr'),
//       Locale.fromSubtags(languageCode: 'it'),
//     ];
//   }

//   @override
//   bool isSupported(Locale locale) => _isSupported(locale);
//   @override
//   Future<S> load(Locale locale) => S.load(locale);
//   @override
//   bool shouldReload(AppLocalizationDelegate old) => false;

//   bool _isSupported(Locale locale) {
//     for (var supportedLocale in supportedLocales) {
//       if (supportedLocale.languageCode == locale.languageCode) {
//         return true;
//       }
//     }
//     return false;
//   }
// }
