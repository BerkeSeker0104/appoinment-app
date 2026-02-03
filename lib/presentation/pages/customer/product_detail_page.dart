import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/product.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/quantity_selector.dart';
import '../auth/sign_up_page.dart';
import 'product_buy_address_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedImageIndex = 0;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProductInfo(),
                _buildDescriptionSection(),
                _buildBottomSpacing(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Product Images
            if (widget.product.pictures.isNotEmpty)
              PageView.builder(
                onPageChanged: (index) {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                itemCount: widget.product.pictures.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: widget.product.pictures[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.backgroundSecondary,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.backgroundSecondary,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: AppColors.textTertiary,
                            size: AppSpacing.iconXxxl,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Resim Yüklenemedi',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Container(
                color: AppColors.backgroundSecondary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory,
                      color: AppColors.textTertiary,
                      size: AppSpacing.iconXxxl,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Resim Yok',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            // Image indicators
            if (widget.product.pictures.length > 1)
              Positioned(
                bottom: AppSpacing.lg,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.product.pictures.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _selectedImageIndex == index
                            ? AppColors.surface
                            : AppColors.surface.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Text(
            widget.product.name,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Company Name
          Text(
            widget.product.companyName,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Price
          Row(
            children: [
              Text(
                '₺${widget.product.price.toStringAsFixed(2)}',
                style: AppTypography.h2.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Stokta',
                  style: AppTypography.label.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quantity Selector
          Row(
            children: [
              Text(
                'Miktar:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              QuantitySelector(
                quantity: _quantity,
                onChanged: (quantity) {
                  setState(() {
                    _quantity = quantity;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.screenHorizontal,
        bottom: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ürün Açıklaması',
            style: AppTypography.h6.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.product.description.isNotEmpty
                ? widget.product.description
                : 'Bu ürün için detaylı açıklama bulunmamaktadır. Ürün kaliteli malzemelerden üretilmiştir ve profesyonel kullanım için uygundur.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Consumer<CartProvider>(
                builder: (context, cartProvider, child) {
                  return ElevatedButton(
                    onPressed: cartProvider.isLoading
                        ? null
                        : () => _addToCart(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      elevation: 0,
                    ),
                    child: cartProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.surface,
                              ),
                            ),
                          )
                        : Text(
                            'Sepete Ekle',
                            style: AppTypography.buttonLarge.copyWith(
                              color: AppColors.surface,
                            ),
                          ),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Buy Now Button - Tam genişlik
            Expanded(
              child: ElevatedButton(
                onPressed: _buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Satın Al',
                  style: AppTypography.buttonLarge.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSpacing() {
    return const SizedBox(height: 100);
  }

  void _addToCart(BuildContext context) async {
    // Check if user is logged in (has token)
    final apiClient = ApiClient();
    final token = await apiClient.getToken();
  //
    if (token == null) {
      // Guest user - show dialog to sign up
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.mustSignUpFirst,
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            l10n.mustSignUpFirstMessage,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: AppTypography.buttonMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: Text(
                l10n.goToSignUp,
                style: AppTypography.buttonMedium.copyWith(color: AppColors.secondary),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // UUID string olarak direkt gönder
    final success = await context
        .read<CartProvider>()
        .addToCart(widget.product.id, quantity: _quantity);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${widget.product.name} sepete eklendi'
              : context.read<CartProvider>().error ?? 'Sepete eklenemedi',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _buyNow() async {
    // Check if user is logged in (has token)
    final apiClient = ApiClient();
    final token = await apiClient.getToken();

    if (token == null) {
      // Guest user - show dialog to sign up
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.mustSignUpFirst,
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            l10n.mustSignUpFirstMessage,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: AppTypography.buttonMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                );
              },
              child: Text(
                l10n.goToSignUp,
                style: AppTypography.buttonMedium
                    .copyWith(color: AppColors.secondary),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to address selection page
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductBuyAddressPage(
          product: widget.product,
          quantity: _quantity,
        ),
      ),
    );
  }
}
