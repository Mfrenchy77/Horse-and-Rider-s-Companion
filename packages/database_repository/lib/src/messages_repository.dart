// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';

///  Interface for Firebase and Message and Groups
class MessagesRepository {
  /* *****    Messages      ***** */
  ///Constant to refer to the General Database Category
  static const String MESSAGES = 'Messages';

  // final _messageDatabaseReference =
  //     FirebaseFirestore.instance.collection(MESSAGES).withConverter<Message>(
  //           fromFirestore: Message.fromFirestore,
  //           toFirestore: (Message message, options) => message.toFirestore(),
  //         );

  ///  create or update [message]
  Future<void> createOrUpdateMessage({required Message message}) {
    return FirebaseFirestore.instance
        .collection(CONVERSATIONS)
        .doc(message.id)
        .collection(MESSAGES)
        .withConverter<Message>(
          fromFirestore: Message.fromFirestore,
          toFirestore: (Message message, options) => message.toFirestore(),
        )
        .doc(message.messsageId)
        .set(message);
  }

  /// retrieve Messages for User using their [conversationId]
  Stream<QuerySnapshot> getMessages({required String conversationId}) {
    return FirebaseFirestore.instance
        .collection(CONVERSATIONS)
        .doc(conversationId)
        .collection(MESSAGES)
        .withConverter<Message>(
          fromFirestore: Message.fromFirestore,
          toFirestore: (Message message, options) => message.toFirestore(),
        )
        .snapshots();
  }

  /// delete message [messageToDelete]
  void deleteMessage({
    required Message messageToDelete,
    required String conversationId,
  }) {
    FirebaseFirestore.instance
        .collection(CONVERSATIONS)
        .doc(conversationId)
        .collection(MESSAGES)
        .doc(messageToDelete.id)
        .delete();
  }

/* ****************************************************************************

                                      Conversations

  *************************************************************************** */

  ///Constant for Conversations
  static const String CONVERSATIONS = 'Conversations';

  final _groupDatabaseReference =
      FirebaseFirestore.instance.collection(CONVERSATIONS).withConverter(
            fromFirestore: Conversation.fromFirestore,
            toFirestore: (Conversation conversation, options) =>
                conversation.toFirestore(),
          );

  ///   create or update [conversation]
  Future<void> createOrUpdateConversation({
    required Conversation conversation,
  }) {
    return _groupDatabaseReference.doc(conversation.id).set(conversation);
  }

  ///   Retrieves a List of Groups for a User
  Stream<QuerySnapshot> getConversations({required String userEmail}) {
    return _groupDatabaseReference
        .where('partiesIds', arrayContains: userEmail)
        .snapshots();
  }

  ///   Delete a group
  void deleteConversation({required Conversation conversation}) {
    _groupDatabaseReference.doc(conversation.id).delete();
  }
}
