import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/message_repository.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../data/services/message_api_service.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/user_model.dart';
import '../../core/services/api_client.dart';
import '../../core/services/app_lifecycle_service.dart';

class MessageProvider with ChangeNotifier implements LoadingStateResettable {
  final MessageRepository _messageRepository;
  Timer? _refreshTimer;
  bool _isLoading = false;
  String? _error;
  
  // Flag to prevent multiple auto-refresh instances
  bool _isAutoRefreshActive = false;

  // Messages list state
  List<ConversationModel> _conversations = [];

  // Single conversation state
  List<Message> _currentMessages = [];
  bool _isLoadingMessages = false;
  bool _isBackgroundRefreshing = false;
  String? _messagesError;

  MessageProvider()
      : _messageRepository = MessageRepositoryImpl(MessageApiService());

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<Message> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isBackgroundRefreshing => _isBackgroundRefreshing;
  String? get error => _error;
  String? get messagesError => _messagesError;

  // Start auto-refresh for messages list
  void startAutoRefresh({String? companyId}) {
    // CRITICAL FIX: Prevent multiple auto-refresh instances
    // This was causing 100+ message notifications because timers were accumulating
    if (_isAutoRefreshActive) {
      return; // Already active, don't create new timers
    }
    
    _refreshTimer?.cancel();
    
    // Mark as active BEFORE creating timer
    _isAutoRefreshActive = true;
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadMessagesList(companyId: companyId);
    });
    // İlk yükleme
    _loadMessagesList(companyId: companyId);
  }

  // Stop auto-refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    
    // Mark as inactive
    _isAutoRefreshActive = false;
  }

  // Load messages list
  Future<void> _loadMessagesList({String? companyId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current user to determine user type
      final currentUser = await _getCurrentUser();
      String? finalCompanyId = companyId;

      // If user is a company and no specific companyId provided, get their company ID
      if (currentUser != null &&
          currentUser.isCompany &&
          finalCompanyId == null) {
        finalCompanyId = await _getCurrentUserCompanyId();
      }

      // API service'i direkt kullan - yeni endpoint ile
      final messageApiService = MessageApiService();
      final conversationsList = await messageApiService.getMessagesList(
        companyId: finalCompanyId,
      );

      _conversations = conversationsList;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;

      // Check if error is due to unauthorized (guest user)
      final errorString = e.toString().toLowerCase();
      final isUnauthorized = errorString.contains('unauthorized') ||
                            errorString.contains('401') ||
                            errorString.contains('yetkisiz');

      // Eğer "kullanıcı seçiniz" veya "şube seçiniz" hatası ise, bu normal (henüz mesaj yok)
      if (e.toString().contains('Mesajı göndereceğiniz kullanıcıyı seçiniz') ||
          e.toString().contains('Şube seçiniz')) {
        _conversations = [];
        _error = null; // Hata olarak gösterme
      } else if (isUnauthorized) {
        // Don't set error for guest users - overlay will handle it
        _conversations = [];
        _error = null;
      } else {
        _error = e.toString();
      }

      notifyListeners();
    }
  }

  // Load messages list (public method for manual refresh)
  Future<void> loadMessagesList({String? companyId}) async {
    await _loadMessagesList(companyId: companyId);
  }

  // Load single conversation messages
  Future<void> loadConversationMessages({
    required String conversationId,
    required String companyId,
    required User currentUser,
    bool isBackgroundRefresh = false,
  }) async {
    try {
      if (isBackgroundRefresh) {
        _isBackgroundRefreshing = true;
      } else {
        _isLoadingMessages = true;
      }
      _messagesError = null;
      notifyListeners();

      // Get all messages for the conversation
      // Conversation ID string (UUID) olarak kullan (backend UUID döndürüyor)
      final messageApiService = MessageApiService();
      final messageModels =
          await messageApiService.getConversationMessages(conversationId);
      final messages = messageModels.map((model) => model.toEntity()).toList();

      // Set isFromMe property for each message with additional fallbacks
      final currentUserId = currentUser.id;
      final updatedMessages = messages.map((message) {
        final isFromMe = _isMessageFromCurrentUser(
          message: message,
          currentUserId: currentUserId,
          isCompanyUser: currentUser.isCompany,
          conversationCompanyId: companyId,
        );
        // Backend'den gelen isRead değerini kullan (0 = okunmamış, 1 = okunmuş)
        // Sadece kendi mesajlarımız için isRead anlamlı (alıcı tarafından okunmuş mu?)
        // Başkalarının mesajları için isRead değeri backend'den gelir (biz tarafından okunmuş mu?)
        return message.copyWith(isFromMe: isFromMe);
      }).toList();

      // Mesajları tarihe göre sırala (en eski üstte, en yeni altta)
      updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _currentMessages = updatedMessages;

      if (isBackgroundRefresh) {
        _isBackgroundRefreshing = false;
      } else {
        _isLoadingMessages = false;
      }
      notifyListeners();
    } catch (e) {
      if (isBackgroundRefresh) {
        _isBackgroundRefreshing = false;
      } else {
        _isLoadingMessages = false;
      }
      _messagesError = e.toString();
      notifyListeners();
    }
  }

  // Send message
  Future<void> sendMessage({
    required String text,
    required String userType,
    String? companyId,
    String? messageId, // UUID string
  }) async {
    try {
      await _messageRepository.sendMessage(
        text: text,
        userType: userType,
        companyId: companyId,
        messageId: messageId,
      );

      // Mesaj listesini yenile - yeni conversation oluşması için
      await _loadMessagesList();

      // Yeni şube için conversation henüz oluşmamış olabilir, retry mekanizması
      int retryCount = 0;
      const maxRetries = 3;

      while (retryCount < maxRetries) {
        // Eğer açık bir sohbet varsa, o sohbetin mesajlarını da yenile
        if (companyId != null) {
          try {
            // Company ID'den conversation ID'yi bul
            ConversationModel? conversation;
            try {
              conversation = _conversations.firstWhere(
                (conv) => conv.companyId != null &&
                    conv.companyId.toString() == companyId,
              );
            } catch (_) {
              conversation = null;
            }

            if (conversation == null) {
              throw Exception('Conversation not found');
            }

            // Sohbet mesajlarını yeniden yükle
            // Conversation ID'yi string olarak kullan (backend UUID döndürüyor)
            final conversationIdString =
                conversation.originalId ?? conversation.id.toString();
            final messageApiService = MessageApiService();
            final messageModels = await messageApiService
                .getConversationMessages(conversationIdString);
            final messages =
                messageModels.map((model) => model.toEntity()).toList();

            // Current user ID'yi al ve isFromMe property'sini set et
            final currentUserId = await _getCurrentUserId();
            if (currentUserId != null) {
              final updatedMessages = messages.map((message) {
                final isFromMe = _isMessageFromCurrentUser(
                  message: message,
                  currentUserId: currentUserId,
                  isCompanyUser: userType.toLowerCase() == 'company',
                  conversationCompanyId: companyId,
                );
                // Backend'den gelen isRead değerini koru
                return message.copyWith(isFromMe: isFromMe);
              }).toList();

              // Mesajları tarihe göre sırala (en eski üstte, en yeni altta)
              updatedMessages
                  .sort((a, b) => a.createdAt.compareTo(b.createdAt));
              _currentMessages = updatedMessages;
            } else {
              _currentMessages = messages;
            }
            notifyListeners();
            break; // Conversation bulundu, döngüden çık
          } catch (e) {
            // Conversation bulunamadı, retry dene
            retryCount++;
            if (retryCount < maxRetries) {
              // Kısa bir bekleme sonrası conversation listesini tekrar yükle
              await Future.delayed(const Duration(milliseconds: 500));
              await _loadMessagesList();
            } else {
              // Son deneme de başarısız oldu, yeni conversation henüz oluşmamış olabilir
              // Boş mesaj listesi göster - kullanıcı tekrar mesaj gönderebilir
              _currentMessages.clear();
              notifyListeners();
            }
          }
        } else {
          break; // companyId yoksa döngüden çık
        }
      }
    } catch (e) {
      // Backend hatalarını daha kullanıcı dostu hale getir
      String errorMessage = e.toString();

      if (e.toString().contains('bakımda')) {
        errorMessage =
            'Mesajlaşma sistemi şu anda bakımda. Lütfen daha sonra tekrar deneyin.';
      } else if (e.toString().contains('Unknown column')) {
        errorMessage = 'Sistem hatası. Lütfen daha sonra tekrar deneyin.';
      }

      _messagesError = errorMessage;
      notifyListeners();
      rethrow; // Hata fırlat ki UI'da gösterilebilsin
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageRepository.deleteMessage(messageId);

      // Mesajı listeden çıkar
      _currentMessages.removeWhere((msg) => msg.id == messageId);
      notifyListeners();

      // Mesaj listesini yenile
      await _loadMessagesList();
    } catch (e) {
      _messagesError = e.toString();
      notifyListeners();
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _messageRepository.deleteConversation(conversationId);

      // Sohbeti listeden çıkar - UUID formatında originalId veya id ile eşleştir
      _conversations.removeWhere((conv) {
        final convId = conv.originalId ?? conv.id.toString();
        return convId == conversationId;
      });
      notifyListeners();

      // Mesaj listesini yenile
      await _loadMessagesList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    try {
      final success = await _messageRepository.markMessagesAsRead(messageIds);
      if (success) {
        // Local state'i güncelle - mesajları okundu olarak işaretle
        for (int i = 0; i < _currentMessages.length; i++) {
          if (messageIds.contains(_currentMessages[i].id)) {
            _currentMessages[i] = _currentMessages[i].copyWith(isRead: true);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      // Hata durumunda sessizce devam et, kullanıcıyı rahatsız etme
    }
  }

  // Clear current conversation
  void clearCurrentConversation() {
    _currentMessages.clear();
    _messagesError = null;
    notifyListeners();
  }

  // Get current user ID helper method
  Future<String?> _getCurrentUserId() async {
    try {
      final apiClient = ApiClient();
      final userJson = await apiClient.getUserJson();
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return userMap['id']?.toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get unread messages count
  int getUnreadCount() {
    return _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  // Helper method to get current user
  Future<User?> _getCurrentUser() async {
    try {
      final apiClient = ApiClient();
      final userJson = await apiClient.getUserJson();
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap).toEntity();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper method to get current user's company ID
  Future<String?> _getCurrentUserCompanyId() async {
    try {
      final apiClient = ApiClient();
      final userJson = await apiClient.getUserJson();
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap).toEntity();

        // For company users, we need to get their company/branch ID from branches API
        if (user.isCompany) {
          try {
            // Get company branches to find the company ID
            final response = await apiClient.get('/api/company');
            if (response.statusCode == 200) {
              final data = response.data;
              if (data['status'] == true &&
                  data['data'] is List &&
                  data['data'].isNotEmpty) {
                final branches = (data['data'] as List)
                    .whereType<Map<String, dynamic>>()
                    .toList();

                if (branches.isEmpty) {
                  return null;
                }

                Map<String, dynamic>? mainBranch;
                for (final branch in branches) {
                  final isMain = branch['isMain'] == 1 ||
                      branch['isMain'] == true ||
                      branch['isMain'] == '1';
                  if (isMain) {
                    mainBranch = branch;
                    break;
                  }
                }

                final targetBranch = mainBranch ?? branches.first;
                return targetBranch['id']?.toString();
              }
            }
          } catch (e) {
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String? _normalizeId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return null;
    }
    return trimmed;
  }

  bool _isMessageFromCurrentUser({
    required Message message,
    required String currentUserId,
    required bool isCompanyUser,
    String? conversationCompanyId,
  }) {
    final normalizedCurrentUserId = _normalizeId(currentUserId);
    final normalizedCompanyId =
        _normalizeId(message.companyId) ?? _normalizeId(conversationCompanyId);
    final normalizedCustomerId = _normalizeId(message.customerId);
    final normalizedSenderId = _normalizeId(message.senderId);
    final normalizedReceiverId = _normalizeId(message.receiverId);

    if (normalizedCurrentUserId == null) {
      return false;
    }

    if (isCompanyUser) {
      // Primary checks using sender info
      if (normalizedSenderId != null) {
        if (normalizedSenderId == normalizedCurrentUserId ||
            (normalizedCompanyId != null &&
                normalizedSenderId == normalizedCompanyId)) {
          return true;
        }

        if (normalizedCustomerId != null &&
            normalizedSenderId == normalizedCustomerId) {
          return false;
        }
      }

      // Fallback using receiver info
      if (normalizedReceiverId != null) {
        if (normalizedCustomerId != null &&
            normalizedReceiverId == normalizedCustomerId) {
          return true;
        }

        if (normalizedReceiverId == normalizedCurrentUserId ||
            (normalizedCompanyId != null &&
                normalizedReceiverId == normalizedCompanyId)) {
          return false;
        }
      }

      return false;
    } else {
      // Customer user checks
      if (normalizedSenderId != null) {
        if (normalizedSenderId == normalizedCurrentUserId ||
            (normalizedCustomerId != null &&
                normalizedSenderId == normalizedCustomerId)) {
          return true;
        }

        if (normalizedCompanyId != null &&
            normalizedSenderId == normalizedCompanyId) {
          return false;
        }
      }

      if (normalizedReceiverId != null) {
        if (normalizedCompanyId != null &&
            normalizedReceiverId == normalizedCompanyId) {
          return true;
        }

        if (normalizedReceiverId == normalizedCurrentUserId ||
            (normalizedCustomerId != null &&
                normalizedReceiverId == normalizedCustomerId)) {
          return false;
        }
      }

      return false;
    }
  }

  /// Reset loading states - called when app resumes from background
  @override
  void resetLoadingState() {
    if (_isLoading || _isLoadingMessages || _isBackgroundRefreshing) {
      _isLoading = false;
      _isLoadingMessages = false;
      _isBackgroundRefreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    AppLifecycleService().unregisterProvider(this);
    stopAutoRefresh();
    super.dispose();
  }
}
