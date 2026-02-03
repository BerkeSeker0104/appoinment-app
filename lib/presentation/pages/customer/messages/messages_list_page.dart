import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/message_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../widgets/messaging_panel.dart';
import '../../../widgets/guest_auth_overlay.dart';
import '../../../../l10n/app_localizations.dart';

class MessagesListPage extends StatefulWidget {
  const MessagesListPage({super.key});

  @override
  State<MessagesListPage> createState() => _MessagesListPageState();
}

class _MessagesListPageState extends State<MessagesListPage> {
  @override
  void initState() {
    super.initState();
    // Auto-refresh başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // Auto-refresh durdur - güvenli şekilde
    try {
      if (mounted) {
        context.read<MessageProvider>().stopAutoRefresh();
      }
    } catch (e) {
      // Dispose sırasında hata olursa ignore et
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: GuestAuthOverlay(
        child: Consumer<MessageProvider>(
          builder: (context, messageProvider, child) {
            if (messageProvider.isLoading &&
                messageProvider.conversations.isEmpty) {
              return _buildLoadingState();
            }

            // Don't show error if it's unauthorized (guest users handled by overlay)
            final error = messageProvider.error;
            final isUnauthorized = error != null &&
                (error.toLowerCase().contains('unauthorized') ||
                 error.toLowerCase().contains('401') ||
                 error.toLowerCase().contains('yetkisiz'));

            if (error != null && !isUnauthorized) {
              return _buildErrorState(messageProvider);
            }

            if (messageProvider.conversations.isEmpty) {
              return _buildEmptyState();
            }

            return _buildConversationsList(messageProvider);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Text(
        AppLocalizations.of(context)!.messages,
        style: AppTypography.h5.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)!.messagesLoading,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(MessageProvider messageProvider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.errorOccurred,
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              messageProvider.error?.contains(
                          'Mesajı göndereceğiniz kullanıcıyı seçiniz') ==
                      true
                  ? AppLocalizations.of(context)!.noMessagesYet
                  : (messageProvider.error ?? AppLocalizations.of(context)!.unknownError),
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {
                messageProvider.loadMessagesList();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primaryLight.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.noMessagesYet,
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.customerMessagesEmptyDesc,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList(MessageProvider messageProvider) {
    return RefreshIndicator(
      onRefresh: messageProvider.loadMessagesList,
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: messageProvider.conversations.length,
        itemBuilder: (context, index) {
          final conversation = messageProvider.conversations[index];
          return _buildConversationItem(conversation);
        },
      ),
    );
  }

  Widget _buildConversationItem(dynamic conversation) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.xs,
      ),
      child: Dismissible(
        key: Key(conversation.id.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (_) => _showDeleteConfirmation(conversation),
        onDismissed: (_) {
          _deleteConversation(conversation);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _openConversation(conversation);
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.8),
                            AppColors.primaryLight.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      child: conversation.companyImage != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusXl),
                              child: Image.network(
                                conversation.companyImage!.startsWith('http')
                                    ? conversation.companyImage!
                                    : '${ApiConstants.fileUrl}${conversation.companyImage!}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultAvatar(conversation);
                                },
                              ),
                            )
                          : _buildDefaultAvatar(conversation),
                    ),
                    SizedBox(width: AppSpacing.md),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.companyName ??
                                      AppLocalizations.of(context)!
                                          .unknownCompany,
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (conversation.lastMessageTime != null)
                                Text(
                                  _formatTime(conversation.lastMessageTime!),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.xs),

                          // Last message and unread count
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  conversation.lastMessage ??
                                      AppLocalizations.of(context)!
                                          .noMessagesYet,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              // Okunmamış mesaj göstergesi sadece unreadCount > 0 olduğunda göster
                              if (conversation.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusXl),
                                  ),
                                  child: Text(
                                    conversation.unreadCount.toString(),
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(dynamic conversation) {
    return Icon(
      Icons.business,
      color: Colors.white,
      size: 24,
    );
  }

  void _openConversation(dynamic conversation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MessagingPanel(
        receiverName: conversation.companyName ?? AppLocalizations.of(context)!.barber,
        receiverImage: conversation.companyImage != null
            ? (conversation.companyImage!.startsWith('http')
                ? conversation.companyImage!
                : '${ApiConstants.fileUrl}${conversation.companyImage!}')
            : '',
        receiverId: conversation.id.toString(), // Conversation ID
        companyId: conversation.companyId?.toString(), // Company ID
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return AppLocalizations.of(context)!.now;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${AppLocalizations.of(context)!.min}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${AppLocalizations.of(context)!.hour}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${AppLocalizations.of(context)!.day}';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Future<bool?> _showDeleteConfirmation(dynamic conversation) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteChat,
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteCompanyChatConfirm(
              conversation.companyName ??
                  AppLocalizations.of(context)!.unknownCompany),
          style: AppTypography.body1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
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

  Future<void> _deleteConversation(dynamic conversation) async {
    try {
      final messageProvider = context.read<MessageProvider>();
      // UUID formatında conversation ID'yi al (originalId varsa onu kullan, yoksa id'yi string'e çevir)
      final conversationId = conversation.originalId ?? conversation.id.toString();
      await messageProvider.deleteConversation(conversationId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chatDeleted),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.chatDeleteError}: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
