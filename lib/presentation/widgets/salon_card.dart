import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../providers/favorite_provider.dart';

class SalonCard extends StatelessWidget {
  final String name;
  final String category;
  final double rating;
  final String distance;
  final String imageUrl;
  final bool isOpen;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final String? companyId; // NEW: to sync with provider

  const SalonCard({
    super.key,
    required this.name,
    required this.category,
    required this.rating,
    required this.distance,
    required this.imageUrl,
    this.isOpen = true,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.companyId, // NEW
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
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.radiusLg),
                      topRight: Radius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppSpacing.radiusLg),
                            topRight: Radius.circular(AppSpacing.radiusLg),
                          ),
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: AppColors.textTertiary,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                ),


                // Favorite Button
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: companyId != null
                      ? Consumer<FavoriteProvider>(
                          builder: (context, favoriteProvider, child) {
                            final isInFavorites =
                                favoriteProvider.isFavorite(companyId!);
                            return GestureDetector(
                              onTap: () async {
                                if (onFavoriteToggle != null) {
                                  onFavoriteToggle!();
                                } else {
                                  // Default behavior using provider
                                  try {
                                    await favoriteProvider
                                        .toggleFavorite(companyId!);
                                  } catch (e) {
                                    // Handle error silently or show a subtle notification
                                  }
                                }
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm,
                                  ),
                                ),
                                child: Icon(
                                  isInFavorites
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: AppSpacing.iconSm,
                                  color: isInFavorites
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        )
                      : GestureDetector(
                          onTap: onFavoriteToggle,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: AppSpacing.iconSm,
                              color: isFavorite
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Category
                  Text(
                    name,
                    style:
                        AppTypography.h6.copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    category,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Rating and Distance
                  Row(
                    children: [
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: AppSpacing.iconSm,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTypography.monoSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: AppSpacing.lg),

                      // Distance
                      if (distance.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: AppSpacing.iconSm,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              distance,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                      const Spacer(),

                      // Status Badge (sağ alt)
                      _buildStatusBadge(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
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
            isOpen
                ? AppLocalizations.of(context)!.open
                : AppLocalizations.of(context)!.closed,
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
}
