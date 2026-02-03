import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class CategoryItem extends StatelessWidget {
  final String id;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;
  final String? iconName;
  final String? imageUrl; // Backend'den gelen görsel

  const CategoryItem({
    super.key,
    required this.id,
    required this.name,
    required this.isSelected,
    required this.onTap,
    this.iconName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dairesel görsel/ikon alanı
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2.0 : 1.5,
                ),
                gradient: imageUrl != null && imageUrl!.isNotEmpty
                    ? null
                    : _getGradientForCategory(id),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            _getIconForCategory(id),
                            color: Colors.white,
                            size: AppSpacing.iconSm,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        _getIconForCategory(id),
                        color: Colors.white,
                        size: AppSpacing.iconSm,
                      ),
                    ),
            ),
            const SizedBox(height: 3),
            // Kategori adı
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected 
                    ? AppColors.primary 
                    : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate gradient colors based on category ID
  LinearGradient _getGradientForCategory(String categoryId) {
    // Use category ID to generate consistent colors
    final colors = [
      [AppColors.primary, AppColors.accent],
      [Colors.orange, Colors.deepOrange],
      [Colors.purple, Colors.deepPurple],
      [Colors.green, Colors.teal],
      [Colors.blue, Colors.indigo],
      [Colors.pink, Colors.red],
      [Colors.amber, Colors.orange],
      [Colors.cyan, Colors.blue],
    ];

    final index = categoryId.hashCode.abs() % colors.length;
    final colorPair = colors[index];

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colorPair,
    );
  }

  // Get icon based on category name or ID
  IconData _getIconForCategory(String categoryId) {
    final categoryName = name.toLowerCase();

    if (categoryName.contains('berber') || categoryName.contains('barber')) {
      return Icons.content_cut;
    } else if (categoryName.contains('kuaför') ||
        categoryName.contains('hairdresser')) {
      return Icons.face;
    } else if (categoryName.contains('güzellik') ||
        categoryName.contains('beauty')) {
      return Icons.face_retouching_natural;
    } else if (categoryName.contains('pet') ||
        categoryName.contains('hayvan')) {
      return Icons.pets;
    } else if (categoryName.contains('spa') || categoryName.contains('masaj')) {
      return Icons.spa;
    } else if (categoryName.contains('unisex')) {
      return Icons.accessibility;
    } else {
      // Default icon
      return Icons.business;
    }
  }
}

