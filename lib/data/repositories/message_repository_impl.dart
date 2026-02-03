import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../services/message_api_service.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageApiService _messageApiService;

  MessageRepositoryImpl(this._messageApiService);

  @override
  Future<List<Message>> getMessagesList() async {
    try {
      final conversations = await _messageApiService.getMessagesList();
      // Conversations'ı Message'lara dönüştür (şimdilik basit bir mapping)
      return conversations
          .map((conv) => Message(
                id: conv.id.toString(),
                text: conv.lastMessage ?? '',
                createdAt: conv.lastMessageTime ?? DateTime.now(),
                companyId: conv.companyId,
                customerId: conv.customerId,
              ))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Message> getMessage(String messageId) async {
    try {
      final messageModel = await _messageApiService.getMessage(messageId);
      return messageModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Message>> getConversationMessages(int conversationId) async {
    try {
      // conversationId zaten int, direkt kullanabiliriz
      // Ama API service string kabul ediyor, bu yüzden toString kullanıyoruz
      final messageModels =
          await _messageApiService.getConversationMessages(conversationId);
      return messageModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  // String conversation ID için ek metod
  Future<List<Message>> getConversationMessagesByString(
      String conversationId) async {
    try {
      final messageModels =
          await _messageApiService.getConversationMessages(conversationId);
      return messageModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Message> sendMessage({
    required String text,
    required String userType,
    String? companyId,
    String? messageId, // UUID string
  }) async {
    try {
      final messageModel = await _messageApiService.sendMessage(
        text: text,
        userType: userType,
        companyId: companyId,
        messageId: messageId,
      );
      return messageModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageApiService.deleteMessage(messageId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _messageApiService.deleteConversation(conversationId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> markMessagesAsRead(List<String> messageIds) async {
    try {
      return await _messageApiService.markMessagesAsRead(messageIds);
    } catch (e) {
      rethrow;
    }
  }
}
