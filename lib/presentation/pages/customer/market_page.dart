import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/memory_manager.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/performance_utils.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_chip.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../../domain/entities/product.dart';
import '../auth/sign_up_page.dart';
import 'product_detail_page.dart';
import 'cart_page.dart';
import 'product_buy_address_page.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> with MemoryAwareWidget {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  bool _isLowMemory = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _isLowMemory = MemoryManager().isLowMemory;
    initMemoryAware();

    // Add listener for real-time search
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final productProvider = context.read<ProductProvider>();
    final cartProvider = context.read<CartProvider>();

    // Load data with debouncing to prevent excessive API calls
    PerformanceUtils.debounce('market_data_load', () {
      productProvider.loadCategories();
      productProvider.loadProducts();
      cartProvider.loadCart();
    });
  }

  @override
  void onMemoryPressure() {
    setState(() {
      _isLowMemory = MemoryManager().isLowMemory;
    });

    // Clear any cached data when memory is low
    if (_isLowMemory) {
      PerformanceUtils.clearImageCache();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    disposeMemoryAware();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isSearchExpanded) _buildSearchBar(),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCategories(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildProductGrid(),
                SizedBox(height: 100 + MediaQuery.of(context).viewInsets.bottom), // Navigation space
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
    return SliverAppBar(
      expandedHeight: 72,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.marketTitle,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.marketSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CartPage(),
              ),
            );
          },
          icon: const Icon(Icons.shopping_cart_outlined),
          color: AppColors.primary,
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _isSearchExpanded = !_isSearchExpanded;
              if (!_isSearchExpanded) {
                _searchController.clear();
                _clearSearch();
              }
            });
          },
          icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
          color: AppColors.primary,
        ),
        ],
      );
    },
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.md,
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchProductPlaceholder,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _clearSearch();
                    },
                    icon:
                        const Icon(Icons.clear, color: AppColors.textSecondary),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          onChanged: (value) {
            setState(() {}); // Rebuild to show/hide clear button
          },
        ),
      ),
    );
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _clearSearch();
    } else {
      _performSearch(query);
    }
  }

  void _performSearch(String query) {
    final productProvider = context.read<ProductProvider>();
    productProvider.searchProducts(query);
  }

  void _clearSearch() {
    final productProvider = context.read<ProductProvider>();
    productProvider.clearFilters();
  }

  Widget _buildCategories() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final categories = productProvider.categories;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.categories,
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 50,
              child: categories.isEmpty
                  ? Center(
                      child: Text(
                        productProvider.isLoading
                            ? AppLocalizations.of(context)!.categoriesLoading
                            : AppLocalizations.of(context)!.noCategoriesFound,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = _selectedCategoryId == category.id;

                        return CategoryChip(
                          category: category,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId =
                                  isSelected ? null : category.id;
                            });
                            productProvider
                                .filterByCategory(_selectedCategoryId);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Use getFilteredProducts() for client-side filtering as backup
        // This ensures products are filtered even if API filtering fails
        final products = productProvider.getFilteredProducts();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedCategoryId != null
                  ? productProvider.categories
                      .firstWhere((c) => c.id == _selectedCategoryId)
                      .getName()
                  : AppLocalizations.of(context)!.products,
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            products.isEmpty
                ? Center(
                    child: Text(
                      productProvider.isLoading
                          ? AppLocalizations.of(context)!.productsLoading
                          : AppLocalizations.of(context)!.noProductsFound,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : PerformanceMonitor(
                    name: 'ProductGrid',
                    child: MemoryOptimizer.buildOptimizedGrid(
                      itemCount: products.length,
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final categoryName = productProvider.categories
                            .where((c) => c.id == product.categoryId)
                            .firstOrNull
                            ?.getName();

                        return ProductCard(
                          product: product,
                          categoryName: categoryName,
                          onTap: () =>
                              _navigateToProductDetail(context, product),
                          onBuyNow: () => _buyNow(context, product),
                        );
                      },
                    ),
                  ),
          ],
        );
      },
    );
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
