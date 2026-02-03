import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/order_model.dart';
import '../../domain/entities/order.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final productImage = firstItem?.productImage;
    final productName = firstItem?.productName ?? 'Ürün';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Status badge at top-right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                // Main content: Horizontal row layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product thumbnail (60x60px rounded rectangle)
                    _buildProductThumbnail(productImage),
                    const SizedBox(width: 12),
                    // Product info and price section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name (Main title)
                          Text(
                            productName,
                            style: AppTypography.h6.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Order ID and Date (Sub-info)
                          Text(
                            '#${order.orderNumber} • ${_formatShortDate(order.createdAt)}',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Price
                          Text(
                            '₺${_formatPrice(order.totalAmount)}',
                            style: AppTypography.h6.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(String? imageUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.backgroundSecondary,
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.backgroundSecondary,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildPlaceholderIcon(),
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: AppColors.backgroundSecondary,
      child: Icon(
        Icons.image_outlined,
        size: 24,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isConfirmed = order.status == OrderStatus.confirmed;
    final isUnpaid = order.status == OrderStatus.pending;

    Color badgeColor;
    Color textColor;
    String statusText;

    if (isConfirmed) {
      // Green/Teal for "Sipariş Alındı"
      badgeColor = AppColors.successLight;
      textColor = AppColors.success;
      statusText = 'Sipariş Alındı';
    } else if (isUnpaid) {
      // Orange/Amber for "Sipariş Ödenmedi"
      badgeColor = AppColors.warningLight;
      textColor = AppColors.warning;
      statusText = 'Sipariş Ödenmedi';
    } else {
      // Default styling for other statuses
      badgeColor = AppColors.infoLight;
      textColor = AppColors.info;
      statusText = order.statusText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    final months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatPrice(double price) {
    if (price == 0.0) {
      return '0';
    }
    if (price == price.toInt().toDouble()) {
      return price.toInt().toString();
    } else {
      return price.toStringAsFixed(2);
    }
  }
}
















