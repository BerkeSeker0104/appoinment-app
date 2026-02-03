import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/order_address_model.dart';
import '../../../data/services/order_api_service.dart';
import '../../../domain/entities/order.dart';
import '../../widgets/premium_button.dart';
import 'customer_main_page.dart';

class OrderSuccessPage extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final String? paymentMethod;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.orderNumber,
    this.paymentMethod,
  });

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  final OrderApiService _orderApiService = OrderApiService();
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      // Gerçek API'den sipariş detayını çek
      final orderModel = await _orderApiService.getOrder(widget.orderId);

      // Convert OrderModel to Order entity
      final order = Order(
        id: orderModel.id,
        userId: orderModel.userId,
        orderNumber: orderModel.orderNumber,
        items: orderModel.items.map((item) {
          return OrderItem(
            id: item.id,
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            price: item.price,
            subtotal: item.subtotal,
            productImage: item.productImage,
          );
        }).toList(),
        totalAmount: orderModel.totalAmount,
        status: orderModel.status,
        paymentStatus: orderModel.paymentStatus,
        deliveryType: orderModel.deliveryType,
        pickupBranchId: orderModel.pickupBranchId,
        pickupBranchName: orderModel.pickupBranchName,
        deliveryAddress: orderModel.deliveryAddress,
        deliveryAddressModel: orderModel.deliveryAddressModel != null
            ? OrderDeliveryAddress(
                address: orderModel.deliveryAddressModel!.address,
                firstName: orderModel.deliveryAddressModel!.firstName,
                lastName: orderModel.deliveryAddressModel!.lastName,
                phoneCode: orderModel.deliveryAddressModel!.phoneCode,
                phone: orderModel.deliveryAddressModel!.phone,
                cityName: orderModel.deliveryAddressModel!.city.name,
                countryName: orderModel.deliveryAddressModel!.city.country.name,
              )
            : null,
        notes: orderModel.notes,
        paymentMethod: orderModel.paymentMethod,
        createdAt: orderModel.createdAt,
        updatedAt: orderModel.updatedAt,
      );

      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _order == null
                ? _buildErrorState()
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: AppSpacing.xxl),
                              _buildSuccessIcon(),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildSuccessMessage(),
                              const SizedBox(height: AppSpacing.xxl),
                              _buildOrderDetails(),
                              const SizedBox(height: AppSpacing.xxl),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomActions(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sipariş bilgileri yüklenemedi',
              style: AppTypography.h5,
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              text: 'Ana Sayfaya Dön',
              onPressed: () => _navigateToHome(),
              variant: ButtonVariant.primary,
              isFullWidth: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        children: [
          Text(
            'Siparişiniz Alındı',
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Siparişiniz başarıyla oluşturuldu. Sipariş numaranız:',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Text(
              widget.orderNumber,
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    if (_order == null) return const SizedBox.shrink();

    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sipariş Özeti',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Order Items
          ..._order!.items.map((item) => Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${item.quantity}x ₺${item.price.toStringAsFixed(2)}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₺${item.subtotal.toStringAsFixed(2)}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )),

          const Divider(height: AppSpacing.xl),

          // Delivery Info - Teslimat Adresi
          _buildDeliveryAddressSection(),
          const SizedBox(height: AppSpacing.lg),

          // Payment Method
          _buildDetailRow(
            icon: Icons.payment,
            label: 'Ödeme Yöntemi',
            value: _getPaymentMethodText(),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₺${_order!.totalAmount.toStringAsFixed(2)}',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodText() {
    // 1. Constructor'dan gelen ödeme yöntemini kullan (öncelikli)
    if (widget.paymentMethod != null) {
      return _formatPaymentMethod(widget.paymentMethod!);
    }

    // 2. Sipariş detayından gelen ödeme yöntemini kullan
    if (_order?.paymentMethod != null) {
      return _formatPaymentMethod(_order!.paymentMethod!);
    }

    // 3. Fallback: Ödeme durumuna göre tahmin et (Eski mantık)
    // Not: Bu kısım tam doğru olmayabilir çünkü ödenmiş olması kartla ödendiği anlamına gelmez
    // ama geriye dönük uyumluluk için bırakıldı.
    return _order!.paymentStatus == PaymentStatus.paid
        ? 'Kredi/Banka Kartı'
        : 'Nakit (Mağazada Ödenecek)';
  }

  String _formatPaymentMethod(String method) {
    final m = method.toLowerCase();
    if (m.contains('card') ||
        m.contains('kredi') ||
        m.contains('credit') ||
        m == 'online') {
      return 'Kredi/Banka Kartı';
    }
    if (m.contains('cash') || m.contains('nakit') || m.contains('hand')) {
      return 'Nakit (Mağazada Ödenecek)';
    }
    // Bilinmeyen bir yöntemse olduğu gibi veya varsayılan bir değer döndür
    return 'Kredi/Banka Kartı';
  }

  Widget _buildDeliveryAddressSection() {
    if (_order == null) return const SizedBox.shrink();

    // deliveryAddressModel varsa detaylı göster
    if (_order!.deliveryAddressModel != null) {
      final address = _order!.deliveryAddressModel!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping,
                  size: AppSpacing.iconMd, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Teslimat Adresi',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                  '${address.cityName}, ${address.countryName}',
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

    // Eski format string adres desteği
    return _buildDetailRow(
      icon: Icons.local_shipping,
      label: 'Teslimat Adresi',
      value: _order!.deliveryAddress ?? 'Belirtilmemiş',
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSpacing.iconMd, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: PremiumButton(
          text: 'Ana Sayfaya Dön',
          onPressed: _navigateToHome,
          variant: ButtonVariant.primary,
        ),
      ),
    );
  }

  void _navigateToHome() {
    // Navigate directly to CustomerMainPage with market tab selected
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const CustomerMainPage(initialTab: 3),
      ),
      (route) => false, // Remove all previous routes
    );
  }
}
