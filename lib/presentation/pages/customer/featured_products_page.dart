import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/product_card.dart';
import '../../providers/product_provider.dart';
// import '../../providers/cart_provider.dart'; // Geçici olarak kaldırıldı
import '../../../domain/entities/product.dart';
import '../auth/sign_up_page.dart';
import 'product_buy_address_page.dart';
import 'product_detail_page.dart';

class FeaturedProductsPage extends StatefulWidget {
  const FeaturedProductsPage({super.key});

  @override
  State<FeaturedProductsPage> createState() => _FeaturedProductsPageState();
}

class _FeaturedProductsPageState extends State<FeaturedProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
      context.read<ProductProvider>().loadProducts();
      // context.read<CartProvider>().loadCart(); // Geçici olarak kaldırıldı
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Öne Çıkan Ürünler',
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          // Sepet ikonu geçici olarak kaldırıldı
          // Consumer<CartProvider>(
          //   builder: (context, cartProvider, child) {
          //     return Stack(
          //       children: [
          //         IconButton(
          //           icon: const Icon(
          //             Icons.shopping_cart_outlined,
          //             color: AppColors.textPrimary,
          //           ),
          //           onPressed: () {
          //             // Navigate to cart page
          //             Navigator.pushNamed(context, '/cart');
          //           },
          //         ),
          //         if (cartProvider.itemCount > 0)
          //           Positioned(
          //             right: 8,
          //             top: 8,
          //             child: Container(
          //               padding: const EdgeInsets.all(4),
          //               decoration: BoxDecoration(
          //                 color: AppColors.error,
          //                 borderRadius: BorderRadius.circular(10),
          //               ),
          //               constraints: const BoxConstraints(
          //                 minWidth: 16,
          //                 minHeight: 16,
          //               ),
          //               child: Text(
          //                 '${cartProvider.itemCount}',
          //                 style: AppTypography.bodySmall.copyWith(
          //                   color: Colors.white,
          //                   fontSize: 10,
          //                 ),
          //                 textAlign: TextAlign.center,
          //               ),
          //             ),
          //           ),
          //       ],
          //     );
          //   },
          // ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Categories Filter
          _buildCategories(),

          // Products Grid
          Expanded(
            child: _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _performSearch();
        },
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _performSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final categories = productProvider.categories;

        return Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: categories.isEmpty
              ? Center(
                  child: Text(
                    productProvider.isLoading
                        ? 'Kategoriler yükleniyor...'
                        : 'Kategori bulunamadı',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: categories.length + 1, // +1 for "Tümü" option
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "Tümü" option
                      final isSelected = _selectedCategoryId == null;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                          _applyFilters();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            'Tümü',
                            style: AppTypography.bodyMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }

                    final category = categories[index - 1];
                    final isSelected = _selectedCategoryId == category.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = isSelected ? null : category.id;
                        });
                        _applyFilters();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          category.getName(),
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = _getFilteredProducts(productProvider.products);

        if (productProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _searchQuery.isNotEmpty || _selectedCategoryId != null
                      ? 'Arama kriterlerinize uygun ürün bulunamadı'
                      : 'Öne çıkan ürün bulunamadı',
                  style: AppTypography.h6.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Farklı arama terimleri deneyebilir veya filtreleri temizleyebilirsiniz',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_searchQuery.isNotEmpty || _selectedCategoryId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: ElevatedButton(
                      onPressed: _clearFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Filtreleri Temizle'),
                    ),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await productProvider.loadProducts();
          },
          color: AppColors.primary,
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final categoryName = productProvider.categories
                  .where((c) => c.id == product.categoryId)
                  .firstOrNull
                  ?.getName();

              return ProductCard(
                product: product,
                categoryName: categoryName,
                onTap: () => _navigateToProductDetail(context, product),
                onBuyNow: () => _buyNow(context, product),
              );
            },
          ),
        );
      },
    );
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;

    // Apply category filter
    if (_selectedCategoryId != null) {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(query) ||
              product.description.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  void _performSearch() {
    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == _searchQuery) {
        _applyFilters();
      }
    });
  }

  void _applyFilters() {
    final productProvider = context.read<ProductProvider>();
    productProvider.loadProducts(
      categoryId: _selectedCategoryId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _searchQuery = '';
    });
    _searchController.clear();
    context.read<ProductProvider>().clearFilters();
  }

  void _navigateToProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(product: product),
      ),
    );
  }

  // _addToCart metodu geçici olarak kaldırıldı
  // void _addToCart(BuildContext context, Product product) async {
  //   // Check if user is logged in (has token)
  //   final apiClient = ApiClient();
  //   final token = await apiClient.getToken();
  //
  //   if (token == null) {
  //     // Guest user - show dialog to sign up
  //     if (!context.mounted) return;
  //     final l10n = AppLocalizations.of(context)!;
  //
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text(
  //           l10n.mustSignUpFirst,
  //           style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
  //         ),
  //         content: Text(
  //           l10n.mustSignUpFirstMessage,
  //           style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text(
  //               l10n.cancel,
  //               style: AppTypography.buttonMedium.copyWith(color: AppColors.textSecondary),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (context) => const SignUpPage()),
  //               );
  //             },
  //             child: Text(
  //               l10n.goToSignUp,
  //               style: AppTypography.buttonMedium.copyWith(color: AppColors.secondary),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //     return;
  //   }

  //   // UUID string olarak direkt gönder
  //   final success =
  //       await context.read<CartProvider>().addToCart(product.id, quantity: 1);

  //   if (!context.mounted) return;

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(success
  //           ? '${product.name} sepete eklendi'
  //           : context.read<CartProvider>().error ?? 'Sepete eklenemedi'),
  //       backgroundColor: success ? AppColors.success : AppColors.error,
  //       duration: const Duration(seconds: 2),
  //     ),
  //   );
  // }

  void _buyNow(BuildContext context, Product product) async {
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
          product: product,
          quantity: 1,
        ),
      ),
    );
  }
}
