import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../widgets/salon_card.dart';
import '../widgets/location_header.dart';
import '../widgets/announcement_section.dart';
import '../widgets/category_item.dart';
import '../providers/company_type_provider.dart';
import '../../data/models/company_type_model.dart';
import 'package:barber_app/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Şirket tiplerini açılışta yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyTypeProvider>().loadCompanyTypes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Header
            const LocationHeader(),

            const SizedBox(height: 0),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchPlaceholder,
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Announcements Section
            const AnnouncementSection(),

            // Categories (Company Types from backend with images)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.screenHorizontal),
              child: Consumer<CompanyTypeProvider>(
                builder: (context, typeProvider, child) {
                  final List<CompanyTypeModel> types =
                      typeProvider.companyTypes;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // removed section title per design
                      SizedBox(
                        height:
                            90, // Dairesel görsel + metin için yeterli yükseklik
                        child: types.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppSpacing.screenHorizontal),
                                  child: Text(
                                    typeProvider.isLoading
                                        ? 'Kategoriler yükleniyor...'
                                        : 'Kategori bulunamadı',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.screenHorizontal,
                                ),
                                itemCount: types.length + 1, // +1: Tümü
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return _buildAllChip(
                                        typeProvider.selectedCategoryId == null,
                                        () =>
                                            typeProvider.selectCategory(null));
                                  }
                                  final type = types[index - 1];
                                  final isSelected =
                                      typeProvider.isCategorySelected(type.id);
                                  return CategoryItem(
                                    id: type.id,
                                    name: type.name,
                                    imageUrl: type.fullImageUrl,
                                    isSelected: isSelected,
                                    onTap: () =>
                                        typeProvider.selectCategory(type.id),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Nearby Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby You',
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See All',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Salon Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
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
                  isOpen: index % 2 == 0,
                  isFavorite: index == 1,
                );
              },
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildAllChip(bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dairesel görsel/ikon alanı
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : AppColors.surface,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2.0 : 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.apps,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  size: AppSpacing.iconSm,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // "Tümü" metni
            Text(
              'Tümü',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSalonName(int index) {
    const names = [
      'Elite Barber Studio',
      'Golden Scissors',
      'Urban Hair Lounge',
      'Classic Cuts & Shave',
      'Modern Style Hub',
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
    ];
    return categories[index];
  }

  double _getSalonRating(int index) {
    const ratings = [4.8, 4.9, 4.6, 4.7, 4.5];
    return ratings[index];
  }

  String _getSalonDistance(int index) {
    const distances = ['0.5 km', '1.2 km', '0.8 km', '2.1 km', '1.5 km'];
    return distances[index];
  }
}
