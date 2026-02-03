import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../pages/auth/phone_login_page.dart';
import '../pages/auth/sign_up_page.dart';
import 'premium_button.dart';

/// Overlay widget that shows login/signup buttons when user is a guest
class GuestAuthOverlay extends StatelessWidget {
  final Widget child;

  const GuestAuthOverlay({
    super.key,
    required this.child,
  });

  Widget _buildAuthCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            AppLocalizations.of(context)!.pleaseSignInOrSignUp,
            style: AppTypography.h5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.pleaseSignInOrSignUpMessage,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PremiumButton(
            text: AppLocalizations.of(context)!.signIn,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PhoneLoginPage(),
                ),
              );
            },
            variant: ButtonVariant.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumButton(
            text: AppLocalizations.of(context)!.signUp,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignUpPage(),
                ),
              );
            },
            variant: ButtonVariant.secondary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiClient().getToken(),
      builder: (context, snapshot) {
        final isGuest = snapshot.data == null;

        if (!isGuest) {
          return child;
        }

        // For guest users, replace child with auth card as part of page scroll
        // The auth card will be part of the page's SingleChildScrollView
        return _buildAuthCard(context);
      },
    );
  }
}

