// ignore_for_file: constant_identifier_names,
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

/// A Group is the reference to a group of messages
/// it holds the parties involved in the message,
/// the parties ids, the creator of the group, the
/// date the group was created, the last person to
/// edit the group, the date the group was last edited,
/// the recent message in the group and the state of
/// the message.
class Conversation {
  Conversation({
    required this.id,
    required this.parties,
    required this.partiesIds,
    required this.createdBy,
    required this.createdOn,
    required this.lastEditBy,
    required this.lastEditDate,
    required this.recentMessage,
    this.messageState = MessageState.UNREAD,
  });

  /// The id of the Conversation
  final String id;

  /// the id of the last profile to edit the Conversation
  String? lastEditBy;

  /// The date the Conversation was last edited
  DateTime lastEditDate;

  /// The most recent message in the Conversation
  Message? recentMessage;

  /// The name of the profile that created the Conversation
  final String createdBy;

  /// The date the Conversation was created
  final DateTime createdOn;

  /// The state of the message [UNREAD, READ]
  MessageState messageState;

  /// The names of the profiles in the Conversation
  final List<String> parties;

  /// The ids of the profiles in the Conversation
  final List<String> partiesIds;

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Conversation(
      id: data!['id'] as String,
      createdBy: data['createdBy'] as String,
      messageState: data['messageState'] == 'UNREAD'
          ? MessageState.UNREAD
          : MessageState.READ,
      recentMessage:
          Message.fromJson(data['recentMessage'] as Map<String, dynamic>?),
      createdOn: (data['createdOn'] as Timestamp).toDate(),
      lastEditBy: data['lastEditBy'] as String?,
      lastEditDate: (data['lastEditDate'] as Timestamp).toDate(),
      parties: (data['parties'] as List).map((e) => e as String).toList(),
      partiesIds: (data['partiesIds'] as List).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'parties': parties,
      'createdBy': createdBy,
      'createdOn': createdOn,
      'lastEditBy': lastEditBy,
      'partiesIds': partiesIds,
      'lastEditDate': lastEditDate,
      'recentMessage': recentMessage?.toFirestore(),
      'messageState': messageState == MessageState.UNREAD ? 'UNREAD' : 'READ',
    };
  }
}
