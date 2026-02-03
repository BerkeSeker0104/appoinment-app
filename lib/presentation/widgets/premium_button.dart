import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

enum ButtonVariant { primary, secondary, ghost }

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == ButtonVariant.primary) {
      return Container(
        width: isFullWidth ? double.infinity : null,
        height: AppSpacing.buttonLarge,
        decoration: BoxDecoration(
          gradient: isLoading || onPressed == null 
              ? LinearGradient(colors: [AppColors.borderMedium, AppColors.borderMedium])
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: isLoading || onPressed == null ? null : [
            BoxShadow(
              color: AppColors.shadowColored,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            onTap: isLoading ? null : onPressed,
            child: Container(
              height: AppSpacing.buttonLarge,
              alignment: Alignment.center,
              child: isLoading
                  ? _buildLoadingIndicator()
                  : _buildButtonContent(),
            ),
          ),
        ),
      );
    }
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: AppSpacing.buttonLarge,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _getButtonStyle(),
        child: isLoading
            ? _buildLoadingIndicator()
            : _buildButtonContent(),
      ),
    );
  }

  ButtonStyle _getButtonStyle() {
    switch (variant) {
      case ButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textInverse,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          side: BorderSide.none,
          padding: EdgeInsets.zero,
        );
      case ButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          side: const BorderSide(color: AppColors.borderMedium, width: 1.5),
          splashFactory: InkRipple.splashFactory,
        );
      case ButtonVariant.ghost:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          side: BorderSide.none,
        );
    }
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          variant == ButtonVariant.primary ? Colors.white : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    final textColor = _getTextColor();
    final iconColor = _getIconColor();
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSpacing.iconSm, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text,
              style: AppTypography.buttonMedium.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }
    return Text(
      text,
      style: AppTypography.buttonMedium.copyWith(color: textColor),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
    );
  }

  Color _getTextColor() {
    if (onPressed == null || isLoading) {
      return variant == ButtonVariant.primary 
          ? AppColors.textSecondary 
          : AppColors.textTertiary;
    }
    
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return AppColors.textPrimary;
      case ButtonVariant.ghost:
        return AppColors.textPrimary;
    }
  }

  Color _getIconColor() {
    if (onPressed == null || isLoading) {
      return variant == ButtonVariant.primary 
          ? AppColors.textSecondary 
          : AppColors.textTertiary;
    }
    
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return AppColors.textPrimary;
      case ButtonVariant.ghost:
        return AppColors.textPrimary;
    }
  }
}
