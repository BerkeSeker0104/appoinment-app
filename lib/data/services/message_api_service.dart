import 'dart:convert';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

class MessageApiService {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  // Get messages list (conversations)
  Future<List<ConversationModel>> getMessagesList({
    String? companyId,
    int page = 1,
    int dataCount = 20,
  }) async {
    try {
      // Yeni endpoint: /api/message/list?companyId=1&page=1&dataCount=20
      final String endpoint = '${ApiConstants.messages}/list';
      final Map<String, dynamic> queryParams = {
        'page': page,
        'dataCount': dataCount,
      };

      if (companyId != null) {
        queryParams['companyId'] = companyId;
      }

      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParams,
      );
      final data = _asMap(response.data);

      if (data['status'] == true && data['data'] is List) {
        final messagesList = (data['data'] as List)
            .map((json) => ConversationModel.fromJson(json))
            .toList();

        return messagesList;
      } else {
        return [];
      }
    } catch (e) {
      // Eğer 400 hatası alırsak, boş liste döndür (henüz mesaj yok)
      if (e.toString().contains('Mesajı göndereceğiniz kullanıcıyı seçiniz')) {
        return [];
      }

      rethrow;
    }
  }

  // Get single message by ID
  Future<MessageModel> getMessage(String messageId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.messages,
        queryParameters: {'messageId': messageId},
      );
      final data = _asMap(response.data);

      if (data['status'] == true && data['data'] != null) {
        // Handle case where data['data'] might be a List instead of Map
        final messageData = data['data'];

        if (messageData is Map<String, dynamic>) {
          return MessageModel.fromJson(messageData);
        } else if (messageData is List && messageData.isNotEmpty) {
          // If it's a list, take the first message
          final firstMessage = messageData.first;
          if (firstMessage is Map<String, dynamic>) {
            return MessageModel.fromJson(firstMessage);
          }
        }

        // If data is empty array or invalid format, throw appropriate error
        throw Exception('No messages found for this conversation');
      } else {
        throw Exception('Message not found');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get messages for a conversation
  Future<List<MessageModel>> getConversationMessages(
      dynamic conversationId) async {
    try {
      // Conversation ID string (UUID) veya int olabilir
      final conversationIdParam = conversationId.toString();

      final response = await _apiClient.get(
        ApiConstants.messages,
        queryParameters: {'messageId': conversationIdParam},
      );
      final data = _asMap(response.data);

      if (data['status'] == true && data['data'] != null) {
        final messageData = data['data'];

        if (messageData is List) {
          // Parse all messages in the list
          return messageData
              .map((msgJson) =>
                  MessageModel.fromJson(msgJson as Map<String, dynamic>))
              .toList();
        } else if (messageData is Map<String, dynamic>) {
          // Single message
          return [MessageModel.fromJson(messageData)];
        }
      }

      // Return empty list if no messages found
      return [];
    } catch (e) {
      // Return empty list instead of throwing error for empty conversations
      return [];
    }
  }

  // Mark messages as read
  Future<bool> markMessagesAsRead(List<String> messageIds) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.messages}/mark-read',
        data: {
          'messageIds': messageIds,
        },
      );
      final data = _asMap(response.data);

      if (data['status'] == true) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      rethrow;
    }
  }

  // Send message
  Future<MessageModel> sendMessage({
    required String text,
    required String userType,
    String? companyId,
    String? messageId, // UUID string
  }) async {
    try {
      Map<String, dynamic> requestData = {'text': text};

      // Müşteri mesaj atarken companyId gönder
      if (userType == 'customer' && companyId != null) {
        requestData['companyId'] = companyId;
      }
      // Firma mesaj atarken messageId ve companyId gönder
      else if (userType == 'company' &&
          messageId != null &&
          companyId != null) {
        requestData['messageId'] = messageId; // UUID string olarak gönder
        requestData['companyId'] = companyId;
      } else {
        throw Exception('Invalid message parameters');
      }

      final response = await _apiClient.post(
        ApiConstants.messages,
        data: requestData,
      );
      final data = _asMap(response.data);

      if (data['status'] == true && data['data'] != null) {
        try {
          return MessageModel.fromJson(data['data']);
        } catch (e) {
          throw Exception(
              'Mesaj gönderildi ancak yanıt işlenirken hata oluştu');
        }
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {

      // Backend database hatası için özel mesaj
      if (e.toString().contains('Unknown column') ||
          e.toString().contains('Oluşturulurken hata oluştu')) {
        throw Exception(
            'Mesajlaşma sistemi şu anda bakımda. Lütfen daha sonra tekrar deneyin.');
      }

      // ApiClient zaten validation hatalarını parse ediyor, bu yüzden direkt rethrow
      rethrow;
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      final response =
          await _apiClient.delete('${ApiConstants.messages}/$messageId');

      final data = _asMap(response.data);
      if (data['status'] != true) {
        throw Exception('Failed to delete message');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete conversation using the new endpoint
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Use the new endpoint: DELETE /api/message/delete/{conversationId}
      // conversationId should be in UUID format
      final response = await _apiClient.delete(
        '${ApiConstants.messages}/delete/$conversationId',
      );

      final data = _asMap(response.data);
      if (data['status'] != true) {
        throw Exception('Failed to delete conversation');
      }
    } catch (e) {
      rethrow;
    }
  }
}
