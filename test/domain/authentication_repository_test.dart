import 'package:authentication_repository/authentication_repository.dart';
import 'package:cache/cache.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements firebase.FirebaseAuth {}

class MockFirebaseUser extends Mock implements firebase.User {}

class MockCredential extends Mock implements firebase.UserCredential {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late MockFirebaseAuth auth;
  late MockFirebaseUser user;
  late MockCredential credential;
  late MockGoogleSignIn google;
  late CacheClient cache;
  late AuthenticationRepository repository;

  setUp(() {
    auth = MockFirebaseAuth();
    user = MockFirebaseUser();
    credential = MockCredential();
    google = MockGoogleSignIn();
    cache = CacheClient();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('rider@example.com');
    when(() => user.displayName).thenReturn('Rider');
    when(() => user.photoURL).thenReturn(null);
    when(() => user.isAnonymous).thenReturn(false);
    when(() => user.emailVerified).thenReturn(true);
    when(() => auth.currentUser).thenReturn(user);
    when(() => credential.user).thenReturn(user);
    repository = AuthenticationRepository(
      cache: cache,
      firebaseAuth: auth,
      googleSignIn: google,
    );
  });

  test('starts without a current user', () {
    expect(repository.currentUser, User.empty);
    expect(repository.getCachedUser(), isNull);
  });

  test('auth stream and both cache readers agree', () async {
    when(auth.userChanges).thenAnswer((_) => Stream.value(user));
    final result = await repository.user.first;
    expect(result?.email, 'rider@example.com');
    expect(result?.isGuest, isFalse);
    expect(repository.currentUser, result);
    expect(repository.getCachedUser(), result);
  });

  test('login populates both cache readers immediately', () async {
    when(
      () => auth.signInWithEmailAndPassword(
        email: 'rider@example.com',
        password: 'secret',
      ),
    ).thenAnswer((_) async => credential);
    final result = await repository.logInWithEmailAndPassword(
      email: 'rider@example.com',
      password: 'secret',
    );
    expect(repository.currentUser, result);
    expect(repository.getCachedUser(), result);
  });

  for (final code in [
    'invalid-email',
    'wrong-password',
    'invalid-credential',
    'user-disabled',
    'unknown',
  ]) {
    test('login maps Firebase error $code', () async {
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(firebase.FirebaseAuthException(code: code));
      await expectLater(
        repository.logInWithEmailAndPassword(
          email: 'a@b.com',
          password: 'secret',
        ),
        throwsA(isA<LogInWithEmailAndPasswordFailure>()),
      );
    });
  }

  test(
    'signup updates name, sends verification and caches without reloading',
    () async {
      when(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => credential);
      when(() => user.updateDisplayName('Rider')).thenAnswer((_) async {});
      when(user.sendEmailVerification).thenAnswer((_) async {});
      final result = await repository.signUp(
        name: 'Rider',
        email: 'rider@example.com',
        password: 'secret',
      );
      verifyInOrder([
        () => user.updateDisplayName('Rider'),
        user.sendEmailVerification,
      ]);
      verifyNever(user.reload);
      expect(repository.currentUser, result);
      expect(repository.getCachedUser(), result);
    },
  );

  test('native Google sign-in checks support before authenticating', () async {
    repository.isWeb = false;
    when(google.supportsAuthenticate).thenReturn(false);
    await expectLater(
      repository.logInWithGoogle(),
      throwsA(
        isA<LogInWithGoogleFailure>().having(
          (error) => error.message,
          'message',
          contains('unavailable'),
        ),
      ),
    );
    verifyNever(() => google.authenticate());
    verifyZeroInteractions(auth);
  });

  test('native Google sign-in exchanges the injected account token', () async {
    repository.isWeb = false;
    final account = MockGoogleAccount();
    when(google.supportsAuthenticate).thenReturn(true);
    when(() => google.authenticate()).thenAnswer((_) async => account);
    when(() => account.authentication).thenReturn(
      const GoogleSignInAuthentication(idToken: 'test-token'),
    );
    registerFallbackValue(
      firebase.GoogleAuthProvider.credential(idToken: 'fallback'),
    );
    when(() => auth.signInWithCredential(any()))
        .thenAnswer((_) async => credential);

    expect((await repository.logInWithGoogle())?.id, 'u1');
    final sent = verify(() => auth.signInWithCredential(captureAny()))
        .captured
        .single as firebase.OAuthCredential;
    expect(sent.idToken, 'test-token');
    verify(() => google.authenticate()).called(1);
  });

  test('web Google sign-in uses the Firebase popup', () async {
    repository.isWeb = true;
    registerFallbackValue(firebase.GoogleAuthProvider());
    when(() => auth.signInWithPopup(any())).thenAnswer((_) async => credential);
    final result = await repository.logInWithGoogle();
    expect(result?.id, 'u1');
    verify(() => auth.signInWithPopup(any())).called(1);
    verifyZeroInteractions(google);
  });

  test('signup maps duplicate accounts', () async {
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(firebase.FirebaseAuthException(code: 'email-already-in-use'));
    await expectLater(
      repository.signUp(
        name: 'Rider',
        email: 'rider@example.com',
        password: 'secret',
      ),
      throwsA(isA<SignUpWithEmailAndPasswordFailure>()),
    );
  });

  test('guest login returns a guest without calling Firebase', () async {
    final guest = await repository.signInAsGuest();
    expect(guest?.isGuest, isTrue);
    expect(guest?.emailVerified, isFalse);
    verifyZeroInteractions(auth);
  });

  test('password reset delegates to Firebase', () async {
    when(() => auth.sendPasswordResetEmail(email: 'rider@example.com'))
        .thenAnswer((_) async {});
    await repository.forgotPassword(email: 'rider@example.com');
    verify(() => auth.sendPasswordResetEmail(email: 'rider@example.com'))
        .called(1);
  });

  test('password reset maps errors', () async {
    when(() => auth.sendPasswordResetEmail(email: any(named: 'email')))
        .thenThrow(firebase.FirebaseAuthException(code: 'invalid-email'));
    await expectLater(
      repository.forgotPassword(email: 'bad'),
      throwsA(isA<ResetPasswordFailure>()),
    );
  });

  test('verified status stream does not revert to false', () async {
    expect(await repository.getEmailVerificationStatus().toList(), [true]);
  });

  test('signed out status is false', () async {
    when(() => auth.currentUser).thenReturn(null);
    expect(repository.isEmailVerified(), isFalse);
    expect(await repository.getEmailVerificationStatus().toList(), [false]);
    await repository.resendEmailVerification();
    await repository.reloadCurrentUser();
    verifyZeroInteractions(user);
  });

  test('reload and resend verification delegate to current user', () async {
    when(user.reload).thenAnswer((_) async {});
    when(user.sendEmailVerification).thenAnswer((_) async {});
    await repository.reloadCurrentUser();
    await repository.resendEmailVerification();
    verify(user.reload).called(1);
    verify(user.sendEmailVerification).called(1);
  });

  test('logout clears cached identity even if Google signout fails', () async {
    cache.write(
      key: AuthenticationRepository.userCacheKey,
      value: const User(id: 'u1', name: 'Rider', email: 'rider@example.com'),
    );
    when(auth.signOut).thenAnswer((_) async {});
    when(google.signOut).thenThrow(Exception('Google unavailable'));
    await repository.logOut();
    expect(repository.currentUser, User.empty);
    expect(repository.getCachedUser(), isNull);
  });

  test('logout reports Firebase failure', () async {
    when(auth.signOut).thenThrow(Exception('offline'));
    await expectLater(repository.logOut(), throwsA(isA<LogOutFailure>()));
  });

  test('guest flag participates in user identity', () {
    expect(
      const User(id: 'u', name: 'Rider', email: 'a@b.com', isGuest: false),
      isNot(const User(id: 'u', name: 'Rider', email: 'a@b.com')),
    );
  });

  test('user JSON round trip preserves authentication flags', () {
    const value = User(
      id: 'u',
      name: 'Rider',
      email: 'a@b.com',
      isGuest: false,
      emailVerified: true,
      photo: 'https://example.com/photo.png',
    );
    expect(User.fromJson(value.toJson()), value);
  });
}
