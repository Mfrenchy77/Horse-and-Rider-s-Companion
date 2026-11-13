import 'package:database_repository/src/models/models.dart';
import 'package:equatable/equatable.dart';

/// Backend-neutral kind of a rider/horse connection or transfer request.
enum ConnectionRequestKind {
  /// Rider requesting another rider as their instructor.
  instructor,

  /// Instructor requesting a rider as their student.
  student,

  /// Trainer requesting to add an owner's horse as a student horse.
  studentHorse,

  /// Owner offering to transfer a horse's ownership to another rider.
  transferHorse,
}

/// Backend-neutral representation of a pending or dismissed connection request.
class ConnectionRequest extends Equatable {
  /// Creates a [ConnectionRequest].
  const ConnectionRequest({
    required this.id,
    required this.messageId,
    required this.kind,
    required this.senderEmail,
    required this.senderName,
    required this.recipientEmail,
    required this.recipientName,
    required this.title,
    required this.summary,
    required this.createdAt,
    this.senderPicUrl,
    this.parties = const [],
    this.partiesIds = const [],
    this.isAccepted = false,
    this.horseId,
    this.horseName,
    this.horsePicUrl,
    this.horseOwnerId,
    this.horseOwnerName,
  });

  /// Stable thread/conversation identifier for this pair of users.
  final String id;

  /// Unique identifier of this specific request item.
  final String messageId;

  /// Request type.
  final ConnectionRequestKind kind;

  /// Normalized email of the sender.
  final String senderEmail;

  /// Display name of the sender.
  final String senderName;

  /// Optional profile photo URL of the sender.
  final String? senderPicUrl;

  /// Normalized email of the recipient.
  final String recipientEmail;

  /// Display name of the recipient.
  final String recipientName;

  /// Human-readable title (e.g. `'Instructor Request'`).
  final String title;

  /// Human-readable summary shown in the requests sheet.
  final String summary;

  /// Participant display names.
  final List<String> parties;

  /// Participant normalized emails.
  final List<String> partiesIds;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Whether the request has already been accepted.
  final bool isAccepted;

  /// Horse identifier for horse-scoped requests.
  final String? horseId;

  /// Horse display name for horse-scoped requests.
  final String? horseName;

  /// Optional horse photo URL.
  final String? horsePicUrl;

  /// Current horse owner email for horse-scoped requests.
  final String? horseOwnerId;

  /// Current horse owner display name for horse-scoped requests.
  final String? horseOwnerName;

  /// Converts a legacy [Message] (and optional [Conversation]) into a
  /// [ConnectionRequest], returning `null` if the message is not a request.
  static ConnectionRequest? fromLegacyMessage(
    Message? message, {
    Conversation? conversation,
  }) {
    if (message == null) return null;
    final kind = switch (message.messageType) {
      MessageType.INSTRUCTOR_REQUEST => ConnectionRequestKind.instructor,
      MessageType.STUDENT_REQUEST => ConnectionRequestKind.student,
      MessageType.STUDENT_HORSE_REQUEST => ConnectionRequestKind.studentHorse,
      MessageType.TRANSFER_HORSE_REQUEST => ConnectionRequestKind.transferHorse,
      _ => null,
    };
    if (kind == null) return null;

    final senderEmail = (message.senderId ??
            (kind == ConnectionRequestKind.studentHorse
                ? message.requestItem?.extra
                : message.requestItem?.id) ??
            '')
        .toLowerCase();
    final partiesIds =
        conversation?.partiesIds ??
        message.parties?.whereType<String>().toList() ??
        const <String>[];
    final recipientEmail = partiesIds
        .firstWhere(
          (email) => email.toLowerCase() != senderEmail,
          orElse: () => '',
        )
        .toLowerCase();
    final parties =
        conversation?.parties ??
        message.recipients?.whereType<String>().toList() ??
        const <String>[];
    final senderName = message.sender ?? '';
    final recipientName = parties.firstWhere(
      (name) => name != senderName,
      orElse: () => '',
    );

    final isHorseKind =
        kind == ConnectionRequestKind.studentHorse ||
        kind == ConnectionRequestKind.transferHorse;

    return ConnectionRequest(
      id: message.id ?? conversation?.id ?? '',
      messageId: message.messageId ?? '',
      kind: kind,
      senderEmail: senderEmail,
      senderName: senderName,
      senderPicUrl: message.senderProfilePicUrl,
      recipientEmail: recipientEmail,
      recipientName: recipientName,
      title: message.subject ?? '',
      summary: message.message ?? '',
      parties: parties,
      partiesIds: partiesIds,
      createdAt: message.date ?? conversation?.lastEditDate ?? DateTime.now(),
      isAccepted: message.requestItem?.isSelected ?? false,
      horseId: isHorseKind ? message.requestItem?.id : null,
      horseName: isHorseKind ? message.requestItem?.name : null,
      horsePicUrl: isHorseKind ? message.requestItem?.imageUrl : null,
      horseOwnerId: isHorseKind ? message.requestItem?.parentId : null,
      horseOwnerName: isHorseKind ? message.requestItem?.message : null,
    );
  }

  /// Converts this [ConnectionRequest] into a legacy [Message] for the
  /// transitional Firestore adapter.
  Message toLegacyMessage({
    MessageType? overrideType,
    String? overrideSummary,
  }) {
    final type =
        overrideType ??
        switch (kind) {
          ConnectionRequestKind.instructor => MessageType.INSTRUCTOR_REQUEST,
          ConnectionRequestKind.student => MessageType.STUDENT_REQUEST,
          ConnectionRequestKind.studentHorse =>
            MessageType.STUDENT_HORSE_REQUEST,
          ConnectionRequestKind.transferHorse =>
            MessageType.TRANSFER_HORSE_REQUEST,
        };
    final isHorseKind =
        kind == ConnectionRequestKind.studentHorse ||
        kind == ConnectionRequestKind.transferHorse;
    final requestItem = BaseListItem(
      id: isHorseKind ? (horseId ?? '') : senderEmail,
      name: isHorseKind ? (horseName ?? '') : senderName,
      imageUrl: isHorseKind ? horsePicUrl : senderPicUrl,
      extra: isHorseKind ? senderEmail : null,
      parentId: isHorseKind ? horseOwnerId : null,
      message: isHorseKind ? horseOwnerName : null,
      isCollapsed: !isHorseKind,
      isSelected: isAccepted,
    );

    return Message(
      id: id,
      messageId: messageId,
      date: createdAt,
      sender: senderName,
      senderId: senderEmail,
      senderProfilePicUrl: senderPicUrl,
      subject: title,
      message: overrideSummary ?? summary,
      messageType: type,
      requestItem: requestItem,
      recipients: parties.isNotEmpty
          ? parties
          : [senderName, recipientName].where((e) => e.isNotEmpty).toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    messageId,
    kind,
    senderEmail,
    senderName,
    senderPicUrl,
    recipientEmail,
    recipientName,
    title,
    summary,
    parties,
    partiesIds,
    createdAt,
    isAccepted,
    horseId,
    horseName,
    horsePicUrl,
    horseOwnerId,
    horseOwnerName,
  ];
}
