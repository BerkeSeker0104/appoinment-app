import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../providers/message_provider.dart';
import '../../data/models/user_model.dart';
import '../../core/services/api_client.dart';
import '../pages/customer/barber_detail_page.dart';

class MessagingPanel extends StatefulWidget {
  final String receiverName;
  final String receiverImage;
  final String receiverId; // Conversation ID
  final String? companyId; // Company ID

  const MessagingPanel({
    super.key,
    required this.receiverName,
    required this.receiverImage,
    required this.receiverId,
    this.companyId,
  });

  @override
  State<MessagingPanel> createState() => _MessagingPanelState();
}

class _MessagingPanelState extends State<MessagingPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
    // İlk açılışta mesajları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshMessages();
      }
    });
  }

  Future<void> _refreshMessages() async {
    try {
      final messageProvider = context.read<MessageProvider>();
      final currentUser = await _getCurrentUser();
      if (currentUser != null) {
        // Önce conversation listesini yükle (eğer boşsa veya customer ise her zaman yenile)
        if (messageProvider.conversations.isEmpty ||
            (currentUser.isCustomer && widget.companyId != null)) {
          await messageProvider.loadMessagesList(companyId: widget.companyId);
        }

        // Customer için conversation ID'yi bul
        String? conversationId;
        if (currentUser.isCustomer && widget.companyId != null) {
          // Customer conversation listesinden bu company ile olan conversation ID'yi bul
          for (var conversation in messageProvider.conversations) {
            if (conversation.companyId?.toString() == widget.companyId) {
              // Orijinal ID'yi kullan (UUID string), yoksa id'yi string'e çevir
              conversationId =
                  conversation.originalId ?? conversation.id.toString();
              break;
            }
          }

          if (conversationId == null) {
            // Conversation henüz oluşmamış (yeni şube), boş mesaj listesi göster
            // Mesaj gönderildiğinde conversation oluşturulacak
            messageProvider.clearCurrentConversation();
            return;
          }
        } else if (currentUser.isCompany) {
          // Company için conversation listesini yükle (eğer boşsa)
          if (messageProvider.conversations.isEmpty) {
            await messageProvider.loadMessagesList(companyId: widget.companyId);
          }

          // Company için receiverId'yi conversation ID olarak kullan
          // Ama önce conversation listesinde bu ID'yi doğrula
          conversationId = widget.receiverId;

          // Conversation listesinde bu ID'yi kontrol et ve originalId varsa onu kullan
          for (var conversation in messageProvider.conversations) {
            final convIdStr =
                conversation.originalId ?? conversation.id.toString();
            if (convIdStr == widget.receiverId ||
                conversation.id.toString() == widget.receiverId) {
              conversationId =
                  conversation.originalId ?? conversation.id.toString();
              break;
            }
          }

        }

        if (conversationId != null) {
          // İlk yükleme değilse arka plan yenilemesi olarak işaretle
          final isBackgroundRefresh =
              messageProvider.currentMessages.isNotEmpty;

          await messageProvider.loadConversationMessages(
            conversationId: conversationId,
            companyId: widget.companyId ?? widget.receiverId,
            currentUser: currentUser,
            isBackgroundRefresh: isBackgroundRefresh,
          );

          // Mesajlar yüklendikten sonra okunmamış mesajları "okundu" olarak işaretle
          if (!isBackgroundRefresh) {
            final unreadMessageIds = messageProvider.currentMessages
                .where((msg) => !msg.isRead && !msg.isFromMe)
                .map((msg) => msg.id)
                .toList();

            if (unreadMessageIds.isNotEmpty) {
              await messageProvider.markMessagesAsRead(
                  unreadMessageIds.map((e) => e.toString()).toList());
            }
          }
        }

        if (mounted) {
          // Mesajlar yüklendikten sonra scroll'u biraz geciktir
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              _scrollToBottom();
            }
          });
        }
      }
    } catch (e) {
    }
  }

  Future<dynamic> _getCurrentUser() async {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessagesList()),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Header content
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.primaryLight.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: widget.receiverImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                        child: Image.network(
                          widget.receiverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultAvatar();
                          },
                        ),
                      )
                    : _buildDefaultAvatar(),
              ),
              const SizedBox(width: AppSpacing.md),

              // Name and status
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToCompanyDetail(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receiverName,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Çevrimiçi',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons removed
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.business,
      color: Colors.white,
      size: 20,
    );
  }

  Widget _buildMessagesList() {
    return Consumer<MessageProvider>(
      builder: (context, messageProvider, child) {
        // Sadece ilk yükleme için loading göster, arka plan yenilemeleri için gösterme
        if (messageProvider.isLoadingMessages &&
            !messageProvider.isBackgroundRefreshing) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (messageProvider.messagesError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Mesajlar yüklenemedi',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  messageProvider.messagesError ?? 'Bilinmeyen hata',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _refreshMessages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final messages = messageProvider.currentMessages;

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Henüz mesaj yok',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'İlk mesajınızı gönderin',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageBubble(message);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(dynamic message) {
    final isFromMe = message.isFromMe;
    final isUnread = !isFromMe && !message.isRead; // Okunmamış mesaj kontrolü

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromMe) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.8),
                    AppColors.primaryLight.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: widget.receiverImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      child: Image.network(
                        widget.receiverImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.business,
                            color: Colors.white,
                            size: 16,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isFromMe
                    ? AppColors.primary
                    : (isUnread
                        ? AppColors.primary.withValues(alpha: 
                            0.1) // Okunmamış mesajlar için açık mavi arka plan
                        : AppColors.backgroundSecondary),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  topRight: Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(
                      isFromMe ? AppSpacing.radiusLg : AppSpacing.radiusSm),
                  bottomRight: Radius.circular(
                      isFromMe ? AppSpacing.radiusSm : AppSpacing.radiusLg),
                ),
                border: isFromMe
                    ? null
                    : Border.all(
                        color: isUnread
                            ? AppColors.primary.withValues(alpha: 
                                0.3) // Okunmamış mesajlar için mavi border
                            : AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isFromMe
                          ? Colors.white
                          : (isUnread
                              ? AppColors
                                  .primary // Okunmamış mesajlar için mavi metin
                              : AppColors.textPrimary),
                      fontWeight: isUnread
                          ? FontWeight.w600
                          : FontWeight
                              .normal, // Okunmamış mesajlar için kalın yazı
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: AppTypography.caption.copyWith(
                          color: isFromMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      if (isFromMe) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.done_all, // Her zaman çift tik göster
                          size: 12,
                          color: message.isRead
                              ? Colors.blue // Okunduğunda mavi çift tik
                              : Colors.grey, // Okunmadığında gri çift tik
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        GestureDetector(
                          onTap: () => _confirmDeleteMessage(message.id),
                          child: Icon(
                            Icons.delete_outline,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Message input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _messageController,
                  style: AppTypography.bodyMedium,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Send button
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color:
                      _isSending ? AppColors.textTertiary : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: _isSending
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Mesajı Sil',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Bu mesajı silmek istediğinizden emin misiniz?',
          style: AppTypography.body1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: Text(
              'Sil',
              style: AppTypography.body1.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final messageProvider = context.read<MessageProvider>();
      await messageProvider.deleteMessage(messageId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj silindi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Mesaj silinirken hata oluştu: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final currentUser = await _getCurrentUser();
      if (currentUser == null) {
        throw Exception('Kullanıcı bilgisi alınamadı');
      }

      final messageProvider = context.read<MessageProvider>();
      await messageProvider.sendMessage(
        text: text,
        userType: currentUser.isCustomer ? 'customer' : 'company',
        companyId: currentUser.isCustomer ? widget.companyId : widget.companyId,
        messageId: currentUser.isCompany
            ? widget.receiverId
            : null, // UUID string olarak gönder
      );

      _messageController.clear();

      // Yeni şube için conversation oluşması için kısa bir bekleme
      if (currentUser.isCustomer && widget.companyId != null) {
        // Conversation listesini hemen yeniden yükle (mesaj gönderildikten sonra conversation oluşur)
        await messageProvider.loadMessagesList(companyId: widget.companyId);
        // Backend'in conversation oluşturması ve mesajın commit edilmesi için bekleme
        await Future.delayed(const Duration(milliseconds: 800));
        // Tekrar yükle (yeni conversation'ı garantilemek için)
        await messageProvider.loadMessagesList(companyId: widget.companyId);
      } else {
        // Company için veya conversation zaten varsa kısa bekleme
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Mesaj gönderildikten sonra conversation mesajlarını yenile
      await _refreshMessages();

      // Ek bir yenileme yap (mesajın backend'de commit edilmesi için)
      await Future.delayed(const Duration(milliseconds: 300));
      await _refreshMessages();

      // Scroll'u biraz geciktir
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _scrollToBottom();
        }
      });
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Mesaj gönderilemedi';

        if (e.toString().contains('bakımda')) {
          errorMessage =
              'Mesajlaşma sistemi şu anda bakımda. Lütfen daha sonra tekrar deneyin.';
        } else if (e.toString().contains('Unknown column')) {
          errorMessage = 'Sistem hatası. Lütfen daha sonra tekrar deneyin.';
        } else {
          errorMessage =
              'Mesaj gönderilemedi: ${e.toString().split(':').last.trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}sa önce';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Future<void> _navigateToCompanyDetail() async {
    try {
      final currentUser = await _getCurrentUser();
      // Sadece customer ise ve companyId varsa işletme detay sayfasına git
      if (currentUser != null && 
          currentUser.isCustomer && 
          widget.companyId != null && 
          widget.companyId!.isNotEmpty) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarberDetailPage(
                companyId: widget.companyId!,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
  }
}
