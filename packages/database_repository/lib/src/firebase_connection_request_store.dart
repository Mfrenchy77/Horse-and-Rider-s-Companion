import 'package:database_repository/src/connection_request.dart';
import 'package:database_repository/src/connection_request_store.dart';
import 'package:database_repository/src/messages_repository.dart';
import 'package:database_repository/src/messages_store.dart';
import 'package:database_repository/src/models/models.dart';

/// Transitional [ConnectionRequestStore] backed by existing `Conversations`
/// and `Messages` Firestore structures so production behavior and
/// `onMessageCreated` notifications remain intact prior to cutover.
class FirebaseConnectionRequestStore implements ConnectionRequestStore {
  /// Creates a [FirebaseConnectionRequestStore] delegating to [messagesStore].
  FirebaseConnectionRequestStore({MessagesStore? messagesStore})
    : _messagesStore = messagesStore ?? MessagesRepository();

  final MessagesStore _messagesStore;

  @override
  Stream<List<ConnectionRequest>> watchRequests({required String userEmail}) {
    return _messagesStore
        .getConversations(userEmail: userEmail)
        .map(
          (conversations) => [
            for (final conversation in conversations)
              if (ConnectionRequest.fromLegacyMessage(
                    conversation.recentMessage,
                    conversation: conversation,
                  )
                  case final request?)
                request,
          ],
        );
  }

  @override
  Future<void> sendRequest(ConnectionRequest request) async {
    final legacyMessage = request.toLegacyMessage();
    final parties = request.parties.isNotEmpty
        ? request.parties
        : [request.senderName, request.recipientName];
    final partiesIds = request.partiesIds.isNotEmpty
        ? request.partiesIds
        : [
            request.senderEmail.toLowerCase(),
            request.recipientEmail.toLowerCase(),
          ];
    final conversation = Conversation(
      id: request.id,
      parties: parties,
      partiesIds: partiesIds,
      createdOn: request.createdAt,
      lastEditDate: request.createdAt,
      createdBy: request.senderName,
      lastEditBy: request.senderName,
      recentMessage: legacyMessage,
    );
    await _messagesStore.createOrUpdateConversation(conversation: conversation);
    await _messagesStore.createOrUpdateMessage(message: legacyMessage);
  }

  @override
  Future<void> dismissRequest({
    required ConnectionRequest request,
    required String dismissalNote,
  }) async {
    final dismissedMessage = request.toLegacyMessage(
      overrideType: MessageType.CHAT,
      overrideSummary: dismissalNote,
    );
    await _messagesStore.createOrUpdateMessage(message: dismissedMessage);
  }
}
