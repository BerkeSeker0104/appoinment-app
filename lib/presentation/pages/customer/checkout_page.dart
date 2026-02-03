import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/order.dart';
import '../../../data/services/branch_api_service.dart';
import '../../../data/services/cart_api_service.dart';
import '../../../data/models/branch_model.dart';
import '../../widgets/delivery_type_selector.dart';
import '../../widgets/address_input_field.dart';
import '../../widgets/address_selection_widget.dart';
import '../../widgets/premium_button.dart';
import '../../providers/address_provider.dart';
import '../../../domain/entities/user_address.dart';
import '../../providers/cart_provider.dart';
import 'payment_webview_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final BranchApiService _branchApiService = BranchApiService();
  final CartApiService _cartApiService = CartApiService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DeliveryType _deliveryType = DeliveryType.pickup;
  BranchModel? _selectedBranch;
  List<BranchModel> _branches = [];
  bool _isLoadingBranches = false;
  bool _isProcessing = false;
  UserAddress? _selectedDeliveryAddress;
  UserAddress? _selectedInvoiceAddress;
  bool _useSameAddressForInvoice = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndBranches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().loadAddresses();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndBranches() async {
    setState(() {
      _isLoadingBranches = true;
    });

    try {
      final branches = await _branchApiService.getBranches();

      if (mounted) {
        setState(() {
          _branches = branches;
          if (branches.isNotEmpty && _selectedBranch == null) {
            _selectedBranch = branches.first;
          }
          _isLoadingBranches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBranches = false;
        });
      }
    }
  }

  bool _canContinue() {
    if (_isProcessing) return false;
    
    if (_deliveryType == DeliveryType.pickup) {
      return _selectedBranch != null;
    } else {
      // Teslimat için hem teslimat hem fatura adresi gerekli
      final hasDeliveryAddress = _selectedDeliveryAddress != null || _addressController.text.trim().isNotEmpty;
      final hasInvoiceAddress = _selectedInvoiceAddress != null || _useSameAddressForInvoice;
      return hasDeliveryAddress && hasInvoiceAddress;
    }
  }

  Future<void> _handleContinue() async {
    if (!_canContinue()) {
      String errorMessage;
      if (_deliveryType == DeliveryType.pickup) {
        errorMessage = 'Lütfen bir şube seçin';
      } else if (_selectedDeliveryAddress == null && _addressController.text.trim().isEmpty) {
        errorMessage = 'Lütfen teslimat adresini seçin veya girin';
      } else {
        errorMessage = 'Lütfen fatura adresini seçin';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Sepet için API endpoint'i henüz hazır değil
    // Backend /api/basket/buy endpoint'i eklendiğinde bu akış aktif edilecek
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sepet ödeme özelliği yakında aktif olacak. Şimdilik ürün detay sayfasından "Satın Al" butonunu kullanabilirsiniz.'),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 4),
      ),
    );
    return;
    
    // ignore: dead_code
    setState(() {
      _isProcessing = true;
    });

    try {
      // Teslimat adresi
      final deliveryAddressId = _selectedDeliveryAddress?.id ?? '';
      
      // Fatura adresi
      String invoiceAddressId;
      if (_useSameAddressForInvoice && _selectedDeliveryAddress != null) {
        // Teslimat adresi ile aynı fatura adresi oluştur/bul
        invoiceAddressId = await context.read<AddressProvider>()
            .ensureInvoiceAddressFromDelivery(_selectedDeliveryAddress!);
      } else {
        invoiceAddressId = _selectedInvoiceAddress?.id ?? '';
      }

      if (deliveryAddressId.isEmpty || invoiceAddressId.isEmpty) {
        throw Exception('Adres bilgileri eksik');
      }

      // API çağrısı yap ve HTML içeriği al
      final htmlContent = await _cartApiService.buyCart(
        invoiceAddressId: invoiceAddressId,
        deliveryAddressId: deliveryAddressId,
      );

      if (mounted) {
        Navigator.pushReplacement(
      context,
      MaterialPageRoute(
            builder: (context) => PaymentWebViewPage(
              htmlContent: htmlContent,
        ),
      ),
    );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.checkout,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Sepetiniz boş',
                    style: AppTypography.h5,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PremiumButton(
                    text: 'Sepete Dön',
                    onPressed: () => Navigator.pop(context),
                    variant: ButtonVariant.primary,
                    isFullWidth: false,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart Summary
                      _buildCartSummary(cartProvider),
                      const SizedBox(height: AppSpacing.xxl),

                      // Delivery Type Selection
                      Text(
                        'Teslimat Tipi',
                        style: AppTypography.h5.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DeliveryTypeSelector(
                        selectedType: _deliveryType,
                        onChanged: (type) {
                          setState(() {
                            _deliveryType = type;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Branch Selection (for pickup)
                      if (_deliveryType == DeliveryType.pickup) ...[
                        Text(
                          'Şube Seçin',
                          style: AppTypography.h5.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildBranchSelector(),
                        const SizedBox(height: AppSpacing.xxl),
                      ],

                      // Address Selection (for delivery)
                      if (_deliveryType == DeliveryType.delivery) ...[
                        AddressSelectionWidget(
                          addressType: AddressType.delivery,
                          selectedAddress: _selectedDeliveryAddress,
                          onAddressSelected: (address) {
                            setState(() {
                              _selectedDeliveryAddress = address;
                              if (address != null) {
                                _addressController.text = address.address;
                                // Eğer adres adı "ev" içeriyorsa, fatura adresini de aynı yap
                                final addressNameLower = address.addressName.toLowerCase();
                                if (addressNameLower.contains('ev') || addressNameLower.contains('home')) {
                                  _useSameAddressForInvoice = true;
                                  _selectedInvoiceAddress = address;
                                  context.read<AddressProvider>().selectInvoiceAddress(address);
                                }
                              }
                            });
                          },
                          label: 'Teslimat Adresi',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'veya',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AddressInputField(
                          controller: _addressController,
                          label: 'Manuel Adres Girişi',
                          hint: 'Adres bilgilerinizi girin',
                          maxLines: 4,
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Fatura Adresi Bölümü
                        Text(
                          'Fatura Adresi',
                          style: AppTypography.h5.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        
                        // Checkbox: Fatura adresim teslimat adresimle aynı
                        if (_selectedDeliveryAddress != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _useSameAddressForInvoice,
                                  onChanged: (value) {
                                    setState(() {
                                      _useSameAddressForInvoice = value ?? false;
                                      if (_useSameAddressForInvoice && _selectedDeliveryAddress != null) {
                                        _selectedInvoiceAddress = _selectedDeliveryAddress;
                                        context.read<AddressProvider>().selectInvoiceAddress(_selectedDeliveryAddress!);
                                      } else {
                                        _selectedInvoiceAddress = null;
                                        context.read<AddressProvider>().selectInvoiceAddress(null);
                                      }
                                    });
                                  },
                                  activeColor: AppColors.primary,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _useSameAddressForInvoice = !_useSameAddressForInvoice;
                                        if (_useSameAddressForInvoice && _selectedDeliveryAddress != null) {
                                          _selectedInvoiceAddress = _selectedDeliveryAddress;
                                          context.read<AddressProvider>().selectInvoiceAddress(_selectedDeliveryAddress!);
                                        } else {
                                          _selectedInvoiceAddress = null;
                                          context.read<AddressProvider>().selectInvoiceAddress(null);
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
                        
                        // Fatura Adresi Seçimi (checkbox seçili değilse göster)
                        if (!_useSameAddressForInvoice) ...[
                          AddressSelectionWidget(
                            addressType: AddressType.invoice,
                            selectedAddress: _selectedInvoiceAddress,
                            onAddressSelected: (address) {
                              setState(() {
                                _selectedInvoiceAddress = address;
                                context.read<AddressProvider>().selectInvoiceAddress(address);
                              });
                            },
                            label: 'Fatura Adresi',
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                        ] else ...[
                          const SizedBox(height: AppSpacing.xxl),
                        ],
                      ],

                      // Notes
                      AddressInputField(
                        controller: _notesController,
                        label: 'Notlar (Opsiyonel)',
                        hint: 'Siparişinizle ilgili özel notlarınız',
                        maxLines: 3,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),

              // Bottom Summary Bar
              _buildBottomBar(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartSummary(CartProvider cartProvider) {
    return Container(
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
            'Sipariş Özeti',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...cartProvider.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
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
                            '${item.quantity}x ₺${item.productPrice.toStringAsFixed(2)}',
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
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: AppSpacing.xl),
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
                '₺${cartProvider.totalAmount.toStringAsFixed(2)}',
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

  Widget _buildBranchSelector() {
    if (_isLoadingBranches) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_branches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.info),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Şube bulunamadı. Lütfen daha sonra tekrar deneyin.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _branches.map((branch) {
          final isSelected = _selectedBranch?.id == branch.id;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedBranch = branch;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.border,
                    width: branch.id != _branches.last.id ? 1 : 0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.store,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      size: AppSpacing.iconMd,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          branch.address,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: AppSpacing.iconLg,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cartProvider) {
    return SafeArea(
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
                  '₺${cartProvider.totalAmount.toStringAsFixed(2)}',
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              text: _isProcessing ? 'Yükleniyor...' : 'Ödemeye Geç',
              onPressed: _canContinue() ? _handleContinue : null,
              variant: ButtonVariant.primary,
              isLoading: _isProcessing,
            ),
          ],
        ),
      ),
    );
  }
}

