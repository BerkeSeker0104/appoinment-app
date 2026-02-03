import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String description;
  final String icon;
  final VoidCallback onAllow;
  final VoidCallback onDeny;
  final bool isLocation;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onAllow,
    required this.onDeny,
    this.isLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isLocation
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isLocation
                    ? Icons.location_on_rounded
                    : Icons.notifications_rounded,
                size: 40,
                color: isLocation ? AppColors.primary : AppColors.success,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              title,
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            // Description
            Text(
              description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Buttons
            Row(
              children: [
                // Deny button
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDeny,
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Text(
                      'Daha Sonra',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Allow button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAllow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isLocation ? AppColors.primary : AppColors.success,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'İzin Ver',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show location permission dialog
  static Future<bool> showLocationPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(
        title: 'Konum İzni',
        description:
            'Yakınındaki berberleri göstermek ve haritada konumunuzu işaretlemek için konum bilginize ihtiyaç duyarız.',
        icon: 'location',
        isLocation: true,
        onAllow: () => Navigator.of(context).pop(true),
        onDeny: () => Navigator.of(context).pop(false),
      ),
    ).then((result) => result ?? false);
  }

  /// Show notification permission dialog
  static Future<bool> showNotificationPermissionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(
        title: 'Bildirim İzni',
        description:
            'Randevu hatırlatmaları ve özel kampanyalar hakkında bildirim alabilmek için bildirim iznine ihtiyacımız var.',
        icon: 'notification',
        isLocation: false,
        onAllow: () => Navigator.of(context).pop(true),
        onDeny: () => Navigator.of(context).pop(false),
      ),
    ).then((result) => result ?? false);
  }
}
