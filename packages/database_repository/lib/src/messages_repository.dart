// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

///  Interface for Firebase and Message and Groups
class MessagesRepository {
  /* *****    Messages      ***** */
  ///Constant to refer to the General Database Category
  static const String MESSAGES = 'Messages';

  /// Constant to refer to the specific Users Messages
  static const String MESSAGES_LIST = 'MessagesList';

  final _messageDatabaseReference =
      FirebaseFirestore.instance.collection(MESSAGES).withConverter<Message>(
            fromFirestore: Message.fromFirestore,
            toFirestore: (Message message, options) => message.toFirestore(),
          );

  ///  create or update [message]
  Future<void> createOrUpdateMessage({
    required Message message,
     String? id,
  }) {
    return FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(message.id)
        .collection(MESSAGES_LIST)
        .withConverter<Message>(
          fromFirestore: Message.fromFirestore,
          toFirestore: (Message message, options) => message.toFirestore(),
        )
        .doc(id ?? DateTime.now().millisecondsSinceEpoch.toString())
        .set(message);
  }

  /// retrieve Messages for User using their [id]
  Stream<QuerySnapshot> getMessages({required String id}) {
    return FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(id)
        .collection(MESSAGES_LIST)
        .withConverter<Message>(
          fromFirestore: Message.fromFirestore,
          toFirestore: (Message message, options) => message.toFirestore(),
        )
        .snapshots();
  }

  /// delete message [messageToDelete]
  void deleteMessage({
    required Message messageToDelete,
    required String id,
  }) {
    _messageDatabaseReference
        .doc(id)
        .collection(MESSAGES_LIST)
        .doc(messageToDelete.id)
        .delete();
  }

/*      *****     Groups      ****** */
  ///Constant for Groups
  static const String GROUPS = 'Groups';

  final _groupDatabaseReference =
      FirebaseFirestore.instance.collection(GROUPS).withConverter(
            fromFirestore: Group.fromFirestore,
            toFirestore: (Group group, options) => group.toFirestore(),
          );

  ///   create or update [group]
  Future<void> createOrUpdateGroup({required Group group}) {
    return _groupDatabaseReference.doc(group.id).set(group);
  }

  ///   Retrieves a List of Groups for a User
  Stream<QuerySnapshot> getGroups({required String userEmail}) {
    return _groupDatabaseReference
        .where('partiesIds', arrayContains: userEmail)
        .snapshots();
  }

  ///   Delete a group
  void deleteGroup({required Group group}) {
    _groupDatabaseReference.doc(group.id).delete();
  }
}
