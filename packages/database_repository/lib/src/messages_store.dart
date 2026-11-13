import 'package:database_repository/src/models/models.dart';

/// Backend-neutral interface for messages and conversations persistence.
abstract interface class MessagesStore {
  /// Creates or updates [message] in its conversation.
  Future<void> createOrUpdateMessage({required Message message});

  /// Streams messages for [conversationId].
  Stream<List<Message>> getMessages({required String conversationId});

  /// Deletes [messageToDelete] from [conversationId].
  void deleteMessage({
    required Message messageToDelete,
    required String conversationId,
  });

  /// Creates or updates [conversation].
  Future<void> createOrUpdateConversation({required Conversation conversation});

  /// Streams conversations involving [userEmail].
  Stream<List<Conversation>> getConversations({required String userEmail});

  /// Deletes [conversation].
  void deleteConversation({required Conversation conversation});
}
