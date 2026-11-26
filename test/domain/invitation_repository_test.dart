import 'package:database_repository/database_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/MainPages/Invitations/pending_invitation_storage.dart';
import 'package:horseandriderscompanion/Utilities/share_helper.dart';

void main() {
  group('Invitation domain models & InMemoryInvitationStore (no Firebase)', () {
    late InMemoryInvitationStore store;
    late InvitationRepository repo;

    setUp(() {
      store = InMemoryInvitationStore(
        actorUid: 'coach-1',
        actorEmail: 'coach@example.com',
        actorName: 'Coach Morgan',
        actorIsTrainer: true,
        actorPhotoUrl: 'https://cdn.example.org/coach.jpg',
        actorLocation: 'Ocala, FL',
      );
      repo = InvitationRepository(store: store);
    });

    test('runs completely without Firebase and enforces trainer gating, '
        'expiration, revocation, self-invite, and idempotency', () async {
      expect(Firebase.apps, isEmpty);

      // General invite works for non-trainers too.
      store.setActor(
        uid: 'rider-1',
        email: 'rider@example.com',
        name: 'Riley Rider',
      );
      await expectLater(
        () => repo.createInvitation(
          const InvitationCreateRequest(type: InvitationType.studentConnection),
        ),
        throwsA(isA<InvitationException>()),
      );
      final generalCreated = await repo.createInvitation(
        const InvitationCreateRequest(
          type: InvitationType.general,
          personalMessage: 'Join us!',
        ),
      );
      expect(generalCreated.invitation.type, InvitationType.general);

      // Student invite works for trainer and exposes public preview signed out.
      store.setActor(
        uid: 'coach-1',
        email: 'coach@example.com',
        name: 'Coach Morgan',
        isTrainer: true,
      );
      final studentCreated = await repo.createInvitation(
        const InvitationCreateRequest(
          type: InvitationType.studentConnection,
          personalMessage: 'See you at Tuesday lesson',
        ),
      );
      store.signOut();
      final preview = await repo.getInvitationPreview(studentCreated.token);
      expect(preview.tokenValid, isTrue);
      expect(preview.status, InvitationStatus.pending);
      expect(preview.inviterDisplayName, 'Coach Morgan');
      expect(preview.inviterIsTrainer, isTrue);
      expect(preview.canRedeem, isTrue);

      // Self-invite is blocked.
      store.setActor(
        uid: 'coach-1',
        email: 'coach@example.com',
        name: 'Coach Morgan',
        isTrainer: true,
      );
      await expectLater(
        () => repo.redeemInvitation(studentCreated.token),
        throwsA(isA<InvitationException>()),
      );

      // Student redeems: creates pending connection without accepting.
      store.setActor(
        uid: 'student-1',
        email: 'student@example.com',
        name: 'Alex Student',
      );
      final firstRedeem = await repo.redeemInvitation(studentCreated.token);
      expect(
        firstRedeem.outcome,
        InvitationRedemptionOutcome.pendingConnectionCreated,
      );
      expect(firstRedeem.requiresConnectionDecision, isTrue);

      // Repeat redemption is idempotent.
      final secondRedeem = await repo.redeemInvitation(studentCreated.token);
      expect(
        secondRedeem.outcome,
        InvitationRedemptionOutcome.pendingConnectionExisting,
      );

      // Explicit accept updates invite status & metrics cleanly.
      store.markConnectionAccepted(firstRedeem.connectionId!);
      final afterAccept = await repo.redeemInvitation(studentCreated.token);
      expect(afterAccept.outcome, InvitationRedemptionOutcome.alreadyConnected);

      store.setActor(
        uid: 'coach-1',
        email: 'coach@example.com',
        name: 'Coach Morgan',
        isTrainer: true,
      );
      final listed = await repo.listMyInvitations();
      expect(listed, hasLength(1));
      expect(listed.single.status, InvitationStatus.accepted);
      expect(listed.single.recipientDisplayName, 'Alex Student');
      final summary = InvitationMetricsSummary.fromInvitations(listed);
      expect(summary.studentInvitesAccepted, 1);

      // Accepted invite cannot be revoked.
      await expectLater(
        () => repo.revokeInvitation(studentCreated.invitation.id),
        throwsA(isA<InvitationException>()),
      );

      // Expiring invite.
      final shortLived = await repo.createInvitation(
        const InvitationCreateRequest(
          type: InvitationType.general,
          expiresInDays: 1,
        ),
      );
      store.advanceClock(const Duration(days: 2));
      final expiredPreview = await repo.getInvitationPreview(shortLived.token);
      expect(expiredPreview.status, InvitationStatus.expired);
      expect(expiredPreview.canRedeem, isFalse);
    });
  });

  group('Invitation link formatting and PendingInvitationStorage', () {
    setUp(() {
      PendingInvitationStorage.debugOverride = <String, String>{};
      PendingInvitationStorage.resetSessionGuards();
    });

    tearDown(() {
      PendingInvitationStorage.debugOverride = null;
      PendingInvitationStorage.resetSessionGuards();
    });

    test('builds canonical horseandriderscompanion.com/invite/{token} URLs '
        'and personalized messages', () {
      expect(
        buildInvitationShareUrl('abc123token_789012'),
        'https://horseandriderscompanion.com/invite/abc123token_789012',
      );
      expect(
        buildInvitationShareUrl(
          'abc123token_789012',
          baseUri: Uri.parse('http://localhost:8080/invite/foo'),
        ),
        'http://localhost:8080/invite/abc123token_789012',
      );
      final msg = buildInvitationShareMessage(
        type: InvitationType.studentConnection,
        inviterName: 'Coach Morgan',
        url: 'https://horseandriderscompanion.com/invite/abc123token_789012',
        personalMessage: 'Welcome to lessons!',
      );
      expect(
        msg,
        contains('Coach Morgan invited you to connect as their student'),
      );
      expect(msg, contains('Welcome to lessons!'));
      expect(
        msg,
        contains(
          'https://horseandriderscompanion.com/invite/abc123token_789012',
        ),
      );
    });

    test(
      'persists pending token across simulated reload and expires stale tokens',
      () async {
        final t0 = DateTime.utc(2026, 11, 25, 10);
        await PendingInvitationStorage.saveToken(
          'invite_token_123456',
          now: t0,
        );
        expect(
          PendingInvitationStorage.readToken(
            now: t0.add(const Duration(hours: 2)),
          ),
          'invite_token_123456',
        );
        expect(
          PendingInvitationStorage.readToken(
            now: t0.add(const Duration(days: 8)),
          ),
          isNull,
        );

        expect(
          PendingInvitationStorage.shouldAutoRedirect(
            uid: 'u1',
            token: 'invite_token_123456',
          ),
          isTrue,
        );
        PendingInvitationStorage.markAutoRedirected(
          uid: 'u1',
          token: 'invite_token_123456',
        );
        expect(
          PendingInvitationStorage.shouldAutoRedirect(
            uid: 'u1',
            token: 'invite_token_123456',
          ),
          isFalse,
        );

        await PendingInvitationStorage.clearToken();
        expect(PendingInvitationStorage.readToken(now: t0), isNull);
      },
    );
  });
}
