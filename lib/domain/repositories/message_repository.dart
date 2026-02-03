import '../entities/message.dart';

abstract class MessageRepository {
  // Get messages list (conversations)
  Future<List<Message>> getMessagesList();

  // Get single message by ID
  Future<Message> getMessage(String messageId);

  // Get messages for a conversation
  Future<List<Message>> getConversationMessages(int conversationId);

  // Send message
  Future<Message> sendMessage({
    required String text,
    required String userType,
    String? companyId,
    String? messageId, // UUID string
  });

  // Delete message
  Future<void> deleteMessage(String messageId);

  // Delete conversation
  Future<void> deleteConversation(String conversationId);

  // Mark messages as read
  Future<bool> markMessagesAsRead(List<String> messageIds);
}
