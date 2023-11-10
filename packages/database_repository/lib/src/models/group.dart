// ignore_for_file: constant_identifier_names,
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

/// The Differnt type of Message Groups
enum GroupType { private, group }

/// This is where groups of Messages will be referenced for Users
class Group {
  Group({
    required this.id,
    required this.type,
    required this.parties,
    required this.partiesIds,
    required this.createdBy,
    required this.createdOn,
    required this.lastEditBy,
    required this.lastEditDate,
    required this.recentMessage,
    this.messageState = MessageState.UNREAD,
  });

  final String id;
  final GroupType type;
  final String createdBy;
  final DateTime createdOn;
  final List<String> parties;
  final List<String> partiesIds;
  String? lastEditBy;
  DateTime lastEditDate;
  Message? recentMessage;
  MessageState messageState;

  factory Group.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    // ignore: avoid_unused_constructor_parameters
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Group(
      id: data!['id'] as String,
      type: data['type'] == 'group' ? GroupType.group : GroupType.private,
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
      'type': type == GroupType.group ? 'group' : 'private',
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
