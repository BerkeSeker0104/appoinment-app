import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../../../data/repositories/product_repository_impl.dart';
import '../../../data/services/order_api_service.dart';
import '../../widgets/premium_button.dart';
import 'payment_webview_page.dart';
import 'order_success_page.dart';

class ProductBuyPaymentPage extends StatefulWidget {
  final Product product;
  final int quantity;
  final String deliveryAddressId;
  final String invoiceAddressId;

  const ProductBuyPaymentPage({
    super.key,
    required this.product,
    required this.quantity,
    required this.deliveryAddressId,
    required this.invoiceAddressId,
  });

  @override
  State<ProductBuyPaymentPage> createState() => _ProductBuyPaymentPageState();
}

class _ProductBuyPaymentPageState extends State<ProductBuyPaymentPage> {
  final ProductUseCases _productUseCases =
      ProductUseCases(ProductRepositoryImpl());

  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  bool _isProcessing = false;

  Future<void> _handlePaymentSuccess() async {
    try {
      // Loading göster
      if (!mounted) return;

      // 1. Son siparişi çek
      final orderApiService = OrderApiService();
      final orders = await orderApiService.getOrders(
        page: 1,
        limit: 1,
      );

      if (orders.isNotEmpty) {
        final latestOrder = orders.first;

        // 2. Sipariş detayını çek
        final orderDetail = await orderApiService.getOrder(latestOrder.id);

        if (!mounted) return;

        // 3. OrderSuccessPage'e yönlendir ve tüm önceki sayfaları temizle
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessPage(
              orderId: orderDetail.id,
              orderNumber: orderDetail.orderNumber,
              paymentMethod: 'creditCard',
            ),
          ),
          (route) => false, // Tüm önceki sayfaları temizle
        );
      } else {
        // Sipariş bulunamadı
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Sipariş bilgileri alınamadı. Lütfen sipariş geçmişinizi kontrol edin.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Hata durumunda kullanıcıyı bilgilendir
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Sipariş bilgileri yüklenirken hata oluştu: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final cardNumber = _cardNumberController.text.replaceAll(' ', '');
      final expiryMonth = _expiryMonthController.text.padLeft(2, '0');
      final expiryYear = _expiryYearController.text;
      final cvv = _cvvController.text;

      final htmlContent = await _productUseCases.buyProduct(
        productId: widget.product.id,
        cardNumber: cardNumber,
        cardExpirationMonth: expiryMonth,
        cardExpirationYear: expiryYear,
        cardCvc: cvv,
        invoiceAddressId: widget.invoiceAddressId,
        deliveryAddressId: widget.deliveryAddressId,
      );

      if (!mounted) return;

      // pushReplacement yerine push kullan ve sonucu dinle
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWebViewPage(
            htmlContent: htmlContent,
          ),
        ),
      );

      // Ödeme başarılı kontrolü
      if (result == true && mounted) {
        // Ödeme başarılı - sipariş bilgilerini al
        await _handlePaymentSuccess();
      } else if (result == false && mounted) {
        // Ödeme başarısız
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Ödeme işlemi başarısız oldu. Lütfen tekrar deneyin.'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (result == null && mounted) {
        // URL pattern eşleşmedi, sipariş durumunu kontrol et
        // Bazen ödeme başarılı olsa bile URL pattern'i eşleşmeyebilir
        print('ProductBuyPaymentPage: WebView\'dan result null döndü, sipariş durumu kontrol ediliyor...');
        try {
          // Son siparişi kontrol et
          final orderApiService = OrderApiService();
          final orders = await orderApiService.getOrders(page: 1, limit: 1);
          
          if (orders.isNotEmpty) {
            final latestOrder = orders.first;
            // Eğer sipariş yakın zamanda oluşturulmuşsa (son 2 dakika içinde) başarılı sayfasına yönlendir
            final now = DateTime.now();
            final orderCreatedAt = latestOrder.createdAt;
            final difference = now.difference(orderCreatedAt);
            
            if (difference.inMinutes < 2) {
              // Sipariş yakın zamanda oluşturulmuş, muhtemelen ödeme başarılı
              print('ProductBuyPaymentPage: Yakın zamanda oluşturulmuş sipariş bulundu, başarılı sayfasına yönlendiriliyor');
              await _handlePaymentSuccess();
              return;
            }
          }
          
          // Sipariş bulunamadı veya eski, kullanıcıyı bilgilendir
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Ödeme durumu belirlenemedi. Lütfen sipariş geçmişinizi kontrol edin.'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (e) {
          print('ProductBuyPaymentPage: Sipariş kontrolü sırasında hata: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Ödeme durumu kontrol edilemedi. Lütfen sipariş geçmişinizi kontrol edin.'),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ödeme başlatılamadı: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.product.price * widget.quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Ödeme Bilgileri',
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXxl),
                        border: Border.all(color: AppColors.border),
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
                          Text(
                            'Sipariş Özeti',
                            style: AppTypography.h6.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${widget.quantity}x ${widget.product.name}',
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                              Text(
                                '₺${totalAmount.toStringAsFixed(2)}',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Card Information
                    Text(
                      'Kart Bilgileri',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Card Holder Name
                    _buildTextField(
                      controller: _cardHolderController,
                      label: 'Kart Üzerindeki İsim',
                      hint: 'AD SOYAD',
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kart sahibi adını girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Card Number
                    _buildTextField(
                      controller: _cardNumberController,
                      label: 'Kart Numarası',
                      hint: '0000 0000 0000 0000',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberFormatter(),
                      ],
                      validator: (value) {
                        final cardNumber = value?.replaceAll(' ', '') ?? '';
                        if (cardNumber.length < 16) {
                          return 'Geçerli bir kart numarası girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Expiry Date and CVV
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _expiryMonthController,
                            label: 'Ay',
                            hint: 'MM',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ay girin';
                              }
                              final month = int.tryParse(value);
                              if (month == null || month < 1 || month > 12) {
                                return 'Geçersiz ay';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildTextField(
                            controller: _expiryYearController,
                            label: 'Yıl',
                            hint: 'YY',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Yıl girin';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildTextField(
                            controller: _cvvController,
                            label: 'CVV',
                            hint: '000',
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (value) {
                              if (value == null || value.length < 3) {
                                return 'CVV girin';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Security Info
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: AppColors.info,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Ödemeniz 3D Secure ile güvence altındadır.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Toplam',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₺${totalAmount.toStringAsFixed(2)}',
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PremiumButton(
                    text: _isProcessing ? 'İşleniyor...' : 'Ödemeyi Tamamla',
                    onPressed: _isProcessing ? null : _processPayment,
                    variant: ButtonVariant.primary,
                    isLoading: _isProcessing,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
