// ignore_for_file: constant_identifier_names, public_member_api_docs, sort_constructors_first, lines_longer_than_80_chars
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

///  Possible message state
enum MessageState { UNREAD, READ }

/// Possible message types
enum MessageType {
  CHAT,
  EDIT_REQUEST,
  STUDENT_REQUEST,
  INSTRUCTOR_REQUEST,
  STUDENT_HORSE_REQUEST,
}

///Model representing a Message
class Message {
  Message({
    this.parties,
    required this.id,
    this.requestItem,
    required this.date,
    required this.sender,
    required this.subject,
    required this.message,
    required this.messsageId,
    required this.recipients,
    required this.senderProfilePicUrl,
    this.messageType = MessageType.CHAT,
    this.messageState = MessageState.UNREAD,
  });

  final String? id;
  final DateTime? date;
  final String? sender;
  final String? subject;
  String? message;
  final String? messsageId;
  MessageState messageState;
  final List<String?>? parties;
  MessageType messageType;
  final BaseListItem? requestItem;
  final List<String?>? recipients;
  final String? senderProfilePicUrl;

  factory Message.fromJson(Map<String, dynamic>? data) => Message(
        id: data?['id'] as String?,
        sender: data?['sender'] as String?,
        subject: data?['subject'] as String?,
        message: data?['message'] as String?,
        messsageId: data?['messsageId'] as String?,
        date: (data?['date'] as Timestamp?)?.toDate(),
        requestItem: data?['requestItem'] != null
            ? BaseListItem.fromJson(
                data?['requestItem'] as Map<String, dynamic>,
              )
            : null,
        messageState: data?['messageState'] == 'UNREAD'
            ? MessageState.UNREAD
            : MessageState.READ,
        messageType: data?['messageType'] == 'STUDENT_HORSE_REQUEST'
            ? MessageType.STUDENT_HORSE_REQUEST
            : data?['messageType'] == 'EDIT_REQUEST'
                ? MessageType.EDIT_REQUEST
                : data?['messageType'] == 'INSTRUCTOR_REQUEST'
                    ? MessageType.INSTRUCTOR_REQUEST
                    : data?['messageType'] == 'STUDENT_REQUEST'
                        ? MessageType.STUDENT_REQUEST
                        : MessageType.CHAT,
        senderProfilePicUrl: data?['senderProfilePicUrl'] as String?,
        recipients:
            (data?['recipient'] as List?)?.map((e) => e as String?).toList(),
        parties: (data?['parties'] as List?)?.map((e) => e as String).toList(),
      );

  factory Message.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Message(
      id: data!['id'] as String?,
      sender: data['sender'] as String?,
      subject: data['subject'] as String?,
      message: data['message'] as String?,
      messsageId: data['messsageId'] as String?,
      date: (data['date'] as Timestamp?)?.toDate(),
      requestItem: data['requestItem'] != null
          ? BaseListItem.fromJson(
              data['requestItem'] as Map<String, dynamic>,
            )
          : null,
      messageState: data['messageState'] == 'UNREAD'
          ? MessageState.UNREAD
          : MessageState.READ,
      messageType: data['messageType'] == 'STUDENT_HORSE_REQUEST'
          ? MessageType.STUDENT_HORSE_REQUEST
          : data['messageType'] == 'EDIT_REQUEST'
              ? MessageType.EDIT_REQUEST
              : data['messageType'] == 'INSTRUCTOR_REQUEST'
                  ? MessageType.INSTRUCTOR_REQUEST
                  : data['messageType'] == 'STUDENT_REQUEST'
                      ? MessageType.STUDENT_REQUEST
                      : MessageType.CHAT,
      senderProfilePicUrl: data['senderProfilePicUrl'] as String?,
      parties: (data['parties'] as List?)?.map((e) => e as String).toList(),
      recipients:
          (data['recipient'] as List?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (sender != null) 'sender': sender,
      if (subject != null) 'subject': subject,
      if (message != null) 'message': message,
      if (parties != null) 'parties': parties,
      if (recipients != null) 'recipients': recipients,
      if (messsageId != null) 'messsageId': messsageId,
      if (requestItem != null) 'requestItem': requestItem!.toJson(),
      if (senderProfilePicUrl != null)
        'senderProfilePicUrl': senderProfilePicUrl,
      'messageType': messageType == MessageType.STUDENT_HORSE_REQUEST
          ? 'STUDENT_HORSE_REQUEST'
          : messageType == MessageType.INSTRUCTOR_REQUEST
              ? 'INSTRUCTOR_REQUEST'
              : messageType == MessageType.EDIT_REQUEST
                  ? 'EDIT_REQUEST'
                  : messageType == MessageType.STUDENT_REQUEST
                      ? 'STUDENT_REQUEST'
                      : 'CHAT',
      'messageState': messageState == MessageState.UNREAD ? 'UNREAD' : 'READ',
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (sender != null) 'sender': sender,
      if (subject != null) 'subject': subject,
      if (message != null) 'message': message,
      if (parties != null) 'parties': parties,
      if (recipients != null) 'recipients': recipients,
      if (messsageId != null) 'messsageId': messsageId,
      if (requestItem != null) 'requestItem': requestItem!.toJson(),
      if (senderProfilePicUrl != null)
        'senderProfilePicUrl': senderProfilePicUrl,
      'messageType': messageType == MessageType.STUDENT_HORSE_REQUEST
          ? 'STUDENT_HORSE_REQUEST'
          : messageType == MessageType.INSTRUCTOR_REQUEST
              ? 'INSTRUCTOR_REQUEST'
              : messageType == MessageType.EDIT_REQUEST
                  ? 'EDIT_REQUEST'
                  : messageType == MessageType.STUDENT_REQUEST
                      ? 'STUDENT_REQUEST'
                      : 'CHAT',
      'messageState': messageState == MessageState.UNREAD ? 'UNREAD' : 'READ',
    };
  }
}
