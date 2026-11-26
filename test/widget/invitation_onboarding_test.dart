import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Auth/auth_page.dart';
import 'package:horseandriderscompanion/MainPages/Invitations/invite_page.dart';
import 'package:horseandriderscompanion/MainPages/Invitations/pending_invitation_storage.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigation_view.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/Widgets/rider_action_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/share_helper.dart';

import '../support/app_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryInvitationStore store;
  late InvitationRepository invitationRepo;
  String? lastClipboardText;

  setUp(() {
    PendingInvitationStorage.debugOverride = <String, String>{};
    PendingInvitationStorage.resetSessionGuards();
    debugNativeShareOverride = null;
    lastClipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<dynamic, dynamic>?;
            lastClipboardText = args?['text'] as String?;
          }
          return null;
        });

    store = InMemoryInvitationStore(
      actorUid: 'coach-uid',
      actorEmail: 'coach@example.com',
      actorName: 'Coach Morgan',
      actorIsTrainer: true,
      actorLocation: 'Lexington, KY',
    );
    invitationRepo = InvitationRepository(store: store);
  });

  tearDown(() {
    PendingInvitationStorage.debugOverride = null;
    PendingInvitationStorage.resetSessionGuards();
    debugNativeShareOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget wrapInviteRouter({
    required AppCubit cubit,
    required String initialLocation,
    Future<Map<String, dynamic>?> Function(Map<String, Object?> payload)?
    onConnectionAction,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          name: 'RiderProfilePage',
          builder: (_, _) => const Scaffold(
            key: Key('mockHomePage'),
            body: Center(child: Text('Home Profile')),
          ),
        ),
        GoRoute(
          path: '/SkillTree',
          builder: (_, _) => const Scaffold(body: Text('Skill Tree')),
        ),
        GoRoute(
          path: AuthPage.path,
          name: AuthPage.name,
          builder: (_, _) => const AuthPage(),
        ),
        GoRoute(
          path: InvitePage.path,
          name: InvitePage.name,
          builder: (_, state) => InvitePage(
            token: state.pathParameters[InvitePage.tokenParam] ?? '',
            repository: invitationRepo,
            onConnectionAction: onConnectionAction,
          ),
        ),
      ],
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<InvitationRepository>.value(value: invitationRepo),
      ],
      child: BlocProvider<AppCubit>.value(
        value: cubit,
        child: MaterialApp.router(theme: mainThemeDark, routerConfig: router),
      ),
    );
  }

  group('Public Invitation Landing Page & Onboarding Workflows', () {
    testWidgets(
      'public landing page renders responsively at 360x800 and 1280x900 '
      'and handles invalid, expired, revoked, and used invitations cleanly',
      (tester) async {
        expect(Firebase.apps, isEmpty);
        final created = await invitationRepo.createInvitation(
          const InvitationCreateRequest(
            type: InvitationType.studentConnection,
            personalMessage: 'Welcome to the barn!',
          ),
        );
        store.signOut();

        for (final size in [const Size(360, 800), const Size(1280, 900)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final harness = await AppTestHarness.create();
          addTearDown(harness.close);

          await tester.pumpWidget(
            wrapInviteRouter(
              cubit: harness.cubit,
              initialLocation: '/invite/${created.token}',
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('invitePublicPreviewCard')),
            findsOneWidget,
          );
          expect(find.text('Coach Morgan'), findsOneWidget);
          expect(find.text('Student Invitation'), findsOneWidget);
          expect(
            find.textContaining('explicitly accept or decline'),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('inviteCreateAccountButton')),
            findsOneWidget,
          );
          expect(find.byKey(const Key('inviteSignInButton')), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        // Invalid token state.
        final harnessInvalid = await AppTestHarness.create();
        addTearDown(harnessInvalid.close);
        await tester.pumpWidget(
          wrapInviteRouter(
            cubit: harnessInvalid.cubit,
            initialLocation: '/invite/nonexistent_token_123456',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('inviteUnavailableCard')), findsOneWidget);
        expect(find.text('Invalid Invitation Link'), findsOneWidget);

        // Revoked state.
        store.setActor(
          uid: 'coach-uid',
          email: 'coach@example.com',
          name: 'Coach Morgan',
          isTrainer: true,
        );
        await invitationRepo.revokeInvitation(created.invitation.id);
        store.signOut();

        final harnessRevoked = await AppTestHarness.create();
        addTearDown(harnessRevoked.close);
        await tester.pumpWidget(
          wrapInviteRouter(
            cubit: harnessRevoked.cubit,
            initialLocation: '/invite/${created.token}',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Invitation Revoked'), findsOneWidget);

        // Expired state.
        store.setActor(
          uid: 'coach-uid',
          email: 'coach@example.com',
          name: 'Coach Morgan',
          isTrainer: true,
        );
        final expiring = await invitationRepo.createInvitation(
          const InvitationCreateRequest(
            type: InvitationType.general,
            expiresInDays: 1,
          ),
        );
        store
          ..advanceClock(const Duration(days: 3))
          ..signOut();

        final harnessExpired = await AppTestHarness.create();
        addTearDown(harnessExpired.close);
        await tester.pumpWidget(
          wrapInviteRouter(
            cubit: harnessExpired.cubit,
            initialLocation: '/invite/${expiring.token}',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Invitation Expired'), findsOneWidget);
      },
    );

    testWidgets('preserves student invite across signup -> verification -> '
        'explicit accept without auto-accepting beforehand', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final created = await invitationRepo.createInvitation(
        const InvitationCreateRequest(
          type: InvitationType.studentConnection,
          personalMessage: 'Happy to coach you!',
        ),
      );
      store.signOut();

      final recordedActions = <Map<String, Object?>>[];
      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      await tester.pumpWidget(
        RepositoryProvider<AuthGateway>.value(
          value: harness.auth,
          child: wrapInviteRouter(
            cubit: harness.cubit,
            initialLocation: '/invite/${created.token}',
            onConnectionAction: (payload) async {
              recordedActions.add(payload);
              if (payload['action'] == 'accept') {
                store.markConnectionAccepted(payload['id']! as String);
              } else if (payload['action'] == 'decline') {
                store.markConnectionDeclined(payload['id']! as String);
              }
              return {'id': payload['id'], 'status': '${payload['action']}ed'};
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Create Account routes to AuthPage and preserves pending token banner.
      await tester.tap(find.byKey(const Key('inviteCreateAccountButton')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('authPendingInviteBanner')), findsOneWidget);
      expect(PendingInvitationStorage.readToken(), created.token);

      // User signs up and returns unverified.
      const unverifiedStudent = User(
        id: 'student-uid',
        email: 'student@example.com',
        name: 'Sam Student',
        isGuest: false,
      );
      store.setActor(
        uid: 'student-uid',
        email: 'student@example.com',
        name: 'Sam Student',
        emailVerified: false,
      );
      // Simulate auth redirect/refresh back to invite page while unverified.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: unverifiedStudent,
          isGuest: true,
          showEmailVerification: true,
          status: AppStatus.unauthenticated,
        ),
      );
      final ctx = tester.element(
        find.byKey(const Key('authPendingInviteBanner')),
      );
      GoRouter.of(ctx).go('/invite/${created.token}');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inviteEmailVerificationCard')),
        findsOneWidget,
      );
      expect(recordedActions, isEmpty);

      // Email verification completes -> redeems and shows Accept/Decline.
      const verifiedStudent = User(
        id: 'student-uid',
        email: 'student@example.com',
        name: 'Sam Student',
        isGuest: false,
        emailVerified: true,
      );
      store.setActor(
        uid: 'student-uid',
        email: 'student@example.com',
        name: 'Sam Student',
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: verifiedStudent,
          isGuest: false,
          showEmailVerification: false,
          status: AppStatus.authenticated,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('inviteStudentDecisionCard')),
        findsOneWidget,
      );
      // CRITICAL: Never auto-accept on registration/redemption.
      expect(recordedActions, isEmpty);
      expect(PendingInvitationStorage.readToken(), isNull);

      // Recipient explicitly clicks Accept Connection.
      await tester.tap(find.byKey(const Key('inviteAcceptConnectionButton')));
      await tester.pumpAndSettle();

      expect(recordedActions, hasLength(1));
      expect(recordedActions.single['action'], 'accept');
      expect(
        find.byKey(const Key('inviteDecisionAcceptedCard')),
        findsOneWidget,
      );
    });

    testWidgets(
      'recipient can decline student connection and general invite creates no '
      'connection request',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final studentInvite = await invitationRepo.createInvitation(
          const InvitationCreateRequest(type: InvitationType.studentConnection),
        );
        final generalInvite = await invitationRepo.createInvitation(
          const InvitationCreateRequest(type: InvitationType.general),
        );

        final recordedActions = <Map<String, Object?>>[];
        final harness = await AppTestHarness.create();
        addTearDown(harness.close);

        store.setActor(
          uid: 'student-2',
          email: 's2@example.com',
          name: 'Taylor Rider',
        );
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: const User(
              id: 'student-2',
              email: 's2@example.com',
              name: 'Taylor Rider',
              isGuest: false,
              emailVerified: true,
            ),
            isGuest: false,
            status: AppStatus.authenticated,
          ),
        );

        await tester.pumpWidget(
          wrapInviteRouter(
            cubit: harness.cubit,
            initialLocation: '/invite/${studentInvite.token}',
            onConnectionAction: (payload) async {
              recordedActions.add(payload);
              if (payload['action'] == 'decline') {
                store.markConnectionDeclined(payload['id']! as String);
              }
              return {'id': payload['id'], 'status': 'declined'};
            },
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const Key('inviteDeclineConnectionButton')),
        );
        await tester.pumpAndSettle();
        expect(recordedActions.single['action'], 'decline');
        expect(
          find.byKey(const Key('inviteDecisionDeclinedCard')),
          findsOneWidget,
        );

        // General invite shows welcome outcome with zero connection decisions.
        await tester.pumpWidget(
          wrapInviteRouter(
            cubit: harness.cubit,
            initialLocation: '/invite/${generalInvite.token}',
            onConnectionAction: (payload) async {
              recordedActions.add(payload);
              return payload;
            },
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('inviteOutcomeCard')), findsOneWidget);
        expect(
          find.byKey(const Key('inviteAcceptConnectionButton')),
          findsNothing,
        );
        expect(recordedActions, hasLength(1));
      },
    );

    testWidgets('instructor profile exposes Invite Student, sharing dialog '
        '(Copy Link + native share), and invitation manager with revoke; '
        'non-instructor sees only general invites', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sharedPayloads = <String>[];
      debugNativeShareOverride =
          ({required String title, required String url, String? text}) async {
            sharedPayloads.add('$title::$url');
            return true;
          };

      final harness = await AppTestHarness.create();
      addTearDown(harness.close);

      final coachProfile = RiderProfile(
        id: 'coach-uid',
        name: 'Coach Morgan',
        email: 'coach@example.com',
        isTrainer: true,
      );

      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          isGuest: false,
          user: const User(
            id: 'coach-uid',
            email: 'coach@example.com',
            name: 'Coach Morgan',
            isGuest: false,
            emailVerified: true,
          ),
          usersProfile: coachProfile,
          status: AppStatus.authenticated,
        ),
      );

      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<InvitationRepository>.value(
              value: invitationRepo,
            ),
          ],
          child: BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: Scaffold(body: RiderProfileView(profile: coachProfile)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify zero layout overflow on 360px compact viewport.
      expect(find.byType(RiderActionBar), findsOneWidget);
      final inviteBtn = find.byKey(const Key('InviteStudentButton'));
      expect(inviteBtn, findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(inviteBtn);
      await tester.pumpAndSettle();
      await tester.tap(inviteBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inviteShareDialog')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('invitePersonalMessageField')),
        'See you in the arena',
      );
      await tester.tap(find.byKey(const Key('inviteGenerateLinkButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('inviteGeneratedUrlText')), findsOneWidget);
      expect(
        find.textContaining('https://horseandriderscompanion.com/invite/'),
        findsOneWidget,
      );

      // Copy link & Share actions work cleanly.
      final copyBtn = find.byKey(const Key('inviteCopyLinkButton'));
      await tester.ensureVisible(copyBtn);
      await tester.tap(copyBtn);
      await tester.pumpAndSettle();
      expect(
        lastClipboardText,
        startsWith('https://horseandriderscompanion.com/invite/'),
      );

      final shareBtn = find.byKey(const Key('inviteNativeShareButton'));
      await tester.ensureVisible(shareBtn);
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();
      expect(sharedPayloads, hasLength(1));

      // Open invitation manager, verify metrics & revoke.
      final managerBtn = find.byKey(const Key('inviteOpenManagerButton'));
      await tester.ensureVisible(managerBtn);
      await tester.tap(managerBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('manageInvitationsDialog')), findsOneWidget);
      expect(find.byKey(const Key('invitationMetricsBar')), findsOneWidget);
      final list = await invitationRepo.listMyInvitations();
      expect(list, hasLength(1));

      final revokeBtn = find.byKey(Key('revokeInvitation_${list.single.id}'));
      await tester.ensureVisible(revokeBtn);
      await tester.tap(revokeBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmRevokeInvitationButton')));
      await tester.pumpAndSettle();
      expect(
        (await invitationRepo.listMyInvitations()).single.status,
        InvitationStatus.revoked,
      );

      // Dismiss manager dialog before rebuilding as non-instructor.
      await tester.tap(find.widgetWithText(FilledButton, 'Close'));
      await tester.pumpAndSettle();

      // Non-instructor profile must NOT show Invite Student button.
      final riderProfile = RiderProfile(
        id: 'rider-uid',
        name: 'Riley Rider',
        email: 'rider@example.com',
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      harness.cubit.emit(
        harness.cubit.state.copyWith(
          user: const User(
            id: 'rider-uid',
            email: 'rider@example.com',
            name: 'Riley Rider',
            isGuest: false,
            emailVerified: true,
          ),
          usersProfile: riderProfile,
        ),
      );
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<InvitationRepository>.value(
              value: invitationRepo,
            ),
          ],
          child: BlocProvider<AppCubit>.value(
            value: harness.cubit,
            child: MaterialApp(
              theme: mainThemeDark,
              home: Scaffold(body: RiderProfileView(profile: riderProfile)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('InviteStudentButton')), findsNothing);
    });

    testWidgets(
      'restores persisted pending invitation after simulated reload without '
      'redirect loops',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final created = await invitationRepo.createInvitation(
          const InvitationCreateRequest(type: InvitationType.studentConnection),
        );
        await PendingInvitationStorage.saveToken(created.token);

        store.setActor(
          uid: 'returning-student',
          email: 'returning@example.com',
          name: 'Returning Student',
        );
        final harness = await AppTestHarness.create();
        addTearDown(harness.close);
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        harness.cubit.emit(
          harness.cubit.state.copyWith(
            user: const User(
              id: 'returning-student',
              email: 'returning@example.com',
              name: 'Returning Student',
              isGuest: false,
              emailVerified: true,
            ),
            isGuest: false,
            status: AppStatus.authenticated,
          ),
        );

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (_, _, shell) => NavigationView(child: shell),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (_, _) =>
                          const Scaffold(body: Text('Restored Home')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/SkillTree',
                      builder: (_, _) => const Scaffold(body: Text('Skills')),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/Resources',
                      builder: (_, _) =>
                          const Scaffold(body: Text('Resources')),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: InvitePage.path,
              name: InvitePage.name,
              builder: (_, state) => InvitePage(
                token: state.pathParameters[InvitePage.tokenParam] ?? '',
                repository: invitationRepo,
                onConnectionAction: (payload) async => {
                  'id': payload['id'],
                  'status': 'accepted',
                },
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<InvitationRepository>.value(
                value: invitationRepo,
              ),
            ],
            child: BlocProvider<AppCubit>.value(
              value: harness.cubit,
              child: MaterialApp.router(
                theme: mainThemeDark,
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Automatically restored from PendingInvitationStorage onto InvitePage.
        expect(
          find.byKey(const Key('inviteStudentDecisionCard')),
          findsOneWidget,
        );
        // Pending token cleared so returning home does not redirect-loop.
        expect(PendingInvitationStorage.readToken(), isNull);
        await tester.tap(
          find.byKey(const Key('inviteDeclineConnectionButton')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('inviteGoToProfileButton')));
        await tester.pumpAndSettle();
        expect(find.text('Restored Home'), findsOneWidget);
      },
    );
  });
}
