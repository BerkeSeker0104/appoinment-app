import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/cart_item_card.dart';
import '../../widgets/cart_bottom_bar.dart';
import '../../widgets/premium_button.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import 'customer_main_page.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
      // Ensure product list is available for thumbnails
      final productProvider = context.read<ProductProvider>();
      if (productProvider.products.isEmpty) {
        productProvider.loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.myCart,
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
          if (cartProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (cartProvider.isEmpty) {
            return _buildEmptyCart();
          }

          return Stack(
            children: [
              ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.lg,
                  AppSpacing.screenHorizontal,
                  120,
                ),
                itemCount: cartProvider.items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.lg),
                itemBuilder: (context, index) {
                  final item = cartProvider.items[index];
                  return Dismissible(
                    key: ValueKey('cart_${item.productId}_${index}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.delete_forever,
                        color: AppColors.error,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      final success =
                          await cartProvider.removeFromCart(item.productId);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${item.productName} ${AppLocalizations.of(context)!.productRemoved}',
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                      return success;
                    },
                    child: CartItemCard(
                      item: item,
                      onIncrease: () async {
                        final success = await cartProvider.increaseQuantity(
                          item.productId,
                          quantity: 1,
                        );
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                cartProvider.error ??
                                    AppLocalizations.of(context)!
                                        .quantityIncreaseError,
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      onDecrease: () async {
                        final success = await cartProvider.decreaseQuantity(
                          item.productId,
                          quantity: 1,
                        );
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                cartProvider.error ??
                                    AppLocalizations.of(context)!
                                        .quantityDecreaseError,
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      onRemove: () async {
                        final success =
                            await cartProvider.removeFromCart(item.productId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '${item.productName} ${AppLocalizations.of(context)!.productRemoved}'
                                    : cartProvider.error ??
                                        AppLocalizations.of(context)!
                                            .productRemoveError,
                              ),
                              backgroundColor: success
                                  ? AppColors.success
                                  : AppColors.error,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CartBottomBar(
                  totalAmount: cartProvider.totalAmount,
                  onCheckout: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckoutPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: AppSpacing.iconXxl,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              AppLocalizations.of(context)!.cartEmpty,
              style: AppTypography.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppLocalizations.of(context)!.cartEmptyMessage,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: PremiumButton(
                text: AppLocalizations.of(context)!.startShopping,
                onPressed: () {
                  // Önce market sekmesine geç (navbar içinde) - context hala geçerli
                  CustomerMainPage.navigateToMarketTab(context);
                  // Sonra sepet sayfasını kapat
                  Navigator.pop(context);
                },
                variant: ButtonVariant.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
