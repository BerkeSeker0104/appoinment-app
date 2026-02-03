import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/order_address_model.dart';
import '../../../data/services/order_api_service.dart';
import '../../../domain/entities/order.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/order_status_badge.dart';

class CompanyOrderDetailPage extends StatefulWidget {
  final String orderId;

  const CompanyOrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  State<CompanyOrderDetailPage> createState() => _CompanyOrderDetailPageState();
}

class _CompanyOrderDetailPageState extends State<CompanyOrderDetailPage> {
  final OrderApiService _orderService = OrderApiService();
  OrderModel? _order;
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final order = await _orderService.getOrder(widget.orderId);

      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _updateOrderStatus(OrderStatus newStatus) async {
    if (_order == null || _isUpdatingStatus) return;

    try {
      setState(() {
        _isUpdatingStatus = true;
      });

      final updatedOrder = await _orderService.updateOrderStatus(
        id: _order!.id,
        status: newStatus,
      );

      if (!mounted) return;
      setState(() {
        _order = updatedOrder;
        _isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş durumu güncellendi'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellenemedi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<OrderStatus> _getAvailableStatuses(OrderStatus currentStatus) {
    // Yeni status sistemi: 0 = Ödenmedi, 1 = Alındı, 2 = Teslim edildi
    switch (currentStatus) {
      case OrderStatus.pending: // 0: Sipariş Ödenmedi
        return [OrderStatus.confirmed]; // 1: Sipariş Alındı'ya geçebilir
      case OrderStatus.confirmed: // 1: Sipariş Alındı
        return [OrderStatus.completed]; // 2: Sipariş Teslim edildi'ye geçebilir
      case OrderStatus.completed: // 2: Sipariş Teslim edildi
        return []; // No status changes allowed
      case OrderStatus.cancelled:
        return []; // No status changes allowed
      default:
        // preparing, readyForPickup gibi eski status'lar için
        if (currentStatus == OrderStatus.preparing ||
            currentStatus == OrderStatus.readyForPickup) {
          return [OrderStatus.completed];
        }
        return [];
    }
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Beklemede';
      case OrderStatus.confirmed:
        return 'Onaylandı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.readyForPickup:
        return 'Teslimata Hazır';
      case OrderStatus.completed:
        return 'Tamamlandı';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.orderSummary,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadOrder,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : _order == null
                    ? _buildEmptyState()
                    : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Hata',
              style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage ?? 'Sipariş yüklenemedi',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _loadOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'Tekrar Dene',
                style: AppTypography.buttonMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sipariş bulunamadı',
            style: AppTypography.h5.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final order = _order!;
    final availableStatuses = _getAvailableStatuses(order.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(order, availableStatuses),
          const SizedBox(height: AppSpacing.xl),
          _buildOrderInfo(order),
          const SizedBox(height: AppSpacing.xl),
          _buildItemsInfo(order),
          const SizedBox(height: AppSpacing.xl),
          _buildDeliveryInfo(order),
          const SizedBox(height: AppSpacing.xl),
          _buildPaymentInfo(order),
          if (order.invoiceAddress != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildInvoiceAddressSection(order),
          ],
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildNotesSection(order),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      OrderModel order, List<OrderStatus> availableStatuses) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sipariş Durumu',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    OrderStatusBadge(status: order.status),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sipariş No',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '#${order.orderNumber}',
                    style: AppTypography.h6.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (availableStatuses.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Durum Güncelle',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: availableStatuses.map((status) {
                return ElevatedButton(
                  onPressed: _isUpdatingStatus
                      ? null
                      : () => _updateOrderStatus(status),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_isUpdatingStatus) ...[
              const SizedBox(height: AppSpacing.md),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildOrderInfo(OrderModel order) {
    return _buildInfoCard(
      title: 'Sipariş Bilgileri',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _buildInfoRow('Sipariş Tarihi', _formatDate(order.createdAt)),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Güncelleme Tarihi', _formatDate(order.updatedAt)),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow('Toplam Ürün', '${order.itemCount} adet'),
        ],
      ),
    );
  }

  Widget _buildItemsInfo(OrderModel order) {
    return _buildInfoCard(
      title: 'Sipariş Ürünleri',
      icon: Icons.shopping_bag_outlined,
      child: Column(
        children: order.items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image placeholder or icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: item.productImage != null
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          child: Image.network(
                            item.productImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.primary),
                          ),
                        )
                      : Icon(Icons.shopping_bag_outlined,
                          color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Adet: ${item.quantity}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₺${_formatPrice(item.price)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '₺${_formatPrice(item.subtotal)}',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeliveryInfo(OrderModel order) {
    return _buildInfoCard(
      title: 'Teslimat Bilgileri',
      icon: Icons.local_shipping_outlined,
      child: Column(
        children: [
          // Teslimat adresi bilgileri - deliveryAddressModel varsa göster
          if (order.deliveryAddressModel != null) ...[
            _buildAddressSection('Teslimat Adresi', order.deliveryAddressModel!),
          ] else if (order.deliveryAddress != null) ...[
            // Eski format string adres desteği
            _buildInfoRow('Teslimat Adresi', order.deliveryAddress!),
          ] else ...[
            Text(
              'Teslimat adresi bilgisi bulunamadı',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection(String title, OrderAddressModel address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.fullName,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                address.address,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${address.city.name}, ${address.city.country.name}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                address.fullPhone,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(OrderModel order) {
    return _buildInfoCard(
      title: 'Ödeme Bilgileri',
      icon: Icons.payment_outlined,
      child: Column(
        children: [
          _buildInfoRow('Ödeme Durumu', order.paymentStatusText),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam Tutar',
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₺${_formatPrice(order.totalAmount)}',
                style: AppTypography.h5.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (order.commissionPrice != null && order.commissionPrice! > 0) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Komisyon',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₺${_formatPrice(order.commissionPrice!)}',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Kazanç',
                  style: AppTypography.h6.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '₺${_formatPrice(order.totalAmount - order.commissionPrice!)}',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceAddressSection(OrderModel order) {
    return _buildInfoCard(
      title: 'Fatura Adresi',
      icon: Icons.receipt_long_outlined,
      child: _buildAddressSection('Fatura Adresi', order.invoiceAddress!),
    );
  }

  Widget _buildNotesSection(OrderModel order) {
    return _buildInfoCard(
      title: 'Notlar',
      icon: Icons.note_outlined,
      child: Text(
        order.notes!,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border, width: 1),
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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


















