import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/memory_manager.dart';
import '../../../core/utils/performance_utils.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_chip.dart';
import '../../providers/product_provider.dart';
import '../../../domain/entities/product.dart';
import '../customer/featured_products_page.dart';

class CompanyMarketPage extends StatefulWidget {
  const CompanyMarketPage({super.key});

  @override
  State<CompanyMarketPage> createState() => _CompanyMarketPageState();
}

class _CompanyMarketPageState extends State<CompanyMarketPage>
    with MemoryAwareWidget {
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

    // Load data with debouncing to prevent excessive API calls
    PerformanceUtils.debounce('market_data_load', () {
      productProvider.loadCategories();
      productProvider.loadProducts();
      // Note: No cart loading for company users
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Market',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Diğer işletmelerin ürünlerini keşfedin',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
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
            icon: Icon(
              _isSearchExpanded ? Icons.close : Icons.search,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (_isSearchExpanded) _buildSearchBar(),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCategories(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildFeaturedProducts(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildProductGrid(),
                const SizedBox(height: 100), // Navigation space
              ]),
            ),
          ),
        ],
      ),
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
            hintText: 'Ürün ara...',
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
              'Kategoriler',
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
                            ? 'Kategoriler yükleniyor...'
                            : 'Kategori bulunamadı',
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

  Widget _buildFeaturedProducts() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final products = productProvider.products.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Öne Çıkan Ürünler',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeaturedProductsPage(),
                      ),
                    );
                  },
                  child: Text(
                    'Tümünü Gör',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 240,
              child: products.isEmpty
                  ? Center(
                      child: Text(
                        productProvider.isLoading
                            ? 'Ürünler yükleniyor...'
                            : 'Ürün bulunamadı',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : PerformanceMonitor(
                      name: 'FeaturedProductsList',
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: AppSpacing.lg),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return SizedBox(
                            width: 160,
                            child: ProductCard(
                              product: product,
                              onTap: () =>
                                  _navigateToProductDetail(context, product),
                              // No onBuyNow for company users - viewing only
                              onBuyNow: null,
                            ),
                          );
                        },
                        // Performance optimizations
                        cacheExtent: _isLowMemory ? 100 : 200,
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                      ),
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
        final products = productProvider.products;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tüm Ürünler',
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
                          ? 'Ürünler yükleniyor...'
                          : 'Ürün bulunamadı',
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
                        return ProductCard(
                          product: product,
                          onTap: () =>
                              _navigateToProductDetail(context, product),
                          // No onBuyNow for company users - viewing only
                          onBuyNow: null,
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
        builder: (context) => CompanyProductDetailPage(product: product),
      ),
    );
  }
}

/// Company version of ProductDetailPage - viewing only, no purchase buttons
class CompanyProductDetailPage extends StatefulWidget {
  final Product product;

  const CompanyProductDetailPage({
    super.key,
    required this.product,
  });

  @override
  State<CompanyProductDetailPage> createState() =>
      _CompanyProductDetailPageState();
}

class _CompanyProductDetailPageState extends State<CompanyProductDetailPage> {
  int _selectedImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildProductImages(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProductInfo(),
                _buildDescriptionSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImages() {
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
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.product.pictures.isNotEmpty)
              PageView.builder(
                onPageChanged: (index) {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                itemCount: widget.product.pictures.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    widget.product.pictures[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
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
          Text(
            widget.product.name,
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
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
                : 'Bu ürün için detaylı açıklama bulunmamaktadır.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}
