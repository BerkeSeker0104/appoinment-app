import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../widgets/salon_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _showFilters = false;

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
        title: Text(
          'Search',
          style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(
              Icons.tune,
              color: _showFilters ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search salons, barbershops...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textTertiary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textTertiary,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),

          // Filters Section
          if (_showFilters) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSimpleChip('All', _selectedCategory == 'All',
                            () => setState(() => _selectedCategory = 'All')),
                        const SizedBox(width: AppSpacing.md),
                        _buildSimpleChip(
                            'Barber Shop',
                            _selectedCategory == 'Barber Shop',
                            () => setState(
                                () => _selectedCategory = 'Barber Shop')),
                        const SizedBox(width: AppSpacing.md),
                        _buildSimpleChip(
                            'Hair Salon',
                            _selectedCategory == 'Hair Salon',
                            () => setState(
                                () => _selectedCategory = 'Hair Salon')),
                        const SizedBox(width: AppSpacing.md),
                        _buildSimpleChip(
                            'Unisex',
                            _selectedCategory == 'Unisex',
                            () => setState(() => _selectedCategory = 'Unisex')),
                        const SizedBox(width: AppSpacing.md),
                        _buildSimpleChip(
                            'Pet Grooming',
                            _selectedCategory == 'Pet Grooming',
                            () => setState(
                                () => _selectedCategory = 'Pet Grooming')),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],

          // Results
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildEmptyState()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChip(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Search for salons and barbershops',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Find the perfect place for your next appointment',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: 0, // disable mock items until API wiring is done
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.lg),
      itemBuilder: (context, index) {
        return SalonCard(
          name: _getSalonName(index),
          category: _getSalonCategory(index),
          rating: _getSalonRating(index),
          distance: _getSalonDistance(index),
          imageUrl: 'https://via.placeholder.com/300x200',
          isOpen: index % 3 != 0,
          isFavorite: index % 4 == 0,
        );
      },
    );
  }

  String _getSalonName(int index) {
    const names = [
      'Elite Barber Studio',
      'Golden Scissors',
      'Urban Hair Lounge',
      'Classic Cuts & Shave',
      'Modern Style Hub',
      'Premium Cuts',
      'Style Masters',
      'The Grooming Club',
    ];
    return names[index];
  }

  String _getSalonCategory(int index) {
    const categories = [
      'Barber Shop',
      'Hair Salon',
      'Unisex',
      'Barber Shop',
      'Hair Salon',
      'Unisex',
      'Barber Shop',
      'Pet Grooming',
    ];
    return categories[index];
  }

  double _getSalonRating(int index) {
    const ratings = [4.8, 4.9, 4.6, 4.7, 4.5, 4.3, 4.8, 4.4];
    return ratings[index];
  }

  String _getSalonDistance(int index) {
    const distances = [
      '0.5 km',
      '1.2 km',
      '0.8 km',
      '2.1 km',
      '1.5 km',
      '0.3 km',
      '3.2 km',
      '1.8 km',
    ];
    return distances[index];
  }
}
