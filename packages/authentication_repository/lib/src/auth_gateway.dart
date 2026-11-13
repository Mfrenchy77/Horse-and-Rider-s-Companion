import 'package:authentication_repository/src/models/models.dart';

/// Backend-neutral interface for authentication and session management.
abstract interface class AuthGateway {
  /// Stream of authentication state changes, emitting [User.empty] when
  /// signed out.
  Stream<User?> get user;

  /// The most recently cached authenticated [User], or [User.empty].
  User get currentUser;

  /// Registers a new user with [name], [email], and [password].
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Creates or returns a guest [User] session.
  Future<User?> signInAsGuest();

  /// Signs in with Google across supported platforms.
  Future<User?> logInWithGoogle();

  /// Signs in with [email] and [password].
  Future<User?> logInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sends a password reset request for [email].
  Future<void> forgotPassword({required String email});

  /// Streams whether the current user's email is verified.
  Stream<bool> getEmailVerificationStatus();

  /// Re-sends the email verification message to the current user.
  Future<void> resendEmailVerification();

  /// Signs out of the current session.
  Future<void> logOut();

  /// Refreshes the current user's session/profile attributes from the backend.
  Future<void> reloadCurrentUser();

  /// Returns `true` if the current user's email address is verified.
  bool isEmailVerified();

  /// Returns a bearer access token for authenticated backend requests, or
  /// `null` if no user is signed in.
  Future<String?> getAccessToken();

  /// Reauthenticates the current email/password user before sensitive actions.
  Future<void> reauthenticateWithPassword({required String password});

  /// Reauthenticates the current Google user before sensitive actions.
  Future<void> reauthenticateWithGoogle();
}
