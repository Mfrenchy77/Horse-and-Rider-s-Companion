import 'package:equatable/equatable.dart';

/// Categories of shareable onboarding invitations.
enum InvitationType {
  /// Open invitation allowing any authenticated user to join the platform.
  general('general'),

  /// Instructor-to-student invitation that prepares a pending coaching request.
  studentConnection('student_connection');

  const InvitationType(this.wireValue);

  /// Backend wire representation.
  final String wireValue;

  /// Parses an [InvitationType] from a serialized wire string.
  static InvitationType fromWire(String? raw) => switch (raw) {
    'student_connection' => InvitationType.studentConnection,
    _ => InvitationType.general,
  };
}

/// Lifecycle status of an invitation or its public preview.
enum InvitationStatus {
  /// General invitation is active and can still be redeemed.
  active,

  /// Student invitation has been created and awaits recipient signup/review.
  pending,

  /// Student invitation was claimed by a registered user awaiting acceptance.
  registered,

  /// Student invitation resulted in an accepted coaching connection.
  accepted,

  /// Student invitation connection request was declined by the recipient.
  declined,

  /// Invitation expired before redemption.
  expired,

  /// Invitation was revoked by the creator.
  revoked,

  /// Invitation reached its maximum redemption count or was claimed elsewhere.
  used,

  /// Token is malformed or unknown.
  invalid;

  /// Parses an [InvitationStatus] from a wire string.
  static InvitationStatus fromWire(String? raw) => switch (raw) {
    'active' => InvitationStatus.active,
    'pending' => InvitationStatus.pending,
    'registered' => InvitationStatus.registered,
    'accepted' => InvitationStatus.accepted,
    'declined' => InvitationStatus.declined,
    'expired' => InvitationStatus.expired,
    'revoked' => InvitationStatus.revoked,
    'used' => InvitationStatus.used,
    _ => InvitationStatus.invalid,
  };
}

/// Server-reported outcome of redeeming an invitation as an authenticated user.
enum InvitationRedemptionOutcome {
  /// General invitation redeemed cleanly without creating a relationship.
  redeemedGeneral,

  /// Same user had already redeemed this general invitation.
  alreadyRedeemedGeneral,

  /// Student invitation prepared a new pending coaching connection request.
  pendingConnectionCreated,

  /// Student invitation recovered an existing pending coaching connection.
  pendingConnectionExisting,

  /// Recipient and instructor already share an accepted coaching connection.
  alreadyConnected,

  /// Student connection request was previously declined/closed.
  previouslyDeclined;

  /// Parses an [InvitationRedemptionOutcome] from a wire string.
  static InvitationRedemptionOutcome fromWire(String? raw) => switch (raw) {
    'already_redeemed_general' =>
      InvitationRedemptionOutcome.alreadyRedeemedGeneral,
    'pending_connection_created' =>
      InvitationRedemptionOutcome.pendingConnectionCreated,
    'pending_connection_existing' =>
      InvitationRedemptionOutcome.pendingConnectionExisting,
    'already_connected' => InvitationRedemptionOutcome.alreadyConnected,
    'previously_declined' => InvitationRedemptionOutcome.previouslyDeclined,
    _ => InvitationRedemptionOutcome.redeemedGeneral,
  };
}

/// Exception thrown by `InvitationStore` implementations.
class InvitationException implements Exception {
  /// Creates an [InvitationException].
  const InvitationException(this.message, {this.code});

  /// User-friendly error message.
  final String message;

  /// Optional backend error code (e.g. `'failed-precondition'`).
  final String? code;

  @override
  String toString() =>
      code == null ? message : 'InvitationException($code): $message';
}

DateTime? _parseOptionalDate(Object? raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  return null;
}

/// Public, unauthenticated-safe preview metadata for an invitation link.
class InvitationPreview extends Equatable {
  /// Creates an [InvitationPreview].
  const InvitationPreview({
    required this.tokenValid,
    required this.status,
    required this.canRedeem,
    this.type,
    this.relationshipRole,
    this.inviterDisplayName,
    this.inviterPhotoUrl,
    this.inviterIsTrainer = false,
    this.inviterLocation,
    this.personalMessage,
    this.expiresAt,
    this.statusMessage = '',
  });

  /// Parses an [InvitationPreview] from a response map.
  factory InvitationPreview.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'] as String?;
    return InvitationPreview(
      tokenValid: map['tokenValid'] == true,
      status: InvitationStatus.fromWire(map['status'] as String?),
      type: rawType == null ? null : InvitationType.fromWire(rawType),
      relationshipRole: map['relationshipRole'] as String?,
      inviterDisplayName: map['inviterDisplayName'] as String?,
      inviterPhotoUrl: map['inviterPhotoUrl'] as String?,
      inviterIsTrainer: map['inviterIsTrainer'] == true,
      inviterLocation: map['inviterLocation'] as String?,
      personalMessage: map['personalMessage'] as String?,
      expiresAt: _parseOptionalDate(map['expiresAt']),
      canRedeem: map['canRedeem'] == true,
      statusMessage: map['statusMessage'] as String? ?? '',
    );
  }

  /// Whether the token maps to an invitation record.
  final bool tokenValid;

  /// Current invitation availability or lifecycle status.
  final InvitationStatus status;

  /// Category of invitation when [tokenValid] is `true`.
  final InvitationType? type;

  /// Optional relationship role (`'student'`) for relationship invitations.
  final String? relationshipRole;

  /// Public display name of the inviting user.
  final String? inviterDisplayName;

  /// Optional sanitized public profile image URL.
  final String? inviterPhotoUrl;

  /// Whether the inviter holds an instructor/trainer profile flag.
  final bool inviterIsTrainer;

  /// Optional public location string.
  final String? inviterLocation;

  /// Optional short welcome note supplied by the inviter.
  final String? personalMessage;

  /// Expiration timestamp when applicable.
  final DateTime? expiresAt;

  /// Whether this invitation can currently be redeemed.
  final bool canRedeem;

  /// Human-readable explanation suitable for public display.
  final String statusMessage;

  @override
  List<Object?> get props => [
    tokenValid,
    status,
    type,
    relationshipRole,
    inviterDisplayName,
    inviterPhotoUrl,
    inviterIsTrainer,
    inviterLocation,
    personalMessage,
    expiresAt,
    canRedeem,
    statusMessage,
  ];
}

/// Inviter-authorized summary of a created invitation for management views.
class InvitationRecord extends Equatable {
  /// Creates an [InvitationRecord].
  const InvitationRecord({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.maxUses,
    required this.redemptionCount,
    this.relationshipRole,
    this.personalMessage,
    this.revokedAt,
    this.acceptedCount = 0,
    this.declinedCount = 0,
    this.connectionId,
    this.connectionStatus,
    this.recipientDisplayName,
  });

  /// Parses an [InvitationRecord] from a backend map.
  factory InvitationRecord.fromMap(Map<String, dynamic> map) {
    return InvitationRecord(
      id: map['id'] as String? ?? '',
      type: InvitationType.fromWire(map['type'] as String?),
      status: InvitationStatus.fromWire(map['status'] as String?),
      relationshipRole: map['relationshipRole'] as String?,
      personalMessage: map['personalMessage'] as String?,
      createdAt: _parseOptionalDate(map['createdAt']) ?? DateTime.now().toUtc(),
      expiresAt:
          _parseOptionalDate(map['expiresAt']) ??
          DateTime.now().toUtc().add(const Duration(days: 14)),
      revokedAt: _parseOptionalDate(map['revokedAt']),
      maxUses: (map['maxUses'] as num?)?.toInt() ?? 1,
      redemptionCount: (map['redemptionCount'] as num?)?.toInt() ?? 0,
      acceptedCount: (map['acceptedCount'] as num?)?.toInt() ?? 0,
      declinedCount: (map['declinedCount'] as num?)?.toInt() ?? 0,
      connectionId: map['connectionId'] as String?,
      connectionStatus: map['connectionStatus'] as String?,
      recipientDisplayName: map['recipientDisplayName'] as String?,
    );
  }

  /// Stable server identifier (`inv_...`).
  final String id;

  /// Invitation category.
  final InvitationType type;

  /// Derived lifecycle status.
  final InvitationStatus status;

  /// Relationship role (`'student'`) when [type] is
  /// [InvitationType.studentConnection].
  final String? relationshipRole;

  /// Optional personal message included in the invite.
  final String? personalMessage;

  /// Timestamp when the invitation was created.
  final DateTime createdAt;

  /// Timestamp when the invitation expires.
  final DateTime expiresAt;

  /// Timestamp when revoked by the creator, if revoked.
  final DateTime? revokedAt;

  /// Maximum allowed unique redemptions.
  final int maxUses;

  /// Number of unique users who redeemed this invitation.
  final int redemptionCount;

  /// Count of accepted student connections created from this invite.
  final int acceptedCount;

  /// Count of declined student connections created from this invite.
  final int declinedCount;

  /// Linked `CoachingConnections` ID for redeemed student invitations.
  final String? connectionId;

  /// Linked connection status (`'pending'`, `'accepted'`, `'declined'`,
  /// `'cancelled'`) for student invitations.
  final String? connectionStatus;

  /// Public display name of the claiming recipient for student invitations
  /// only; always `null` for general invitations.
  final String? recipientDisplayName;

  /// Whether this is an instructor-to-student invitation.
  bool get isStudentConnection => type == InvitationType.studentConnection;

  /// Whether the creator can currently revoke this invitation.
  bool get isRevocable =>
      status == InvitationStatus.active ||
      status == InvitationStatus.pending ||
      status == InvitationStatus.registered;

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    relationshipRole,
    personalMessage,
    createdAt,
    expiresAt,
    revokedAt,
    maxUses,
    redemptionCount,
    acceptedCount,
    declinedCount,
    connectionId,
    connectionStatus,
    recipientDisplayName,
  ];
}

/// Request payload for creating a new invitation.
class InvitationCreateRequest extends Equatable {
  /// Creates an [InvitationCreateRequest].
  const InvitationCreateRequest({
    required this.type,
    this.personalMessage,
    this.expiresInDays,
    this.maxUses,
  });

  /// Invitation category.
  final InvitationType type;

  /// Optional personal note attached to the invite (max 200 chars).
  final String? personalMessage;

  /// Optional expiration window in days.
  final int? expiresInDays;

  /// Optional redemption limit for general invitations.
  final int? maxUses;

  /// Serializes this request into a callable payload map.
  Map<String, dynamic> toMap() => {
    'type': type.wireValue,
    if (personalMessage != null && personalMessage!.trim().isNotEmpty)
      'personalMessage': personalMessage!.trim(),
    if (expiresInDays != null) 'expiresInDays': expiresInDays,
    if (maxUses != null) 'maxUses': maxUses,
  };

  @override
  List<Object?> get props => [type, personalMessage, expiresInDays, maxUses];
}

/// Result returned when an invitation is created, including its secret token.
class InvitationCreateResult extends Equatable {
  /// Creates an [InvitationCreateResult].
  const InvitationCreateResult({
    required this.invitation,
    required this.token,
    required this.sharePath,
  });

  /// Parses an [InvitationCreateResult] from a callable response map.
  factory InvitationCreateResult.fromMap(Map<String, dynamic> map) {
    final rawInv = map['invitation'];
    return InvitationCreateResult(
      invitation: InvitationRecord.fromMap(
        rawInv is Map ? Map<String, dynamic>.from(rawInv) : const {},
      ),
      token: map['token'] as String? ?? '',
      sharePath: map['sharePath'] as String? ?? '',
    );
  }

  /// Created invitation summary.
  final InvitationRecord invitation;

  /// Cryptographically random bearer token (returned once at creation).
  final String token;

  /// Relative share path (`/invite/<token>`).
  final String sharePath;

  @override
  List<Object?> get props => [invitation, token, sharePath];
}

/// Result returned when an authenticated user redeems an invitation token.
class InvitationRedemptionResult extends Equatable {
  /// Creates an [InvitationRedemptionResult].
  const InvitationRedemptionResult({
    required this.invitationId,
    required this.type,
    required this.outcome,
    required this.inviterDisplayName,
    this.inviterPhotoUrl,
    this.connectionId,
    this.connectionVersion,
    this.connectionStatus,
    this.requestDocId,
    this.message = '',
  });

  /// Parses an [InvitationRedemptionResult] from a response map.
  factory InvitationRedemptionResult.fromMap(Map<String, dynamic> map) {
    return InvitationRedemptionResult(
      invitationId: map['invitationId'] as String? ?? '',
      type: InvitationType.fromWire(map['type'] as String?),
      outcome: InvitationRedemptionOutcome.fromWire(map['outcome'] as String?),
      inviterDisplayName: map['inviterDisplayName'] as String? ?? 'Member',
      inviterPhotoUrl: map['inviterPhotoUrl'] as String?,
      connectionId: map['connectionId'] as String?,
      connectionVersion: map['connectionVersion'] as String?,
      connectionStatus: map['connectionStatus'] as String?,
      requestDocId: map['requestDocId'] as String?,
      message: map['message'] as String? ?? '',
    );
  }

  /// Server ID of the redeemed invitation.
  final String invitationId;

  /// Category of the redeemed invitation.
  final InvitationType type;

  /// Redemption outcome describing next step for the recipient.
  final InvitationRedemptionOutcome outcome;

  /// Public display name of the inviter.
  final String inviterDisplayName;

  /// Optional public photo URL of the inviter.
  final String? inviterPhotoUrl;

  /// Pending/existing `CoachingConnections` doc ID for student invitations.
  final String? connectionId;

  /// Optimistic concurrency version string needed by `coachingConnection`.
  final String? connectionVersion;

  /// Current coaching connection status (`'pending'`, `'accepted'`, etc.).
  final String? connectionStatus;

  /// Associated `Requests` doc ID so accept/decline resolves both records.
  final String? requestDocId;

  /// Human-readable status summary for UI display.
  final String message;

  /// Whether the recipient must still explicitly accept or decline a pending
  /// coaching connection request.
  bool get requiresConnectionDecision =>
      outcome == InvitationRedemptionOutcome.pendingConnectionCreated ||
      outcome == InvitationRedemptionOutcome.pendingConnectionExisting;

  @override
  List<Object?> get props => [
    invitationId,
    type,
    outcome,
    inviterDisplayName,
    inviterPhotoUrl,
    connectionId,
    connectionVersion,
    connectionStatus,
    requestDocId,
    message,
  ];
}

/// Lightweight conversion metrics aggregated over the inviter's invitations.
class InvitationMetricsSummary extends Equatable {
  /// Creates an [InvitationMetricsSummary].
  const InvitationMetricsSummary({
    required this.totalCreated,
    required this.activeCount,
    required this.totalRedemptions,
    required this.studentInvitesSent,
    required this.studentInvitesPending,
    required this.studentInvitesAccepted,
    required this.studentInvitesDeclined,
  });

  /// Aggregates [invitations] into summary metrics.
  factory InvitationMetricsSummary.fromInvitations(
    List<InvitationRecord> invitations,
  ) {
    var activeCount = 0;
    var totalRedemptions = 0;
    var studentSent = 0;
    var studentPending = 0;
    var studentAccepted = 0;
    var studentDeclined = 0;

    for (final inv in invitations) {
      totalRedemptions += inv.redemptionCount;
      if (inv.status == InvitationStatus.active ||
          inv.status == InvitationStatus.pending ||
          inv.status == InvitationStatus.registered) {
        activeCount++;
      }
      if (inv.isStudentConnection) {
        studentSent++;
        if (inv.status == InvitationStatus.accepted) {
          studentAccepted++;
        } else if (inv.status == InvitationStatus.declined) {
          studentDeclined++;
        } else if (inv.status == InvitationStatus.pending ||
            inv.status == InvitationStatus.registered) {
          studentPending++;
        }
      }
    }

    return InvitationMetricsSummary(
      totalCreated: invitations.length,
      activeCount: activeCount,
      totalRedemptions: totalRedemptions,
      studentInvitesSent: studentSent,
      studentInvitesPending: studentPending,
      studentInvitesAccepted: studentAccepted,
      studentInvitesDeclined: studentDeclined,
    );
  }

  /// Total invitations created by this user.
  final int totalCreated;

  /// Invitations still active/pending review.
  final int activeCount;

  /// Total unique user redemptions across invitations.
  final int totalRedemptions;

  /// Count of student connection invitations created.
  final int studentInvitesSent;

  /// Count of student invitations awaiting registration or decision.
  final int studentInvitesPending;

  /// Count of student invitations accepted by recipients.
  final int studentInvitesAccepted;

  /// Count of student invitations declined by recipients.
  final int studentInvitesDeclined;

  @override
  List<Object?> get props => [
    totalCreated,
    activeCount,
    totalRedemptions,
    studentInvitesSent,
    studentInvitesPending,
    studentInvitesAccepted,
    studentInvitesDeclined,
  ];
}
