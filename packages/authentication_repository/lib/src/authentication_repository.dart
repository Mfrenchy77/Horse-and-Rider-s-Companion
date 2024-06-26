// ignore_for_file: avoid_print

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:cache/cache.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// {@template sign_up_with_email_and_password_failure}
/// Thrown if during the sign up process if a failure occurs.
/// {@endtemplate}
class SignUpWithEmailAndPasswordFailure implements Exception {
  /// {@macro sign_up_with_email_and_password_failure}
  const SignUpWithEmailAndPasswordFailure([
    this.message = 'An unknown exception occurred.',
  ]);

  /// Create an authentication message
  /// from a firebase authentication exception code.
  /// https://pub.dev/documentation/firebase_auth/latest/firebase_auth/FirebaseAuth/createUserWithEmailAndPassword.html
  factory SignUpWithEmailAndPasswordFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const SignUpWithEmailAndPasswordFailure(
          'Email is not valid or badly formatted.',
        );
      case 'user-disabled':
        return const SignUpWithEmailAndPasswordFailure(
          'This user has been disabled. Please contact support for help.',
        );
      case 'email-already-in-use':
        return const SignUpWithEmailAndPasswordFailure(
          'An account already exists for that email.',
        );
      case 'operation-not-allowed':
        return const SignUpWithEmailAndPasswordFailure(
          'Operation is not allowed.  Please contact support.',
        );
      case 'weak-password':
        return const SignUpWithEmailAndPasswordFailure(
          'Please enter a stronger password.',
        );
      default:
        return const SignUpWithEmailAndPasswordFailure('Error');
    }
  }

  /// The associated error message.
  final String message;
}

/// {@template log_in_with_email_and_password_failure}
/// Thrown during the login process if a failure occurs.
/// https://pub.dev/documentation/firebase_auth/latest/firebase_auth/FirebaseAuth/signInWithEmailAndPassword.html
/// {@endtemplate}
class LogInWithEmailAndPasswordFailure implements Exception {
  /// {@macro log_in_with_email_and_password_failure}
  const LogInWithEmailAndPasswordFailure([
    this.message = 'An unknown exception occurred.',
  ]);

  /// Create an authentication message
  /// from a firebase authentication exception code.
  factory LogInWithEmailAndPasswordFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const LogInWithEmailAndPasswordFailure(
          'Email is not valid or badly formatted.',
        );
      case 'user-disabled':
        return const LogInWithEmailAndPasswordFailure(
          'This user has been disabled. Please contact support for help.',
        );
      case 'user-not-found':
        return const LogInWithEmailAndPasswordFailure(
          'Email is not found, check spelling or please create an account.',
        );
      case 'wrong-password':
        return const LogInWithEmailAndPasswordFailure(
          'Incorrect password, please try again.',
        );
      default:
        return const LogInWithEmailAndPasswordFailure();
    }
  }

  /// The associated error message.
  final String message;
}

/// {@template log_in_as_guest_failure}
/// Thrown during the login process if a failure occurs.
/// https://pub.dev/documentation/firebase_auth/latest/firebase_auth/FirebaseAuth/signInAnonymously.html
/// {@endtemplate}
class LogInAsGuestFailure implements Exception {
  /// {@macro log_in_as_guest_failure}
  const LogInAsGuestFailure([
    this.message = 'An unknown exception occurred.',
  ]);

  /// Create an authentication message
  /// from a firebase authentication exception code.
  factory LogInAsGuestFailure.fromCode(String code) {
    switch (code) {
      case 'user-disabled':
        return const LogInAsGuestFailure(
          'This function has been disabled. Please contact support for help.',
        );
      default:
        return const LogInAsGuestFailure();
    }
  }

  /// The associated error message.
  final String message;
}

/// {@template reset_password_failure}
///Thrown during the reset password process if a failure occurs.
///https://pub.dev/documentation/firebase_auth/latest/firebase_auth/FirebaseAuth/sendPasswordResetEmail.html
///{@endtemplate}
class ResetPasswordFailure implements Exception {
  ///{@macro reset_password_failure}
  const ResetPasswordFailure([
    this.message = 'An unknown exception occurred.',
  ]);

  ///Create an authentication message
  ///from a firebase authentication exception code.
  factory ResetPasswordFailure.fromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return const ResetPasswordFailure(
          'Email is not valid or badly formatted.',
        );
      case 'user-not-found':
        return const ResetPasswordFailure(
          'Email is not found, check your spelling, or create an account.',
        );
      case 'missing-android-pkg-name':
        return const ResetPasswordFailure(
          'Missing Android package name.',
        );
      case 'missing-continue-uri':
        return const ResetPasswordFailure(
          'Missing continue URI.',
        );
      case 'missing-ios-bundle-id':
        return const ResetPasswordFailure(
          'Missing iOS bundle ID.',
        );
      case 'invalid-continue-uri':
        return const ResetPasswordFailure(
          'Invalid continue URI.',
        );
      case 'unauthorized-continue-uri':
        return const ResetPasswordFailure(
          'Unauthorized continue URI.',
        );

      default:
        return const ResetPasswordFailure();
    }
  }

  ///The associated error message.
  final String message;
}

/// {@template log_in_with_google_failure}
/// Thrown during the sign in with google process if a failure occurs.
/// https://pub.dev/documentation/firebase_auth/latest/firebase_auth/FirebaseAuth/signInWithCredential.html
/// {@endtemplate}
class LogInWithGoogleFailure implements Exception {
  /// {@macro log_in_with_google_failure}
  const LogInWithGoogleFailure([
    this.message = 'An unknown exception occurred.',
  ]);

  /// Create an authentication message
  /// from a firebase authentication exception code.
  factory LogInWithGoogleFailure.fromCode(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return const LogInWithGoogleFailure(
          'Account exists with different credentials.',
        );
      case 'invalid-credential':
        return const LogInWithGoogleFailure(
          'The credential received is malformed or has expired.',
        );
      case 'operation-not-allowed':
        return const LogInWithGoogleFailure(
          'Operation is not allowed.  Please contact support.',
        );
      case 'user-disabled':
        return const LogInWithGoogleFailure(
          'This user has been disabled. Please contact support for help.',
        );
      case 'user-not-found':
        return const LogInWithGoogleFailure(
          'Email is not found, please create an account.',
        );
      case 'wrong-password':
        return const LogInWithGoogleFailure(
          'Incorrect password, please try again.',
        );
      case 'invalid-verification-code':
        return const LogInWithGoogleFailure(
          'The credential verification code received is invalid.',
        );
      case 'invalid-verification-id':
        return const LogInWithGoogleFailure(
          'The credential verification ID received is invalid.',
        );
      default:
        return const LogInWithGoogleFailure();
    }
  }

  /// The associated error message.
  final String message;
}

/// Thrown during the logout process if a failure occurs.
class LogOutFailure implements Exception {}

/// {@template authentication_repository}
/// Repository which manages user authentication.
/// {@endtemplate}
class AuthenticationRepository {
  /// {@macro authentication_repository}
  AuthenticationRepository({
    CacheClient? cache,
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _cache = cache ?? CacheClient(),
        _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

  final CacheClient _cache;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Whether or not the current environment is web
  /// Should only be overriden for testing purposes. Otherwise,
  /// defaults to [kIsWeb]
  @visibleForTesting
  bool isWeb = kIsWeb;

  /// User cache key.
  /// Should only be used for testing purposes.
  @visibleForTesting
  static const userCacheKey = '__user_cache_key__';

// Caches the current Firebase user
  Future<void> _cacheCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      final user = firebaseUser.toAppUser();
      await _cacheUser(user!);
    } else {
      await _clearCachedUser();
    }
  }

  /// Saves the User object to cache
  Future<void> _cacheUser(User user) async {
    final userData = user.toJson();
    _cache.write(key: userCacheKey, value: userData);
  }

  /// Retrieves the cached user data
  User? getCachedUser() {
    final userData = _cache.read<Map<String, dynamic>>(key: userCacheKey);
    return userData != null ? User.fromJson(userData) : null;
  }

  /// Clears the cached user data
  Future<void> _clearCachedUser() async {
    debugPrint('Clearing cached user');
    _cache.remove(key: userCacheKey);
  }

  /// Stream of [User] which will emit the current user when
  /// the authentication state changes.
  ///
  /// Emits [User.empty] if the user is not authenticated.
  Stream<User?> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      final user = firebaseUser == null ? User.empty : firebaseUser.toAppUser();
      _cache.write<User>(key: userCacheKey, value: user!);
      return user;
    });
  }

  /// Returns the current cached user.
  /// Defaults to [User.empty] if there is no cached user.
  User get currentUser {
    return _cache.read<User>(key: userCacheKey) ?? User.empty;
  }

  /// Creates a new user with the provided [name] and [email] and [password].
  ///
  /// Throws a [SignUpWithEmailAndPasswordFailure] if an exception occurs.
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create user account
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Safely access the current user with null check
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('User not found after registration.');
      }

      // Update display name and reload user profile
      await currentUser.updateDisplayName(name);
      await currentUser.reload();

      //Cache the user
      await _cacheCurrentUser();

      // Send email verification
      await currentUser.sendEmailVerification();
      return currentUser.toAppUser();
      // Optionally, update the cache with the new user information if necessary
      // _cache.write(key: userCacheKey, value: currentUser);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw SignUpWithEmailAndPasswordFailure.fromCode(e.code);
    } catch (e) {
      // Log or handle other exceptions here
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Allow the user to sign in as a guest
  Future<User?> signInAsGuest() async {
    const guestUser = User(
      id: 'guest',
      email: '',
      name: 'Guest',
      // ignore: avoid_redundant_argument_values
      isGuest: true,
      // ignore: avoid_redundant_argument_values
      emailVerified: false,
    );
    return guestUser;
  }

  /// Starts the Sign In with Google Flow.
  ///
  /// Throws a [LogInWithGoogleFailure] if an exception occurs.
  Future<User?> logInWithGoogle() async {
    try {
      late final firebase_auth.AuthCredential credential;
      if (isWeb) {
        final googleProvider = firebase_auth.GoogleAuthProvider();
        final userCredential = await _firebaseAuth.signInWithPopup(
          googleProvider,
        );
        credential = userCredential.credential!;
      } else {
        final googleUser = await _googleSignIn.signIn();
        final googleAuth = await googleUser!.authentication;
        credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      }

      await _firebaseAuth.signInWithCredential(credential);
      // Cache the current user after successful Google sign-in
      await _cacheCurrentUser();
      return _firebaseAuth.currentUser?.toAppUser();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw LogInWithGoogleFailure.fromCode(e.code);
    } catch (_) {
      throw const LogInWithGoogleFailure();
    }
  }

  /// Signs in with the provided [email] and [password].
  ///
  /// Throws a [LogInWithEmailAndPasswordFailure] if an exception occurs.
  Future<User?> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cache the current user after successful login
      await _cacheCurrentUser();
      return _firebaseAuth.currentUser?.toAppUser();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw LogInWithEmailAndPasswordFailure.fromCode(e.code);
    } catch (_) {
      throw const LogInWithEmailAndPasswordFailure();
    }
  }

  ///Sends an [email] to the address provided
  ///to reset password
  Future<void> forgotPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Catch FirebaseAuthException and convert to ResetPasswordFailure
      throw ResetPasswordFailure.fromCode(e.code);
    } catch (e) {
      // Handle other types of exceptions
      throw const ResetPasswordFailure();
    }
  }

  /// Returns the current user's email verification status
  /// as a stream of [bool] values.
  Stream<bool> getEmailVerificationStatus() async* {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      yield user.emailVerified;
    }
    yield false;
  }

  /// Re send the email verification
  Future<void> resendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  /// Signs out the current user which will emit
  /// [User.empty] from the [user] Stream.
  ///
  /// Throws a [LogOutFailure] if an exception occurs.
  Future<void> logOut() async {
    debugPrint('Logging out');
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      // Clear the cached user on logout
      await _clearCachedUser();
    } catch (_) {
      throw LogOutFailure();
    }
  }

  /// Reloads the current user

  Future<void> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// Returns the current user's email verification status
  bool isEmailVerified() {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return user.emailVerified;
    }
    return false;
  }
}

/// Extension on [firebase_auth.User] to convert to [User]
extension UserConversion on firebase_auth.User? {
  /// Converts a [firebase_auth.User] to a [User]
  User? toAppUser() {
    final firebaseUser = this;
    if (firebaseUser == null) {
      return null;
    } else {
      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        photo: firebaseUser.photoURL,
        name: firebaseUser.displayName ?? '',
        isGuest: firebaseUser.isAnonymous,
        emailVerified: firebaseUser.emailVerified,
      );
    }
  }
}
