import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../data/models/branch_model.dart';
import '../providers/favorite_provider.dart';

class BarberCard extends StatelessWidget {
  final BranchModel barber;
  final double? distance;
  final VoidCallback? onTap;
  final VoidCallback? onBookAppointment;
  final VoidCallback? onViewDetails;
  final bool showDistance;
  final bool showFavorite;

  const BarberCard({
    super.key,
    required this.barber,
    this.distance,
    this.onTap,
    this.onBookAppointment,
    this.onViewDetails,
    this.showDistance = true,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 300,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Favorite Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: barber.image != null
                      ? Image.network(
                          barber.image!,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(context);
                          },
                        )
                      : _buildPlaceholderImage(context),
                ),
                // Favorite Button
                if (showFavorite)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Consumer<FavoriteProvider>(
                      builder: (context, favoriteProvider, child) {
                        final isFavorite =
                            favoriteProvider.isFavorite(barber.id);
                        return GestureDetector(
                          onTap: () async {
                            try {
                              await favoriteProvider.toggleFavorite(barber.id);
                            } catch (e) {
                              // Handle error silently
                            }
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadow.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: isFavorite
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Name
            Text(
              barber.name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),

            // Address
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    barber.address,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Bottom row: Distance, Rating, Status
            Row(
              children: [
                if (showDistance && distance != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me, size: 9, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          '${distance!.toStringAsFixed(1)} km',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Consumer<FavoriteProvider>(
                  builder: (context, favoriteProvider, child) {
                    // Use rating from provider if available (for favorites), otherwise use barber.averageRating
                    final rating = favoriteProvider.getCompanyRating(barber.id);
                    final displayRating = rating > 0 ? rating : (barber.averageRating ?? 0.0);
                    
                    return GestureDetector(
                      onTap: () {
                        // Navigate to barber detail page
                        if (onTap != null) {
                          onTap!();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 9, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              displayRating.toStringAsFixed(1),
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                _buildStatusBadge(context),
              ],
            ),

            // Action Buttons
            if (onBookAppointment != null || onViewDetails != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (onBookAppointment != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onBookAppointment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          textStyle: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.appointmentButton),
                      ),
                    ),
                  if (onBookAppointment != null && onViewDetails != null)
                    const SizedBox(width: 8),
                  if (onViewDetails != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetails,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          textStyle: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(AppLocalizations.of(context)!.detailsButton),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 28, color: AppColors.textTertiary),
          const SizedBox(height: 3),
          Text(
            AppLocalizations.of(context)!.noImage,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final isOpen = _isOpenNow();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            isOpen ? AppLocalizations.of(context)!.open : AppLocalizations.of(context)!.closed,
            style: AppTypography.bodySmall.copyWith(
              color: isOpen ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  bool _isOpenNow() {
    if (barber.workingHours.isEmpty) return false;

    if (barber.workingHours.containsKey('all') &&
        barber.workingHours['all'] == '7/24 Açık') {
      return true;
    }

    final now = DateTime.now();
    final dayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    final todayName = dayNames[now.weekday - 1];
    final todayHours = barber.workingHours[todayName];

    if (todayHours == null || todayHours.toLowerCase() == 'kapalı') {
      return false;
    }

    // "09:00 - 18:00" veya "09:00:00 - 18:00:00" formatını destekle
    final parts = todayHours.split(' - ');
    if (parts.length != 2) return false;

    try {
      // Zaman formatını normalize et: "09:00:00" -> "09:00"
      final openTimeStr = _normalizeTimeString(parts[0].trim());
      final closeTimeStr = _normalizeTimeString(parts[1].trim());

      final openParts = openTimeStr.split(':');
      final closeParts = closeTimeStr.split(':');

      if (openParts.length < 2 || closeParts.length < 2) return false;

      final openTime = TimeOfDay(
        hour: int.parse(openParts[0]),
        minute: int.parse(openParts[1]),
      );
      final closeTime = TimeOfDay(
        hour: int.parse(closeParts[0]),
        minute: int.parse(closeParts[1]),
      );

      final nowMinutes = now.hour * 60 + now.minute;
      final openMinutes = openTime.hour * 60 + openTime.minute;
      final closeMinutes = closeTime.hour * 60 + closeTime.minute;

      return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
    } catch (e) {
      return false;
    }
  }

  /// Zaman formatını normalize et: "09:00:00" -> "09:00"
  String _normalizeTimeString(String time) {
    if (time.isEmpty) return '09:00';
    
    // "09:00:00" veya "09:00" formatını destekle
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');
      return '$hour:$minute';
    }
    
    return time;
  }
}
