import 'package:database_repository/src/models/invitation.dart';

/// Backend-neutral interface for creating, previewing, redeeming, listing,
/// and revoking onboarding and coaching invitations.
abstract interface class InvitationStore {
  /// Fetches public preview metadata for an invitation [token] without
  /// requiring authentication.
  Future<InvitationPreview> getInvitationPreview(String token);

  /// Creates a new invitation owned by the currently authenticated user.
  Future<InvitationCreateResult> createInvitation(
    InvitationCreateRequest request,
  );

  /// Redeems an invitation [token] on behalf of the authenticated user.
  Future<InvitationRedemptionResult> redeemInvitation(String token);

  /// Lists invitations created by the currently authenticated user.
  Future<List<InvitationRecord>> listMyInvitations();

  /// Revokes an invitation created by the currently authenticated user.
  Future<InvitationRecord> revokeInvitation(String invitationId);
}

/// Repository facade coordinating invitation operations over [InvitationStore].
class InvitationRepository implements InvitationStore {
  /// Creates an [InvitationRepository] backed by [store].
  // ignore: prefer_initializing_formals
  const InvitationRepository({required InvitationStore store}) : _store = store;

  final InvitationStore _store;

  @override
  Future<InvitationPreview> getInvitationPreview(String token) =>
      _store.getInvitationPreview(token);

  @override
  Future<InvitationCreateResult> createInvitation(
    InvitationCreateRequest request,
  ) => _store.createInvitation(request);

  @override
  Future<InvitationRedemptionResult> redeemInvitation(String token) =>
      _store.redeemInvitation(token);

  @override
  Future<List<InvitationRecord>> listMyInvitations() =>
      _store.listMyInvitations();

  @override
  Future<InvitationRecord> revokeInvitation(String invitationId) =>
      _store.revokeInvitation(invitationId);
}

class _InMemoryInvitationEntry {
  _InMemoryInvitationEntry({
    required this.id,
    required this.token,
    required this.inviterUid,
    required this.inviterEmail,
    required this.inviterDisplayName,
    required this.inviterPhotoUrl,
    required this.inviterIsTrainer,
    required this.inviterLocation,
    required this.type,
    required this.maxUses,
    required this.createdAt,
    required this.expiresAt,
    this.personalMessage,
  });

  final String id;
  final String token;
  final String inviterUid;
  final String inviterEmail;
  String inviterDisplayName;
  String? inviterPhotoUrl;
  bool inviterIsTrainer;
  String? inviterLocation;
  final InvitationType type;
  final String? personalMessage;
  final int maxUses;
  final DateTime createdAt;
  final DateTime expiresAt;
  DateTime? revokedAt;
  String? claimedByUid;
  String? recipientDisplayName;
  String? connectionId;
  String? connectionVersion;
  String? connectionStatus;
  final Set<String> redeemedUids = {};

  InvitationStatus derivedStatus(DateTime now) {
    if (revokedAt != null) return InvitationStatus.revoked;
    if (type == InvitationType.studentConnection) {
      if (connectionStatus == 'accepted') return InvitationStatus.accepted;
      if (connectionStatus == 'declined') return InvitationStatus.declined;
      if (claimedByUid != null) return InvitationStatus.registered;
      if (now.isAfter(expiresAt)) return InvitationStatus.expired;
      return InvitationStatus.pending;
    }
    if (redeemedUids.length >= maxUses) return InvitationStatus.used;
    if (now.isAfter(expiresAt)) return InvitationStatus.expired;
    return InvitationStatus.active;
  }

  InvitationRecord toRecord(DateTime now) {
    final isStudent = type == InvitationType.studentConnection;
    return InvitationRecord(
      id: id,
      type: type,
      status: derivedStatus(now),
      relationshipRole: isStudent ? 'student' : null,
      personalMessage: personalMessage,
      createdAt: createdAt,
      expiresAt: expiresAt,
      revokedAt: revokedAt,
      maxUses: maxUses,
      redemptionCount: redeemedUids.length,
      acceptedCount: connectionStatus == 'accepted' ? 1 : 0,
      declinedCount: connectionStatus == 'declined' ? 1 : 0,
      connectionId: isStudent ? connectionId : null,
      connectionStatus: isStudent ? connectionStatus : null,
      recipientDisplayName: isStudent && claimedByUid != null
          ? recipientDisplayName
          : null,
    );
  }
}

/// Deterministic in-memory [InvitationStore] for domain and widget tests.
class InMemoryInvitationStore implements InvitationStore {
  /// Creates an [InMemoryInvitationStore].
  InMemoryInvitationStore({
    this.actorUid = 'actor-1',
    this.actorEmail = 'actor@example.com',
    this.actorName = 'Actor Rider',
    this.actorPhotoUrl,
    this.actorIsTrainer = false,
    this.actorEmailVerified = true,
    this.actorHasProfile = true,
    this.actorLocation,
    DateTime Function()? now,
  }) : _clockBase = now?.call() ?? DateTime.utc(2026, 11, 25, 12);

  /// Maximum creations allowed per user in a rolling 24-hour window.
  static const int maxCreatesPer24Hours = 20;

  /// Maximum fresh redemptions allowed per user in a rolling 24-hour window.
  static const int maxRedeemsPer24Hours = 30;

  static final RegExp _tokenRegex = RegExp(r'^[A-Za-z0-9_-]{16,128}$');

  final Map<String, _InMemoryInvitationEntry> _byId = {};
  final Map<String, String> _tokenToId = {};
  final Map<String, List<DateTime>> _createHistory = {};
  final Map<String, List<DateTime>> _redeemHistory = {};
  final Set<String> _acceptedPairs = {};
  final DateTime _clockBase;
  Duration _clockOffset = Duration.zero;
  int _counter = 0;

  /// Current simulated signed-in user ID (empty means signed out).
  String actorUid;

  /// Current simulated signed-in email.
  String actorEmail;

  /// Current simulated display name.
  String actorName;

  /// Optional public photo URL for the active actor.
  String? actorPhotoUrl;

  /// Whether the active actor is marked as an instructor/trainer.
  bool actorIsTrainer;

  /// Whether the active actor's email is verified.
  bool actorEmailVerified;

  /// Whether the active actor has completed a rider profile.
  bool actorHasProfile;

  /// Optional public location for the active actor.
  String? actorLocation;

  /// Optional callback invoked when redeeming a student invite prepares a
  /// pending connection so tests can sync local fixtures or request stores.
  Future<void> Function({
    required String connectionId,
    required String connectionVersion,
    required String coachUid,
    required String coachEmail,
    required String coachName,
    required String learnerUid,
    required String learnerEmail,
    required String learnerName,
    required String invitationId,
    String? personalMessage,
  })?
  onPendingConnectionPrepared;

  DateTime get _now => _clockBase.add(_clockOffset);

  /// Advances the simulated clock by [delta].
  void advanceClock(Duration delta) {
    _clockOffset += delta;
  }

  /// Switches the active authenticated identity cleanly in tests.
  void setActor({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
    bool isTrainer = false,
    bool emailVerified = true,
    bool hasProfile = true,
    String? location,
  }) {
    actorUid = uid;
    actorEmail = email;
    actorName = name;
    actorPhotoUrl = photoUrl;
    actorIsTrainer = isTrainer;
    actorEmailVerified = emailVerified;
    actorHasProfile = hasProfile;
    actorLocation = location;
  }

  /// Clears the active authenticated identity (simulates signed-out visitor).
  void signOut() {
    actorUid = '';
    actorEmail = '';
    actorName = '';
    actorPhotoUrl = null;
    actorIsTrainer = false;
    actorEmailVerified = false;
    actorHasProfile = false;
    actorLocation = null;
  }

  /// Seeds an already-accepted coach/student pair before redemption.
  void seedAcceptedConnection({
    required String coachUid,
    required String learnerUid,
  }) {
    _acceptedPairs.add('$coachUid::$learnerUid');
  }

  /// Simulates recipient acceptance on [connectionId] and syncs invitation
  /// metrics/status.
  void markConnectionAccepted(String connectionId) {
    for (final entry in _byId.values) {
      if (entry.connectionId == connectionId) {
        entry.connectionStatus = 'accepted';
        if (entry.claimedByUid != null) {
          _acceptedPairs.add('${entry.inviterUid}::${entry.claimedByUid}');
        }
      }
    }
  }

  /// Simulates recipient decline on [connectionId] and syncs invitation
  /// metrics/status.
  void markConnectionDeclined(String connectionId) {
    for (final entry in _byId.values) {
      if (entry.connectionId == connectionId) {
        entry.connectionStatus = 'declined';
      }
    }
  }

  void _requireVerifiedActor() {
    if (actorUid.isEmpty || actorEmail.trim().isEmpty || !actorEmailVerified) {
      throw const InvitationException(
        'Sign in with a verified email first.',
        code: 'unauthenticated',
      );
    }
  }

  String _hashInt(int seq) => seq.toRadixString(16).padLeft(16, '0');

  @override
  Future<InvitationPreview> getInvitationPreview(String token) async {
    final normalized = token.trim();
    if (!_tokenRegex.hasMatch(normalized)) {
      return const InvitationPreview(
        tokenValid: false,
        status: InvitationStatus.invalid,
        canRedeem: false,
        statusMessage: 'This invitation link is not valid.',
      );
    }
    final invId = _tokenToId[normalized];
    final entry = invId == null ? null : _byId[invId];
    if (entry == null) {
      return const InvitationPreview(
        tokenValid: false,
        status: InvitationStatus.invalid,
        canRedeem: false,
        statusMessage: 'This invitation link is not valid.',
      );
    }

    final now = _now;
    final derived = entry.derivedStatus(now);
    final isStudent = entry.type == InvitationType.studentConnection;
    var status = derived;
    var canRedeem = false;
    var message = '';

    if (entry.revokedAt != null) {
      status = InvitationStatus.revoked;
      message = 'This invitation has been revoked by the sender.';
    } else if (isStudent) {
      if (entry.claimedByUid != null) {
        if (actorUid.isNotEmpty && actorUid == entry.claimedByUid) {
          canRedeem = true;
          status = derived;
          message = derived == InvitationStatus.accepted
              ? 'You are connected with ${entry.inviterDisplayName}.'
              : derived == InvitationStatus.declined
              ? 'You previously declined this student connection request.'
              : "Continue reviewing ${entry.inviterDisplayName}'s "
                    'student connection request.';
        } else {
          status = InvitationStatus.used;
          message = 'This student invitation has already been claimed.';
        }
      } else if (now.isAfter(entry.expiresAt)) {
        status = InvitationStatus.expired;
        message =
            'This invitation link has expired. Ask the instructor to send '
            'a new one.';
      } else if (!entry.inviterIsTrainer) {
        status = InvitationStatus.revoked;
        message = 'This instructor invitation is no longer available.';
      } else {
        status = InvitationStatus.pending;
        canRedeem = true;
        message =
            '${entry.inviterDisplayName} invited you to connect as their '
            'student. After signing in, you can review and accept or decline '
            'the connection request.';
      }
    } else {
      if (entry.redeemedUids.length >= entry.maxUses) {
        status = InvitationStatus.used;
        message = 'This invitation link has reached its usage limit.';
      } else if (now.isAfter(entry.expiresAt)) {
        status = InvitationStatus.expired;
        message = 'This invitation link has expired.';
      } else {
        status = InvitationStatus.active;
        canRedeem = true;
        message =
            '${entry.inviterDisplayName} invited you to join '
            "Horse & Rider's Companion.";
      }
    }

    return InvitationPreview(
      tokenValid: true,
      status: status,
      type: entry.type,
      relationshipRole: isStudent ? 'student' : null,
      inviterDisplayName: entry.inviterDisplayName,
      inviterPhotoUrl: entry.inviterPhotoUrl,
      inviterIsTrainer: entry.inviterIsTrainer,
      inviterLocation: entry.inviterLocation,
      personalMessage: entry.personalMessage,
      expiresAt: entry.expiresAt,
      canRedeem: canRedeem,
      statusMessage: message,
    );
  }

  @override
  Future<InvitationCreateResult> createInvitation(
    InvitationCreateRequest request,
  ) async {
    _requireVerifiedActor();
    if (!actorHasProfile) {
      throw const InvitationException(
        'Complete your rider profile before creating invitations.',
        code: 'failed-precondition',
      );
    }
    final isStudent = request.type == InvitationType.studentConnection;
    if (isStudent && !actorIsTrainer) {
      throw const InvitationException(
        'Only instructors and trainers can create student invitations.',
        code: 'permission-denied',
      );
    }
    final trimmedNote = request.personalMessage?.trim();
    if (trimmedNote != null && trimmedNote.length > 200) {
      throw const InvitationException(
        'Personal message must be 200 characters or fewer.',
        code: 'invalid-argument',
      );
    }

    final now = _now;
    final cutoff = now.subtract(const Duration(hours: 24));
    final recent = (_createHistory[actorUid] ?? <DateTime>[])
        .where((t) => !t.isBefore(cutoff))
        .toList();
    if (recent.length >= maxCreatesPer24Hours) {
      throw const InvitationException(
        'Daily invitation creation limit reached. Try again later.',
        code: 'resource-exhausted',
      );
    }
    _createHistory[actorUid] = [...recent, now];

    final seq = ++_counter;
    final id = 'inv_${_hashInt(seq)}';
    final token = 'invite_token_${_hashInt(seq)}_hrc';
    final ttlDays = request.expiresInDays ?? (isStudent ? 14 : 30);
    final maxUses = isStudent ? 1 : (request.maxUses ?? 25);

    final entry = _InMemoryInvitationEntry(
      id: id,
      token: token,
      inviterUid: actorUid,
      inviterEmail: actorEmail.trim().toLowerCase(),
      inviterDisplayName: actorName.trim().isNotEmpty
          ? actorName.trim()
          : actorEmail,
      inviterPhotoUrl: actorPhotoUrl,
      inviterIsTrainer: actorIsTrainer,
      inviterLocation: actorLocation,
      type: request.type,
      personalMessage: (trimmedNote == null || trimmedNote.isEmpty)
          ? null
          : trimmedNote,
      maxUses: maxUses,
      createdAt: now,
      expiresAt: now.add(Duration(days: ttlDays)),
    );
    _byId[id] = entry;
    _tokenToId[token] = id;

    return InvitationCreateResult(
      invitation: entry.toRecord(now),
      token: token,
      sharePath: '/invite/$token',
    );
  }

  @override
  Future<InvitationRedemptionResult> redeemInvitation(String token) async {
    _requireVerifiedActor();
    final normalized = token.trim();
    final invId = _tokenToId[normalized];
    final entry = invId == null ? null : _byId[invId];
    if (!_tokenRegex.hasMatch(normalized) || entry == null) {
      throw const InvitationException(
        'This invitation link is not valid.',
        code: 'not-found',
      );
    }

    if (entry.inviterUid == actorUid ||
        entry.inviterEmail == actorEmail.trim().toLowerCase()) {
      throw const InvitationException(
        'You cannot redeem your own invitation link.',
        code: 'failed-precondition',
      );
    }

    final isStudent = entry.type == InvitationType.studentConnection;
    if (entry.redeemedUids.contains(actorUid)) {
      if (!isStudent) {
        return InvitationRedemptionResult(
          invitationId: entry.id,
          type: entry.type,
          outcome: InvitationRedemptionOutcome.alreadyRedeemedGeneral,
          inviterDisplayName: entry.inviterDisplayName,
          inviterPhotoUrl: entry.inviterPhotoUrl,
          message: 'You have already joined using this invitation.',
        );
      }
      if (entry.connectionStatus == 'accepted') {
        return InvitationRedemptionResult(
          invitationId: entry.id,
          type: entry.type,
          outcome: InvitationRedemptionOutcome.alreadyConnected,
          inviterDisplayName: entry.inviterDisplayName,
          inviterPhotoUrl: entry.inviterPhotoUrl,
          connectionId: entry.connectionId,
          connectionVersion: entry.connectionVersion,
          connectionStatus: 'accepted',
          message:
              'You are already connected with ${entry.inviterDisplayName}.',
        );
      }
      if (entry.connectionStatus == 'pending') {
        return InvitationRedemptionResult(
          invitationId: entry.id,
          type: entry.type,
          outcome: InvitationRedemptionOutcome.pendingConnectionExisting,
          inviterDisplayName: entry.inviterDisplayName,
          inviterPhotoUrl: entry.inviterPhotoUrl,
          connectionId: entry.connectionId,
          connectionVersion: entry.connectionVersion,
          connectionStatus: 'pending',
          requestDocId: entry.connectionId,
          message:
              "Review ${entry.inviterDisplayName}'s student connection "
              'request below.',
        );
      }
      return InvitationRedemptionResult(
        invitationId: entry.id,
        type: entry.type,
        outcome: InvitationRedemptionOutcome.previouslyDeclined,
        inviterDisplayName: entry.inviterDisplayName,
        inviterPhotoUrl: entry.inviterPhotoUrl,
        connectionId: entry.connectionId,
        connectionVersion: entry.connectionVersion,
        connectionStatus: entry.connectionStatus,
        message: 'You previously declined this student connection request.',
      );
    }

    final now = _now;
    final cutoff = now.subtract(const Duration(hours: 24));
    final recent = (_redeemHistory[actorUid] ?? <DateTime>[])
        .where((t) => !t.isBefore(cutoff))
        .toList();
    if (recent.length >= maxRedeemsPer24Hours) {
      throw const InvitationException(
        'Too many invitation redemption attempts today. Try again later.',
        code: 'resource-exhausted',
      );
    }
    _redeemHistory[actorUid] = [...recent, now];

    if (entry.revokedAt != null) {
      throw const InvitationException(
        'This invitation has been revoked by the sender.',
        code: 'failed-precondition',
      );
    }
    if (now.isAfter(entry.expiresAt)) {
      throw const InvitationException(
        'This invitation link has expired.',
        code: 'failed-precondition',
      );
    }

    if (!isStudent) {
      if (entry.redeemedUids.length >= entry.maxUses) {
        throw const InvitationException(
          'This invitation link has reached its usage limit.',
          code: 'failed-precondition',
        );
      }
      entry.redeemedUids.add(actorUid);
      return InvitationRedemptionResult(
        invitationId: entry.id,
        type: entry.type,
        outcome: InvitationRedemptionOutcome.redeemedGeneral,
        inviterDisplayName: entry.inviterDisplayName,
        inviterPhotoUrl: entry.inviterPhotoUrl,
        message:
            'Welcome! ${entry.inviterDisplayName} invited you to '
            "Horse & Rider's Companion.",
      );
    }

    if (entry.claimedByUid != null && entry.claimedByUid != actorUid) {
      throw const InvitationException(
        'This student invitation has already been claimed.',
        code: 'failed-precondition',
      );
    }
    if (!entry.inviterIsTrainer) {
      throw const InvitationException(
        'This instructor invitation is no longer available.',
        code: 'failed-precondition',
      );
    }

    final learnerDisplayName = actorName.trim().isNotEmpty
        ? actorName.trim()
        : actorEmail.split('@').first;
    final connId = 'conn_${entry.inviterUid}_$actorUid';
    final version = 'ver_${++_counter}';

    if (_acceptedPairs.contains('${entry.inviterUid}::$actorUid')) {
      entry
        ..redeemedUids.add(actorUid)
        ..claimedByUid = actorUid
        ..recipientDisplayName = learnerDisplayName
        ..connectionId = connId
        ..connectionVersion = version
        ..connectionStatus = 'accepted';
      return InvitationRedemptionResult(
        invitationId: entry.id,
        type: entry.type,
        outcome: InvitationRedemptionOutcome.alreadyConnected,
        inviterDisplayName: entry.inviterDisplayName,
        inviterPhotoUrl: entry.inviterPhotoUrl,
        connectionId: connId,
        connectionVersion: version,
        connectionStatus: 'accepted',
        message: 'You are already connected with ${entry.inviterDisplayName}.',
      );
    }

    entry
      ..redeemedUids.add(actorUid)
      ..claimedByUid = actorUid
      ..recipientDisplayName = learnerDisplayName
      ..connectionId = connId
      ..connectionVersion = version
      ..connectionStatus = 'pending';

    await onPendingConnectionPrepared?.call(
      connectionId: connId,
      connectionVersion: version,
      coachUid: entry.inviterUid,
      coachEmail: entry.inviterEmail,
      coachName: entry.inviterDisplayName,
      learnerUid: actorUid,
      learnerEmail: actorEmail.trim().toLowerCase(),
      learnerName: learnerDisplayName,
      invitationId: entry.id,
      personalMessage: entry.personalMessage,
    );

    return InvitationRedemptionResult(
      invitationId: entry.id,
      type: entry.type,
      outcome: InvitationRedemptionOutcome.pendingConnectionCreated,
      inviterDisplayName: entry.inviterDisplayName,
      inviterPhotoUrl: entry.inviterPhotoUrl,
      connectionId: connId,
      connectionVersion: version,
      connectionStatus: 'pending',
      requestDocId: connId,
      message:
          '${entry.inviterDisplayName} wants to connect with you as '
          'their student.',
    );
  }

  @override
  Future<List<InvitationRecord>> listMyInvitations() async {
    _requireVerifiedActor();
    final now = _now;
    final list = _byId.values.where((e) => e.inviterUid == actorUid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.map((e) => e.toRecord(now)).toList();
  }

  @override
  Future<InvitationRecord> revokeInvitation(String invitationId) async {
    _requireVerifiedActor();
    final entry = _byId[invitationId];
    if (entry == null) {
      throw const InvitationException(
        'Invitation not found.',
        code: 'not-found',
      );
    }
    if (entry.inviterUid != actorUid) {
      throw const InvitationException(
        'You can only revoke your own invitations.',
        code: 'permission-denied',
      );
    }
    if (entry.connectionStatus == 'accepted') {
      throw const InvitationException(
        'Accepted connections must be ended from Connections and requests.',
        code: 'failed-precondition',
      );
    }
    final now = _now;
    if (entry.revokedAt == null) {
      entry.revokedAt = now;
      if (entry.connectionStatus == 'pending') {
        entry.connectionStatus = 'cancelled';
      }
    }
    return entry.toRecord(now);
  }
}
