import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/product.dart';
import '../providers/product_provider.dart';
import 'quantity_controller.dart';

class CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    this.onIncrease,
    this.onDecrease,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(context),
              const SizedBox(width: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.md),
                    QuantityController(
                      quantity: item.quantity,
                      onIncrease: onIncrease,
                      onDecrease: onDecrease,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _buildDeleteButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(BuildContext context) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        color: AppColors.backgroundSecondary,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: _CartItemThumbnail(productId: item.productId),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close,
          size: AppSpacing.iconSm,
          color: AppColors.error,
        ),
      ),
    );
  }
}

class _CartItemThumbnail extends StatelessWidget {
  final String productId;

  const _CartItemThumbnail({required this.productId});

  @override
  Widget build(BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final product = productProvider.products.firstWhere(
      (p) => p.id == productId,
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
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        memCacheWidth: 130,
        memCacheHeight: 130,
        placeholder: (context, url) => Container(
          color: AppColors.backgroundSecondary,
          child: Center(
            child: SizedBox(
              width: AppSpacing.iconMd,
              height: AppSpacing.iconMd,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.textTertiary),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Icon(
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
