import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../domain/entities/order.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool isCompact;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  Color _getStatusColor() {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange; // Sipariş Ödenmedi
      case OrderStatus.confirmed:
        return Colors.blue; // Sipariş Alındı
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.readyForPickup:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.teal; // Sipariş Teslim edildi
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (status) {
      case OrderStatus.pending:
        return 'Sipariş Ödenmedi';
      case OrderStatus.confirmed:
        return 'Sipariş Alındı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.readyForPickup:
        return 'Teslime Hazır';
      case OrderStatus.completed:
        return 'Sipariş Teslim edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.inventory_2_outlined;
      case OrderStatus.readyForPickup:
        return Icons.shopping_bag_outlined;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.sm : AppSpacing.md,
        vertical: isCompact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: color,
            size: isCompact ? 14 : 16,
          ),
          SizedBox(width: isCompact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            _getStatusText(),
            style:
                (isCompact ? AppTypography.bodySmall : AppTypography.bodyMedium)
                    .copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
