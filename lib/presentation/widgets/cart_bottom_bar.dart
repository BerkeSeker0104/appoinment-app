import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import 'premium_button.dart';

class CartBottomBar extends StatelessWidget {
  final double totalAmount;
  final VoidCallback? onCheckout;
  final bool isLoading;

  const CartBottomBar({
    super.key,
    required this.totalAmount,
    this.onCheckout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Toplam Tutar',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₺${totalAmount.toStringAsFixed(2)}',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: PremiumButton(
                text: 'Sepeti Onayla',
                onPressed: isLoading ? null : onCheckout,
                variant: ButtonVariant.primary,
                isLoading: isLoading,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

























