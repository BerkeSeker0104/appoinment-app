import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

enum BookingStatus { upcoming, completed, cancelled }

class BookingCard extends StatelessWidget {
  final String salonName;
  final String service;
  final String date;
  final String time;
  final String price;
  final BookingStatus status;
  final VoidCallback? onCancel;
  final VoidCallback? onReschedule;
  final VoidCallback? onReview;
  final VoidCallback? onTap;

  const BookingCard({
    super.key,
    required this.salonName,
    required this.service,
    required this.date,
    required this.time,
    required this.price,
    required this.status,
    this.onCancel,
    this.onReschedule,
    this.onReview,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      salonName,
                      style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // Service
              Text(
                service,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              
              const SizedBox(height: AppSpacing.lg),
              
              // Date, Time, and Price
              Row(
                children: [
                  // Date & Time
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: AppSpacing.iconSm,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              time,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Price
                  Text(
                    price,
                    style: AppTypography.monoMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              
              // Action buttons based on status
              if (_shouldShowActions()) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case BookingStatus.upcoming:
        backgroundColor = AppColors.accent.withValues(alpha: 0.1);
        textColor = AppColors.accent;
        text = 'Upcoming';
        break;
      case BookingStatus.completed:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        text = 'Completed';
        break;
      case BookingStatus.cancelled:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _shouldShowActions() {
    return status == BookingStatus.upcoming || status == BookingStatus.completed;
  }

  Widget _buildActionButtons() {
    if (status == BookingStatus.upcoming) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                foregroundColor: AppColors.error,
              ),
              child: Text(
                'Cancel',
                style: AppTypography.buttonSmall.copyWith(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton(
              onPressed: onReschedule,
              child: Text(
                'Reschedule',
                style: AppTypography.buttonSmall.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    } else if (status == BookingStatus.completed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onReview,
          child: Text(
            'Leave Review',
            style: AppTypography.buttonSmall.copyWith(color: AppColors.primary),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}












