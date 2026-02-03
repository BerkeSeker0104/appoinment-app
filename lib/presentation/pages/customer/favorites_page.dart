import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/salon_card.dart';
import '../../widgets/guest_auth_overlay.dart';
import 'barber_detail_page.dart';
import 'customer_main_page.dart';

class FavoritesPage extends StatefulWidget {
  final bool fromHome;
  
  const FavoritesPage({super.key, this.fromHome = false});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    // Load favorites when page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoriteProvider>().loadFavorites();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<FavoriteProvider>().refreshFavorites();
  }

  void _handleFavoriteToggle(String companyId) async {
    final provider = context.read<FavoriteProvider>();
    try {
      await provider.toggleFavorite(companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.isFavorite(companyId)
                  ? AppLocalizations.of(context)!.addedToFavorites
                  : AppLocalizations.of(context)!.removedFromFavorites,
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Hata: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToDetail(String companyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarberDetailPage(companyId: companyId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GuestAuthOverlay(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<FavoriteProvider>(
                  builder: (context, provider, child) {
                    // Don't show loading or error states for guest users - overlay handles it
                    if (provider.isLoading && provider.favorites.isEmpty) {
                      return _buildLoadingState();
                    }

                    // Only show error if it's not unauthorized (guest users handled by overlay)
                    if (provider.errorMessage != null &&
                        provider.favorites.isEmpty &&
                        !provider.errorMessage!.toLowerCase().contains('unauthorized') &&
                        !provider.errorMessage!.toLowerCase().contains('401') &&
                        !provider.errorMessage!.toLowerCase().contains('yetkisiz')) {
                      return _buildErrorState(provider.errorMessage!);
                    }

                    if (provider.favorites.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildFavoritesList(provider);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (widget.fromHome) {
                    // Ana sayfadan geldiyse, ana sayfaya dön
                    Navigator.pop(context);
                    // Ana sayfaya (tab 0) geçmek için CustomerMainPage'i bul ve tab'ı değiştir
                    CustomerMainPage.navigateToHomeTab(context);
                  } else {
                    // Profil sayfasından geldiyse, normal geri dön
                    Navigator.pop(context);
                  }
                },
                icon: Icon(Icons.arrow_back_ios_rounded),
                color: AppColors.textPrimary,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.myFavorites,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Consumer<FavoriteProvider>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${provider.favorites.length} favori firma',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Favoriler yükleniyor...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Bir hata oluştu',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.retry,
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Henüz favori firmanız yok',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Beğendiğiniz firmaları favorilerinize ekleyerek kolayca ulaşabilirsiniz',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(FavoriteProvider provider) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.md,
          AppSpacing.screenHorizontal,
          AppSpacing.screenHorizontal + 100, // Space for nav bar
        ),
        itemCount: provider.favoriteCompanies.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final company = provider.favoriteCompanies[index];

          // Check if this is placeholder data and show better fallback
          final isPlaceholderName =
              company.name.toLowerCase().contains('deneme') ||
                  company.name.toLowerCase().contains('test') ||
                  company.name.isEmpty;

          final isPlaceholderType = company.type.contains('Tip ') ||
              company.type.contains('Deneme') ||
              company.type.contains('Profesyonel berber hizmetleri') ||
              company.type.isEmpty;

          final displayName =
              isPlaceholderName ? AppLocalizations.of(context)!.barberSalon : company.name;
          final displayCategory =
              isPlaceholderType ? AppLocalizations.of(context)!.barberSalon : company.type;

          // Try to get a better description from address if type is placeholder
          final displayDescription =
              isPlaceholderType && company.address.isNotEmpty
                  ? company.address
                  : displayCategory;

          // Use rating from provider (calculated using getCompanyRatingStats like detail page)
          final rating = provider.getCompanyRating(company.id);

          return SalonCard(
            name: displayName,
            category: displayDescription,
            rating: rating,
            distance: '', // Distance calculation would need location
            imageUrl: company.image ?? '',
            isOpen: company.isActive,
            isFavorite: true, // Always true in favorites list
            companyId: company.id, // Pass companyId for provider sync
            onTap: () => _navigateToDetail(company.id),
            onFavoriteToggle: () => _handleFavoriteToggle(company.id),
          );
        },
      ),
    );
  }
}
