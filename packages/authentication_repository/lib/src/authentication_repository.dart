// ignore: lines_longer_than_80_chars
// ignore_for_file: avoid_print, public_member_api_docs, avoid_redundant_argument_values

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:cache/cache.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// -------------------- Error types (unchanged) --------------------

class SignUpWithEmailAndPasswordFailure implements Exception {
  const SignUpWithEmailAndPasswordFailure([
    this.message = 'An unknown exception occurred.',
  ]);
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
  final String message;
}

class LogInWithEmailAndPasswordFailure implements Exception {
  const LogInWithEmailAndPasswordFailure([
    this.message = 'An unknown exception occurred.',
  ]);
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
  final String message;
}

class LogInAsGuestFailure implements Exception {
  const LogInAsGuestFailure([
    this.message = 'An unknown exception occurred.',
  ]);
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
  final String message;
}

class ResetPasswordFailure implements Exception {
  const ResetPasswordFailure([
    this.message = 'An unknown exception occurred.',
  ]);
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
        return const ResetPasswordFailure('Missing Android package name.');
      case 'missing-continue-uri':
        return const ResetPasswordFailure('Missing continue URI.');
      case 'missing-ios-bundle-id':
        return const ResetPasswordFailure('Missing iOS bundle ID.');
      case 'invalid-continue-uri':
        return const ResetPasswordFailure('Invalid continue URI.');
      case 'unauthorized-continue-uri':
        return const ResetPasswordFailure('Unauthorized continue URI.');
      default:
        return const ResetPasswordFailure();
    }
  }
  final String message;
}

class LogInWithGoogleFailure implements Exception {
  const LogInWithGoogleFailure([
    this.message = 'An unknown exception occurred.',
  ]);
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
  final String message;
}

class LogOutFailure implements Exception {}

/// -------------------- Authentication Repository --------------------

class AuthenticationRepository {
  AuthenticationRepository({
    CacheClient? cache,
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn, // optional injection to match your main.dart
  })  : _cache = cache ?? CacheClient(),
        _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final CacheClient _cache;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @visibleForTesting
  bool isWeb = kIsWeb;

  @visibleForTesting
  static const userCacheKey = '__user_cache_key__';

  // Guard against double-initialization (plugin recommends init once).
  static bool _gsInitialized = false;

  /// Lazily ensure Google Sign-In is initialized (v7 requirement).
  /// If you already call `GoogleSignIn.instance.initialize(...)` in main()
  ///  this is a no-op.
  Future<void> _ensureGoogleInitialized() async {
    if (isWeb) return; // Not used for web popup flow.
    if (_gsInitialized) return;
    try {
      await GoogleSignIn.instance
          .initialize(); // clientId/serverClientId optional
      _gsInitialized = true;
    } catch (e) {
      // If already initialized elsewhere, or platform handled via plist/json, ignore.
      debugPrint('GoogleSignIn initialize() skipped/failed: $e');
      _gsInitialized = true; // Avoid retry storm.
    }
  }

  Future<void> _cacheCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      final user = firebaseUser.toAppUser();
      await _cacheUser(user!);
    } else {
      await _clearCachedUser();
    }
  }

  Future<void> _cacheUser(User user) async {
    final userData = user.toJson();
    _cache.write(key: userCacheKey, value: userData);
  }

  User? getCachedUser() {
    final userData = _cache.read<Map<String, dynamic>>(key: userCacheKey);
    return userData != null ? User.fromJson(userData) : null;
  }

  Future<void> _clearCachedUser() async {
    debugPrint('Clearing cached user');
    _cache.remove(key: userCacheKey);
  }

  Stream<User?> get user {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      final user = firebaseUser == null ? User.empty : firebaseUser.toAppUser();
      _cache.write<User>(key: userCacheKey, value: user!);
      return user;
    });
  }

  User get currentUser {
    return _cache.read<User>(key: userCacheKey) ?? User.empty;
  }

  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('User not found after registration.');
      }
      await currentUser.updateDisplayName(name);
      await currentUser.reload();
      await _cacheCurrentUser();
      await currentUser.sendEmailVerification();
      return currentUser.toAppUser();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw SignUpWithEmailAndPasswordFailure.fromCode(e.code);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<User?> signInAsGuest() async {
    const guestUser = User(
      id: 'guest',
      email: '',
      name: 'Guest',
      isGuest: true,
      emailVerified: false,
    );
    return guestUser;
  }

  /// Google sign-in across platforms.
  /// - Web: Firebase popup
  /// - Android/iOS/macOS: google_sign_in v7 authenticate() -> idToken -> Firebase credential
  Future<User?> logInWithGoogle() async {
    try {
      if (isWeb) {
        final provider = firebase_auth.GoogleAuthProvider();
        final userCred = await _firebaseAuth.signInWithPopup(provider);
        await _cacheCurrentUser();
        return userCred.user?.toAppUser();
      }

      // Native (Android/iOS/macOS)
      await _ensureGoogleInitialized();

      // Prefer authenticate() when supported (v7+ API).
      if (_googleSignIn.supportsAuthenticate()) {
        final account = await _googleSignIn.authenticate();
        final googleAuth = account.authentication; // idToken only in v7
        final credential = firebase_auth.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final userCred = await _firebaseAuth.signInWithCredential(credential);
        await _cacheCurrentUser();
        return userCred.user?.toAppUser();
      } else {
        // Extremely old platforms: fallback not expected in v7, but just in
        // case (Most clients should never hit this branch.)
        final account = await _googleSignIn.authenticate();
        final googleAuth = account.authentication;
        final credential = firebase_auth.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final userCred = await _firebaseAuth.signInWithCredential(credential);
        await _cacheCurrentUser();
        return userCred.user?.toAppUser();
      }
    } on GoogleSignInException catch (e) {
      // v7.1+ exposes structured codes (e.code is GoogleSignInExceptionCode)
      final msg = e.code.toString().contains('canceled')
          ? 'Sign-in canceled.'
          : 'Google sign-in failed.';
      throw LogInWithGoogleFailure(msg);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw LogInWithGoogleFailure.fromCode(e.code);
    } catch (_) {
      throw const LogInWithGoogleFailure();
    }
  }

  Future<User?> logInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _cacheCurrentUser();
      return cred.user?.toAppUser();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw LogInWithEmailAndPasswordFailure.fromCode(e.code);
    } catch (_) {
      throw const LogInWithEmailAndPasswordFailure();
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw ResetPasswordFailure.fromCode(e.code);
    } catch (_) {
      throw const ResetPasswordFailure();
    }
  }

  Stream<bool> getEmailVerificationStatus() async* {
    final user = _firebaseAuth.currentUser;
    if (user != null) yield user.emailVerified;
    yield false;
  }

  Future<void> resendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) await user.sendEmailVerification();
  }

  Future<void> logOut() async {
    debugPrint('Logging out');
    try {
      await _firebaseAuth.signOut();
      if (!isWeb) {
        // Sign out of Google so the account chooser shows next time.
        try {
          await _googleSignIn.signOut();
        } catch (_) {
          // ignore
        }
      }
      await _clearCachedUser();
    } catch (_) {
      throw LogOutFailure();
    }
  }

  Future<void> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) await user.reload();
  }

  bool isEmailVerified() {
    final user = _firebaseAuth.currentUser;
    return user?.emailVerified ?? false;
  }
}

/// Converts a [firebase_auth.User] to your app's [User] model.
extension UserConversion on firebase_auth.User? {
  User? toAppUser() {
    final firebaseUser = this;
    if (firebaseUser == null) return null;
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
