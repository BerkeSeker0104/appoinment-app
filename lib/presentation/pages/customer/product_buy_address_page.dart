import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/user_address.dart';
import '../../widgets/address_selection_widget.dart';
import '../../providers/address_provider.dart';
import '../../widgets/premium_button.dart';
import 'product_buy_payment_page.dart';

class ProductBuyAddressPage extends StatefulWidget {
  final Product product;
  final int quantity;

  const ProductBuyAddressPage({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  State<ProductBuyAddressPage> createState() => _ProductBuyAddressPageState();
}

class _ProductBuyAddressPageState extends State<ProductBuyAddressPage> {
  UserAddress? _selectedDeliveryAddress;
  UserAddress? _selectedInvoiceAddress;
  bool _useSameAddressForInvoice = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().loadAddresses();
    });
  }

  bool _canContinue() {
    if (_selectedDeliveryAddress == null) return false;
    // If using same address for invoice, allow it (backend should handle it)
    if (_useSameAddressForInvoice) {
      return true;
    }
    // Otherwise, invoice address must be selected
    return _selectedInvoiceAddress != null;
  }

  Future<void> _handleContinue() async {
    if (!_canContinue()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen teslimat ve fatura adreslerini seçin'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      String invoiceAddressId;

      if (_useSameAddressForInvoice) {
        // "Aynı adresi kullan" seçildi
        // Backend'de invoiceAddressId için type: "invoice" olan adres gerekiyor
        // Teslimat adresi bilgileriyle aynı/yeni bir fatura adresi ID'si al
        
        invoiceAddressId = await context.read<AddressProvider>()
            .ensureInvoiceAddressFromDelivery(_selectedDeliveryAddress!);
            
      } else {
        // Kullanıcı ayrı bir fatura adresi seçti
        invoiceAddressId = _selectedInvoiceAddress!.id;
      }

      // Debug: Log address types
      print('Address Selection Debug:');
      print('  Delivery Address ID: ${_selectedDeliveryAddress!.id}');
      print('  Delivery Address Type: ${_selectedDeliveryAddress!.type}');
      print('  Use Same Address: $_useSameAddressForInvoice');
      print('  Invoice Address ID: $invoiceAddressId');

      if (!mounted) return;

      // Navigate to payment page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductBuyPaymentPage(
            product: widget.product,
            quantity: widget.quantity,
            deliveryAddressId: _selectedDeliveryAddress!.id,
            invoiceAddressId: invoiceAddressId,
          ),
        ),
      );
    } catch (e) {
      print('Error in _handleContinue: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
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
          'Adres Seçimi',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Summary
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
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
                          'Ürün Özeti',
                          style: AppTypography.h5.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${widget.quantity}x ₺${widget.product.price.toStringAsFixed(2)}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
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

                  // Delivery Address Selection
                  Text(
                    'Teslimat Adresi',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AddressSelectionWidget(
                    addressType: AddressType.delivery,
                    selectedAddress: _selectedDeliveryAddress,
                    onAddressSelected: (address) {
                      setState(() {
                        _selectedDeliveryAddress = address;
                        if (address != null) {
                          // Auto-check "use same address" if address name contains "ev" or "home"
                          final addressNameLower =
                              address.addressName.toLowerCase();
                          if (addressNameLower.contains('ev') ||
                              addressNameLower.contains('home')) {
                            _useSameAddressForInvoice = true;
                            _selectedInvoiceAddress = address;
                            context
                                .read<AddressProvider>()
                                .selectInvoiceAddress(address);
                          } else {
                            // Keep current state, don't auto-uncheck
                            // User can manually check/uncheck the checkbox
                          }
                        }
                      });
                    },
                    label: 'Teslimat Adresi',
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Invoice Address Section
                  Text(
                    'Fatura Adresi',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Checkbox: Fatura adresim teslimat adresimle aynı
                  // Always show if delivery address is selected
                  if (_selectedDeliveryAddress != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _useSameAddressForInvoice,
                            onChanged: (value) {
                              setState(() {
                                _useSameAddressForInvoice = value ?? false;
                                if (_useSameAddressForInvoice &&
                                    _selectedDeliveryAddress != null) {
                                  _selectedInvoiceAddress =
                                      _selectedDeliveryAddress;
                                  context
                                      .read<AddressProvider>()
                                      .selectInvoiceAddress(
                                          _selectedDeliveryAddress!);
                                } else {
                                  _selectedInvoiceAddress = null;
                                  context
                                      .read<AddressProvider>()
                                      .selectInvoiceAddress(null);
                                }
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _useSameAddressForInvoice =
                                      !_useSameAddressForInvoice;
                                  if (_useSameAddressForInvoice &&
                                      _selectedDeliveryAddress != null) {
                                    _selectedInvoiceAddress =
                                        _selectedDeliveryAddress;
                                    context
                                        .read<AddressProvider>()
                                        .selectInvoiceAddress(
                                            _selectedDeliveryAddress!);
                                  } else {
                                    _selectedInvoiceAddress = null;
                                    context
                                        .read<AddressProvider>()
                                        .selectInvoiceAddress(null);
                                  }
                                });
                              },
                              child: Text(
                                'Fatura adresim teslimat adresimle aynı',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Invoice Address Selection (if checkbox not selected)
                  if (!_useSameAddressForInvoice) ...[
                    AddressSelectionWidget(
                      addressType: AddressType.invoice,
                      selectedAddress: _selectedInvoiceAddress,
                      onAddressSelected: (address) {
                        setState(() {
                          _selectedInvoiceAddress = address;
                          context
                              .read<AddressProvider>()
                              .selectInvoiceAddress(address);
                        });
                      },
                      label: 'Fatura Adresi',
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ] else ...[
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ],
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
                    text: _isProcessing ? 'İşleniyor...' : 'Ödemeye Geç',
                    onPressed: (_canContinue() && !_isProcessing) ? _handleContinue : null,
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
}
