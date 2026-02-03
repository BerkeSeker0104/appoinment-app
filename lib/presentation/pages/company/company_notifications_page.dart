import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/notification.dart' as entity;
import '../../../domain/entities/notification.dart' show NotificationType;
import '../../providers/notification_provider.dart';
import '../../../l10n/app_localizations.dart';

class CompanyNotificationsPage extends StatefulWidget {
  const CompanyNotificationsPage({super.key});

  @override
  State<CompanyNotificationsPage> createState() =>
      _CompanyNotificationsPageState();
}

class _CompanyNotificationsPageState extends State<CompanyNotificationsPage> {
  NotificationProvider? _notificationProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save provider reference when dependencies are available
    _notificationProvider ??= context.read<NotificationProvider>();
  }

  @override
  void initState() {
    super.initState();
    // Start auto-refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationProvider?.startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // Stop auto-refresh when leaving page
    // Use saved reference instead of context.read() to avoid dispose error
    _notificationProvider?.stopAutoRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.notifications,
          style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadNotifications.isNotEmpty) {
                return Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await provider.markAllAsRead();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.allNotificationsMarkedRead,
                              style: AppTypography.body2.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.done_all,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      AppLocalizations.of(context)!.markAllAsRead,
                      style: AppTypography.body2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return _buildLoadingState();
          }

          if (provider.error != null && provider.notifications.isEmpty) {
            return _buildErrorState(provider);
          }

          if (provider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return _buildNotificationsList(provider);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)!.notificationsLoading,
            style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(NotificationProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.errorOccurred,
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              provider.error ?? AppLocalizations.of(context)!.notificationsLoadError,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => provider.loadNotifications(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.retry,
                style: AppTypography.body1.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildHeaderSection(),
          const SizedBox(height: AppSpacing.xl),
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal),
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.textTertiary,
                    size: 48,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppLocalizations.of(context)!.noNotificationsYet,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppLocalizations.of(context)!.notificationsEmptyDesc,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(NotificationProvider provider) {
    // Separate unread and read notifications
    final unreadNotifications = provider.unreadNotifications;
    final readNotifications = provider.readNotifications;

    // Combine: unread first, then read
    final sortedNotifications = [...unreadNotifications, ...readNotifications];

    // Calculate total items including headers
    int totalItems = sortedNotifications.length;
    if (unreadNotifications.isNotEmpty) totalItems += 1; // Unread header
    if (readNotifications.isNotEmpty && unreadNotifications.isNotEmpty)
      totalItems += 1; // Read header
    if (provider.hasMorePages) totalItems += 1; // Load more

    return RefreshIndicator(
      onRefresh: () => provider.loadNotifications(refresh: true),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          // Unread header
          if (unreadNotifications.isNotEmpty && index == 0) {
            return _buildSectionHeader(
                AppLocalizations.of(context)!.unreadNotifications, unreadNotifications.length);
          }

          // Adjust index for unread header
          int adjustedIndex =
              unreadNotifications.isNotEmpty ? index - 1 : index;

          // Read header
          if (readNotifications.isNotEmpty &&
              unreadNotifications.isNotEmpty &&
              adjustedIndex == unreadNotifications.length) {
            return _buildSectionHeader(
                AppLocalizations.of(context)!.readNotifications, readNotifications.length);
          }

          // Adjust index for read header
          if (readNotifications.isNotEmpty && unreadNotifications.isNotEmpty) {
            adjustedIndex = adjustedIndex > unreadNotifications.length
                ? adjustedIndex - 1
                : adjustedIndex;
          }

          // Load more indicator
          if (adjustedIndex >= sortedNotifications.length) {
            if (provider.hasMorePages) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.loadMoreNotifications();
              });
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final notification = sortedNotifications[adjustedIndex];
          return _buildNotificationCard(notification, provider);
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      margin: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              '$count',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
      entity.Notification notification, NotificationProvider provider) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);
    final isUnread = !notification.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
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
            if (isUnread) {
              provider.markAsRead(notification.id);
            }
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with unread indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isUnread
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : color.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        icon,
                        color: isUnread ? AppColors.primary : color,
                        size: 24,
                      ),
                    ),
                    if (isUnread)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 2,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTypography.body1.copyWith(
                                color: isUnread
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: isUnread ? 15 : 14,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Text(
                                  AppLocalizations.of(context)!.newLabel,
                                style: AppTypography.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.readLabel,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        notification.message,
                        style: AppTypography.body2.copyWith(
                          color: isUnread
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontWeight:
                              isUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatDate(notification.createdAt),
                        style: AppTypography.bodySmall.copyWith(
                          color: isUnread
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        return Container(
          margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppLocalizations.of(context)!.notifications,
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (provider.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.unreadNotificationCount(provider.unreadCount),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Text(
                  AppLocalizations.of(context)!.notificationsSubtitle,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return Icons.calendar_today;
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.promotion:
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return AppColors.primary;
      case NotificationType.order:
        return AppColors.success;
      case NotificationType.message:
        return AppColors.info;
      case NotificationType.system:
        return AppColors.warning;
      case NotificationType.promotion:
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return AppLocalizations.of(context)!.justNow;
        }
        return AppLocalizations.of(context)!.minutesAgo(difference.inMinutes);
      }
      return AppLocalizations.of(context)!.hoursAgo(difference.inHours);
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
