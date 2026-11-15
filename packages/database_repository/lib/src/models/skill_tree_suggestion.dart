// ignore_for_file: public_member_api_docs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Categories of community Skill Tree curriculum suggestions.
enum SuggestionCategory {
  missingTermOrAlias('missing_term_or_alias', 'Missing Term or Alias'),
  componentOrExample('component_or_example', 'Component or Example'),
  levelAdjustmentOrAddition(
    'level_adjustment_or_addition',
    'Level Adjustment or Addition',
  ),
  newSkillProposal('new_skill_proposal', 'New Skill Proposal'),
  safetyOrWordingCorrection(
    'safety_or_wording_correction',
    'Safety or Wording Correction',
  );

  const SuggestionCategory(this.value, this.label);

  /// Wire/Firestore string identifier.
  final String value;

  /// Human-readable display label.
  final String label;

  /// Parses a wire string into [SuggestionCategory], defaulting to
  /// [componentOrExample].
  static SuggestionCategory fromWire(String? raw) {
    for (final item in values) {
      if (item.value == raw) return item;
    }
    return componentOrExample;
  }
}

/// Review workflow status for a [SkillTreeSuggestion].
enum SuggestionStatus {
  submitted('submitted', 'Submitted', isAdminOnly: false),
  underReview('under_review', 'Under Review', isAdminOnly: false),
  needsClarification(
    'needs_clarification',
    'Needs Clarification',
    isAdminOnly: false,
  ),
  approvedAsAliasOrComponent(
    'approved_as_alias_or_component',
    'Approved (Alias / Component)',
    isAdminOnly: true,
  ),
  approvedAsLevel(
    'approved_as_level',
    'Approved (Level)',
    isAdminOnly: true,
  ),
  approvedAsNewSkill(
    'approved_as_new_skill',
    'Approved (New Skill)',
    isAdminOnly: true,
  ),
  published('published', 'Published', isAdminOnly: true),
  declinedAlreadyCovered(
    'declined_already_covered',
    'Declined (Already Covered)',
    isAdminOnly: true,
  ),
  declinedOutOfScope(
    'declined_out_of_scope',
    'Declined (Out of Scope)',
    isAdminOnly: true,
  );

  const SuggestionStatus(
    this.value,
    this.label, {
    required this.isAdminOnly,
  });

  /// Wire/Firestore string identifier.
  final String value;

  /// Human-readable display label.
  final String label;

  /// Whether only an administrator (not a moderator) can set this status.
  final bool isAdminOnly;

  /// Parses a wire string into [SuggestionStatus], defaulting to [submitted].
  static SuggestionStatus fromWire(String? raw) {
    for (final item in values) {
      if (item.value == raw) return item;
    }
    return submitted;
  }
}

/// Input payload for submitting a new Skill Tree suggestion.
class SkillTreeSuggestionDraft {
  /// Creates a [SkillTreeSuggestionDraft].
  const SkillTreeSuggestionDraft({
    required this.contributionCategory,
    required this.subject,
    required this.realm,
    required this.title,
    required this.description,
    this.familyId,
    this.targetSkillId,
    this.targetSkillName,
    this.targetLevel,
    this.rationale,
    this.proposedAlias,
  });

  final SuggestionCategory contributionCategory;
  final String subject;
  final String realm;
  final String? familyId;
  final String? targetSkillId;
  final String? targetSkillName;
  final String? targetLevel;
  final String title;
  final String description;
  final String? rationale;
  final String? proposedAlias;

  /// Converts this draft to the Cloud Function payload map.
  Map<String, dynamic> toPayload() => {
        'contributionCategory': contributionCategory.value,
        'subject': subject,
        'realm': realm,
        'familyId': familyId,
        'targetSkillId': targetSkillId,
        'targetSkillName': targetSkillName,
        'targetLevel': targetLevel,
        'title': title,
        'description': description,
        'rationale': rationale,
        'proposedAlias': proposedAlias,
      };
}

/// Staff review update payload for an existing [SkillTreeSuggestion].
class SuggestionReviewUpdate {
  /// Creates a [SuggestionReviewUpdate].
  const SuggestionReviewUpdate({
    required this.suggestionId,
    this.status,
    this.assignedToUid,
    this.includeAssignedToUid = false,
    this.publicResolutionNote,
    this.includePublicResolutionNote = false,
    this.privateNote,
  });

  final String suggestionId;
  final SuggestionStatus? status;
  final String? assignedToUid;
  final bool includeAssignedToUid;
  final String? publicResolutionNote;
  final bool includePublicResolutionNote;
  final String? privateNote;

  /// Converts this update to the Cloud Function payload map.
  Map<String, dynamic> toPayload() {
    final payload = <String, dynamic>{
      'suggestionId': suggestionId,
    };
    if (status != null) {
      payload['status'] = status!.value;
    }
    if (includeAssignedToUid) {
      payload['assignedToUid'] = assignedToUid;
    }
    if (includePublicResolutionNote) {
      payload['publicResolutionNote'] = publicResolutionNote;
    }
    if (privateNote != null && privateNote!.trim().isNotEmpty) {
      payload['privateNote'] = privateNote!.trim();
    }
    return payload;
  }
}

/// Community Skill Tree curriculum suggestion record.
class SkillTreeSuggestion extends Equatable {
  /// Creates a [SkillTreeSuggestion].
  const SkillTreeSuggestion({
    required this.id,
    required this.submittedByUid,
    required this.submitterEmail,
    required this.submitterName,
    required this.contributionCategory,
    required this.subject,
    required this.realm,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.familyId,
    this.targetSkillId,
    this.targetSkillName,
    this.targetLevel,
    this.rationale,
    this.proposedAlias,
    this.assignedToUid,
    this.publicResolutionNote,
    this.reviewedByUid,
    this.reviewedByName,
    this.reviewedAt,
  });

  /// Creates a [SkillTreeSuggestion] from a Firestore or JSON map.
  factory SkillTreeSuggestion.fromMap(Map<String, dynamic> map) {
    return SkillTreeSuggestion(
      id: map['id'] as String? ?? '',
      submittedByUid: map['submittedByUid'] as String? ?? '',
      submitterEmail: map['submitterEmail'] as String? ?? '',
      submitterName: map['submitterName'] as String? ?? '',
      contributionCategory: SuggestionCategory.fromWire(
        map['contributionCategory'] as String?,
      ),
      subject: map['subject'] as String? ?? 'rider',
      realm: map['realm'] as String? ?? 'Other',
      familyId: map['familyId'] as String?,
      targetSkillId: map['targetSkillId'] as String?,
      targetSkillName: map['targetSkillName'] as String?,
      targetLevel: map['targetLevel'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      rationale: map['rationale'] as String?,
      proposedAlias: map['proposedAlias'] as String?,
      status: SuggestionStatus.fromWire(map['status'] as String?),
      assignedToUid: map['assignedToUid'] as String?,
      publicResolutionNote: map['publicResolutionNote'] as String?,
      reviewedByUid: map['reviewedByUid'] as String?,
      reviewedByName: map['reviewedByName'] as String?,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now().toUtc(),
      reviewedAt: _parseDate(map['reviewedAt']),
    );
  }

  final String id;
  final String submittedByUid;
  final String submitterEmail;
  final String submitterName;
  final SuggestionCategory contributionCategory;
  final String subject;
  final String realm;
  final String? familyId;
  final String? targetSkillId;
  final String? targetSkillName;
  final String? targetLevel;
  final String title;
  final String description;
  final String? rationale;
  final String? proposedAlias;
  final SuggestionStatus status;
  final String? assignedToUid;
  final String? publicResolutionNote;
  final String? reviewedByUid;
  final String? reviewedByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;

  @override
  List<Object?> get props => [
        id,
        submittedByUid,
        submitterEmail,
        submitterName,
        contributionCategory,
        subject,
        realm,
        familyId,
        targetSkillId,
        targetSkillName,
        targetLevel,
        title,
        description,
        rationale,
        proposedAlias,
        status,
        assignedToUid,
        publicResolutionNote,
        reviewedByUid,
        reviewedByName,
        createdAt,
        updatedAt,
        reviewedAt,
      ];
}

/// Private staff audit event stored under
/// `SkillTreeSuggestions/{suggestionId}/AuditEvents/{eventId}`.
class SuggestionAuditEvent extends Equatable {
  /// Creates a [SuggestionAuditEvent].
  const SuggestionAuditEvent({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorName,
    required this.actorRole,
    required this.at,
    this.fromStatus,
    this.toStatus,
    this.privateNote,
    this.publicNote,
  });

  /// Creates a [SuggestionAuditEvent] from a Firestore map.
  factory SuggestionAuditEvent.fromMap(Map<String, dynamic> map) {
    return SuggestionAuditEvent(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'note_added',
      actorUid: map['actorUid'] as String? ?? '',
      actorName: map['actorName'] as String? ?? '',
      actorRole: map['actorRole'] as String? ?? 'submitter',
      fromStatus: map['fromStatus'] == null
          ? null
          : SuggestionStatus.fromWire(map['fromStatus'] as String?),
      toStatus: map['toStatus'] == null
          ? null
          : SuggestionStatus.fromWire(map['toStatus'] as String?),
      privateNote: map['privateNote'] as String?,
      publicNote: map['publicNote'] as String?,
      at: _parseDate(map['at']) ?? DateTime.now().toUtc(),
    );
  }

  final String id;
  final String type;
  final String actorUid;
  final String actorName;
  final String actorRole;
  final SuggestionStatus? fromStatus;
  final SuggestionStatus? toStatus;
  final String? privateNote;
  final String? publicNote;
  final DateTime at;

  @override
  List<Object?> get props => [
        id,
        type,
        actorUid,
        actorName,
        actorRole,
        fromStatus,
        toStatus,
        privateNote,
        publicNote,
        at,
      ];
}

/// Domain exception thrown by Skill Tree suggestion store operations.
class SkillTreeSuggestionException implements Exception {
  /// Creates a [SkillTreeSuggestionException].
  const SkillTreeSuggestionException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate().toUtc();
  if (value is DateTime) return value.toUtc();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
