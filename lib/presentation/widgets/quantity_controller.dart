import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class QuantityController extends StatelessWidget {
  final int quantity;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final bool isEnabled;

  const QuantityController({
    super.key,
    required this.quantity,
    this.onIncrease,
    this.onDecrease,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        color: AppColors.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove,
            onTap: isEnabled ? onDecrease : null,
            isLeft: true,
          ),
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Center(
              child: Text(
                '$quantity',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onTap: isEnabled ? onIncrease : null,
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isLeft = false,
  }) {
    final isDisabled = onTap == null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.backgroundSecondary
              : AppColors.surface,
          borderRadius: isLeft
              ? const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusLg),
                  bottomLeft: Radius.circular(AppSpacing.radiusLg),
                )
              : const BorderRadius.only(
                  topRight: Radius.circular(AppSpacing.radiusLg),
                  bottomRight: Radius.circular(AppSpacing.radiusLg),
                ),
        ),
        child: Icon(
          icon,
          size: AppSpacing.iconSm,
          color: isDisabled
              ? AppColors.textTertiary
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}

