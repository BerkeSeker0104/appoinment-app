import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/product.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onRemove;

  const CartItemWidget({
    super.key,
    required this.item,
    this.onIncrease,
    this.onDecrease,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image (uses optional 'mainImage' pattern if available from name or ID mapping in backend; fallback to icon)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              color: AppColors.backgroundSecondary,
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _CartItemThumbnail(productId: item.productId),
          ),
          const SizedBox(width: AppSpacing.md),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '₺${item.productPrice.toStringAsFixed(2)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // per-item toplam kaldırıldı; genel toplam alt barda gösteriliyor
              ],
            ),
          ),

          // Quantity Controls and Remove
          Column(
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrease Button
                    GestureDetector(
                      onTap: onDecrease,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppSpacing.radiusSm),
                            bottomLeft: Radius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: AppSpacing.iconSm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // Quantity
                    Container(
                      width: 40,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                      ),
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Increase Button
                    GestureDetector(
                      onTap: onIncrease,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(AppSpacing.radiusSm),
                            bottomRight: Radius.circular(AppSpacing.radiusSm),
                          ),
                        ),
                        child: Icon(
                          Icons.add,
                          size: AppSpacing.iconSm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Remove Button
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.delete_forever,
                    size: AppSpacing.iconMd,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartItemThumbnail extends StatelessWidget {
  final String productId; // UUID string
  const _CartItemThumbnail({required this.productId});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final product = productProvider.products.firstWhere(
      (p) => p.id == productId, // UUID string karşılaştırması
      orElse: () => Product(
        id: '',
        userId: '',
        categoryId: '',
        name: '',
        description: '',
        price: 0,
        pictures: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyName: '',
      ),
    );

    final imageUrl = product.mainImage;
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textTertiary,
          size: AppSpacing.iconLg,
        ),
      );
    }

    return Icon(
      Icons.shopping_bag_outlined,
      color: AppColors.textTertiary,
      size: AppSpacing.iconLg,
    );
  }
}
