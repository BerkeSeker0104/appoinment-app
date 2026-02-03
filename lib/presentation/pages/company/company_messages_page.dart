import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/message_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/messaging_panel.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/usecases/branch_usecases.dart';
import '../../../data/repositories/branch_repository_impl.dart';

class CompanyMessagesPage extends StatefulWidget {
  const CompanyMessagesPage({super.key});

  @override
  State<CompanyMessagesPage> createState() => _CompanyMessagesPageState();
}

class _CompanyMessagesPageState extends State<CompanyMessagesPage> {
  final BranchUseCases _branchUseCases = BranchUseCases(BranchRepositoryImpl());
  final TextEditingController _searchController = TextEditingController();
  
  String? _selectedBranchId;
  String _searchQuery = '';
  bool _isLoadingBranches = true;

  @override
  void initState() {
    super.initState();
    _loadCompanyBranches();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  Future<void> _loadCompanyBranches() async {
    try {
      setState(() {
        _isLoadingBranches = true;
      });

      final branches = await _branchUseCases.getBranches();

      setState(() {
        // TEMPORARILY: Auto-select the first branch since there's only one branch now
        if (branches.isNotEmpty && _selectedBranchId == null) {
          _selectedBranchId = branches.first.id.toString();
        }
        _isLoadingBranches = false;
      });

      // Auto-refresh başlat (şube seçildikten sonra)
      if (branches.isNotEmpty && _selectedBranchId != null) {
        // Mesajları otomatik yükle
        context.read<MessageProvider>().loadMessagesList(
              companyId: _selectedBranchId,
            );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<MessageProvider>().startAutoRefresh();
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingBranches = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      body: _isLoadingBranches
          ? _buildBranchesLoadingState()
          : // TEMPORARILY: Skip branch selection, auto-select first branch
          _selectedBranchId == null
              ? _buildBranchesLoadingState() // Show loading while selecting branch
              : Consumer<MessageProvider>(
                  builder: (context, messageProvider, child) {
                    if (messageProvider.isLoading &&
                        messageProvider.conversations.isEmpty) {
                      return _buildLoadingState();
                    }

                    if (messageProvider.error != null) {
                      return _buildErrorState(messageProvider);
                    }

                    if (messageProvider.conversations.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Column(
                      children: [
                        _buildSearchBar(),
                        Expanded(
                          child: _buildConversationsList(messageProvider),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Text(
        AppLocalizations.of(context)!.customerMessages,
        style: AppTypography.h4.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      // TEMPORARILY COMMENTED OUT - Branch selector in app bar (only one branch now, auto-selected)
      // actions: [
      //   if (_selectedBranchId != null) _buildBranchSelector(),
      // ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.search,
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),
    );
  }

  // TEMPORARILY COMMENTED OUT - Branch selector dropdown (only one branch now, auto-selected)
  // Widget _buildBranchSelector() {
  //   return Container(
  //     margin: const EdgeInsets.only(right: AppSpacing.sm),
  //     child: DropdownButton<String>(
  //       value: _selectedBranchId,
  //       hint: Text(
  //         AppLocalizations.of(context)!.selectBranch,
  //         style: AppTypography.body2.copyWith(
  //           color: AppColors.textSecondary,
  //         ),
  //       ),
  //       items: _companyBranches.map((branch) {
  //         return DropdownMenuItem<String>(
  //           value: branch.id.toString(),
  //           child: Text(
  //             branch.name,
  //             style: AppTypography.body2.copyWith(
  //               color: AppColors.textPrimary,
  //             ),
  //           ),
  //         );
  //       }).toList(),
  //       onChanged: (value) {
  //         setState(() {
  //           _selectedBranchId = value;
  //         });
  //         // Mesajları yeniden yükle
  //         context.read<MessageProvider>().loadMessagesList(
  //               companyId: value,
  //             );
  //       },
  //       underline: Container(),
  //       icon: Icon(
  //         Icons.arrow_drop_down,
  //         color: AppColors.textSecondary,
  //       ),
  //     ),
  //   );
  // }

  Widget _buildBranchesLoadingState() {
    // TEMPORARILY: Hide "Branches loading" text, only show loading indicator
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // TEMPORARILY COMMENTED OUT - Branch selection state (only one branch now, auto-selected)
  // Widget _buildBranchSelectionState() {
  //   return SingleChildScrollView(
  //     child: Padding(
  //       padding: EdgeInsets.all(AppSpacing.xl),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Container(
  //             padding: EdgeInsets.all(AppSpacing.lg),
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 colors: [
  //                   AppColors.primary.withValues(alpha: 0.1),
  //                   AppColors.primaryLight.withValues(alpha: 0.05),
  //                 ],
  //               ),
  //               borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
  //             ),
  //             child: Icon(
  //               Icons.business,
  //               size: 48,
  //               color: AppColors.primary.withValues(alpha: 0.6),
  //             ),
  //           ),
  //           SizedBox(height: AppSpacing.lg),
  //           Text(
  //             AppLocalizations.of(context)!.selectBranch,
  //             style: AppTypography.h5.copyWith(
  //               color: AppColors.textPrimary,
  //               fontWeight: FontWeight.w600,
  //             ),
  //           ),
  //           SizedBox(height: AppSpacing.sm),
  //           Text(
  //             AppLocalizations.of(context)!.selectBranchToViewMessages,
  //             style: AppTypography.body2.copyWith(
  //               color: AppColors.textSecondary,
  //             ),
  //             textAlign: TextAlign.center,
  //           ),
  //           SizedBox(height: AppSpacing.xl),
  //           if (_companyBranches.isNotEmpty)
  //             Column(
  //               children: _companyBranches.map((branch) {
  //                 return Container(
  //                   width: double.infinity,
  //                   margin: EdgeInsets.only(bottom: AppSpacing.sm),
  //                   child: ElevatedButton(
  //                     onPressed: () {
  //                       setState(() {
  //                         _selectedBranchId = branch.id.toString();
  //                       });
  //                       // Mesajları yükle
  //                       context.read<MessageProvider>().loadMessagesList(
  //                             companyId: branch.id.toString(),
  //                           );
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: AppColors.surface,
  //                       foregroundColor: AppColors.textPrimary,
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: AppSpacing.lg,
  //                         vertical: AppSpacing.md,
  //                       ),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius:
  //                             BorderRadius.circular(AppSpacing.radiusLg),
  //                         side: BorderSide(color: AppColors.border),
  //                       ),
  //                     ),
  //                     child: Row(
  //                       children: [
  //                         Icon(
  //                           Icons.business,
  //                           color: AppColors.primary,
  //                           size: 20,
  //                         ),
  //                         SizedBox(width: AppSpacing.sm),
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(
  //                                 branch.name,
  //                                 style: AppTypography.bodyLarge.copyWith(
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),
  //                               if (branch.address.isNotEmpty)
  //                                 Text(
  //                                   branch.address,
  //                                   style: AppTypography.caption.copyWith(
  //                                     color: AppColors.textSecondary,
  //                                   ),
  //                                   maxLines: 1,
  //                                   overflow: TextOverflow.ellipsis,
  //                                 ),
  //                             ],
  //                           ),
  //                         ),
  //                         Icon(
  //                           Icons.arrow_forward_ios,
  //                           size: 16,
  //                           color: AppColors.textTertiary,
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //               }).toList(),
  //             )
  //           else
  //             Text(
  //               AppLocalizations.of(context)!.noBranchesFoundYet,
  //               style: AppTypography.body2.copyWith(
  //                 color: AppColors.textSecondary,
  //               ),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
              AppLocalizations.of(context)!.anErrorOccurred,
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              messageProvider.error?.contains(
                              'Mesajı göndereceğiniz kullanıcıyı seçiniz') ==
                          true ||
                      messageProvider.error?.contains('Şube seçiniz') == true
                  ? AppLocalizations.of(context)!.noMessagesYetForBranch
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
              AppLocalizations.of(context)!.customerMessagesWillAppearHere,
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
    final filteredConversations = messageProvider.conversations.where((conversation) {
      final name = conversation.customerName?.toLowerCase() ?? '';
      final message = conversation.lastMessage?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || message.contains(query);
    }).toList();

    if (filteredConversations.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noResults,
          style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: messageProvider.loadMessagesList,
      color: AppColors.primary,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: filteredConversations.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: AppColors.border.withValues(alpha: 0.5),
          indent: 82, // Align with text start
        ),
        itemBuilder: (context, index) {
          final conversation = filteredConversations[index];
          return _buildConversationItem(conversation);
        },
      ),
    );
  }

  Widget _buildConversationItem(dynamic conversation) {
    final hasImage = conversation.customerImage != null && conversation.customerImage!.isNotEmpty;
    final initials = (conversation.customerName != null && conversation.customerName!.isNotEmpty)
        ? conversation.customerName!.trim().split(' ').take(2).map((e) => e[0].toUpperCase()).join()
        : '?';

    return Material(
      color: AppColors.surface, // Clean white background
      child: InkWell(
        onTap: () => _openConversation(conversation),
        onLongPress: () => _confirmDeleteConversation(conversation),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md, // More vertical padding
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasImage ? null : AppColors.primary.withValues(alpha: 0.1),
                ),
                child: hasImage
                    ? ClipOval( // Circular image
                        child: Image.network(
                          conversation.customerImage!.startsWith('http')
                              ? conversation.customerImage!
                              : '${ApiConstants.fileUrl}${conversation.customerImage!}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                                child: Text(initials,
                                    style: AppTypography.h6.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold)));
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: AppTypography.h6.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Name and Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            conversation.customerName ?? AppLocalizations.of(context)!.unknown,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600, // Semi-bold
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatTime(conversation.lastMessageTime),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2), // Small gap

                    // Bottom Row: Message Preview and Unread Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage ?? AppLocalizations.of(context)!.noMessagesYet,
                            style: AppTypography.bodyMedium.copyWith(
                              color: conversation.unreadCount > 0 
                                  ? AppColors.textPrimary // Darker if unread
                                  : AppColors.textSecondary.withValues(alpha: 0.8), // Lighter gray
                              fontWeight: conversation.unreadCount > 0 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2, // Truncate to 2 lines
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: EdgeInsets.only(left: AppSpacing.sm),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              conversation.unreadCount.toString(),
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
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
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      color: Colors.white,
      size: 24,
    );
  }

  void _openConversation(dynamic conversation) {
    // Conversation ID'yi doğru şekilde al (originalId varsa onu kullan, yoksa id'yi string'e çevir)
    final conversationId = conversation.originalId ?? conversation.id.toString();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MessagingPanel(
        receiverName: conversation.customerName ?? AppLocalizations.of(context)!.customer,
        receiverImage: conversation.customerImage != null
            ? (conversation.customerImage!.startsWith('http')
                ? conversation.customerImage!
                : '${ApiConstants.fileUrl}${conversation.customerImage!}')
            : '',
        receiverId: conversationId, // Conversation ID - UUID formatında
        companyId:
            conversation.companyId.toString(), // Company ID - API için gerekli
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      // Bugün: Saat (14:30)
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      // Dün
      return AppLocalizations.of(context)!.yesterday;
    } else {
      // Daha eski: Tarih (26/12)
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
    }
  }

  void _confirmDeleteConversation(dynamic conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteChat,
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteCustomerChatConfirm(conversation.customerName ?? AppLocalizations.of(context)!.customer),
          style: AppTypography.body1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation(conversation);
            },
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
