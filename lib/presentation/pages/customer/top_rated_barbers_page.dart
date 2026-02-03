import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/company_api_service.dart';
import '../../../data/models/branch_model.dart';
import '../../widgets/barber_card.dart';
import 'barber_detail_page.dart';
import 'service_selection_page.dart';
import 'employee_selection_page.dart';

class TopRatedBarbersPage extends StatefulWidget {
  const TopRatedBarbersPage({super.key});

  @override
  State<TopRatedBarbersPage> createState() => _TopRatedBarbersPageState();
}

class _TopRatedBarbersPageState extends State<TopRatedBarbersPage> {
  final LocationService _locationService = LocationService();
  final CompanyApiService _companyService = CompanyApiService();

  bool _isLoading = true;
  List<BranchModel> _topRatedBarbers = [];

  @override
  void initState() {
    super.initState();
    _loadTopRatedBarbers();
  }

  Future<void> _loadTopRatedBarbers() async {
    try {
      setState(() => _isLoading = true);
      List<BranchModel> barbers = await _companyService.getTopRatedCompanies(limit: 50);

      // Ensure sorting by rating (highest first) - extra safety check
      barbers.sort((a, b) {
        final ratingA = a.averageRating ?? 0.0;
        final ratingB = b.averageRating ?? 0.0;
        final reviewsA = a.totalReviews ?? 0;
        final reviewsB = b.totalReviews ?? 0;

        // First sort by rating (descending - highest first)
        if (ratingA != ratingB) {
          return ratingB.compareTo(ratingA);
        }

        // If ratings are equal, sort by review count (descending)
        return reviewsB.compareTo(reviewsA);
      });

      if (!mounted) return;
      setState(() {
        _topRatedBarbers = barbers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşletmeler yüklenemedi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  double? _calculateDistance(BranchModel barber) {
    final position = _locationService.lastKnownPosition;
    if (position == null ||
        barber.latitude == null ||
        barber.longitude == null) {
      return null;
    }
    return _locationService.calculateDistance(
      position.latitude,
      position.longitude,
      barber.latitude!,
      barber.longitude!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : _topRatedBarbers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadTopRatedBarbers,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(
                            AppSpacing.screenHorizontal,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            childAspectRatio: 1.1,
                            mainAxisSpacing: AppSpacing.lg,
                          ),
                          itemCount: _topRatedBarbers.length,
                          itemBuilder: (context, index) {
                            final barber = _topRatedBarbers[index];
                            return BarberCard(
                              barber: barber,
                              distance: _calculateDistance(barber),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BarberDetailPage(
                                      companyId: barber.id,
                                    ),
                                  ),
                                );
                              },
                              onBookAppointment: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmployeeSelectionPage(
                                      barberId: barber.id,
                                      barberName: barber.name,
                                      barberImage: barber.image ?? '',
                                      branch: barber,
                                    ),
                                  ),
                                );
                              },
                              onViewDetails: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BarberDetailPage(
                                      companyId: barber.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        MediaQuery.of(context).padding.top + AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(color: AppColors.background),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.backgroundSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                side: BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'En Yüksek Puanlılar',
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${_topRatedBarbers.length} ${AppLocalizations.of(context)!.barbersFound}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadTopRatedBarbers,
            icon: Icon(Icons.refresh_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Henüz puanlanmış berber yok',
            style: AppTypography.h6.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Yüksek puanlı berberler burada görünecek',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
