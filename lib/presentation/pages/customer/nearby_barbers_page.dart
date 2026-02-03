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
import 'customer_main_page.dart';

class NearbyBarbersPage extends StatefulWidget {
  const NearbyBarbersPage({super.key});

  @override
  State<NearbyBarbersPage> createState() => _NearbyBarbersPageState();
}

class _NearbyBarbersPageState extends State<NearbyBarbersPage> {
  final LocationService _locationService = LocationService();
  final CompanyApiService _companyService = CompanyApiService();

  bool _isLoading = true;
  List<BranchModel> _nearbyBarbers = [];

  @override
  void initState() {
    super.initState();
    _loadNearbyBarbers();
  }

  Future<void> _loadNearbyBarbers() async {
    try {
      setState(() => _isLoading = true);

      // Get user's current location
      final position = await _locationService.getCurrentLocation();

      List<BranchModel> barbers;

      if (position != null) {
        // Get nearby barbers within 20km radius
        barbers = await _companyService.getNearbyCompanies(
          position.latitude,
          position.longitude,
          radiusKm: 20,
        );

        // Sort by distance (closest first)
        barbers.sort((a, b) {
          final distanceA = _calculateDistance(a);
          final distanceB = _calculateDistance(b);

          // Handle null distances (put them at the end)
          if (distanceA == null && distanceB == null) return 0;
          if (distanceA == null) return 1;
          if (distanceB == null) return -1;

          return distanceA.compareTo(distanceB);
        });
      } else {
        // If no location, get all companies
        barbers = await _companyService.getCompanies();
      }

      if (!mounted) return;
      setState(() {
        _nearbyBarbers = barbers;
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

  void _navigateToMap() {
    // Ana sayfaya dön ve harita sekmesini aktif et
    Navigator.popUntil(context, (route) => route.isFirst);
    // CustomerMainPage'i harita sekmesi ile yeniden oluştur
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerMainPage(initialTab: 1),
      ),
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
                : _nearbyBarbers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNearbyBarbers,
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
                          itemCount: _nearbyBarbers.length,
                          itemBuilder: (context, index) {
                            final barber = _nearbyBarbers[index];
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
                  AppLocalizations.of(context)!.nearbyBarbers,
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
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${_nearbyBarbers.length} ${AppLocalizations.of(context)!.barbersFound}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Map navigation button
          IconButton(
            onPressed: _navigateToMap,
            icon: Icon(
              Icons.map_rounded,
              color: AppColors.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.backgroundSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                side: BorderSide(color: AppColors.border),
              ),
            ),
            tooltip: 'Haritada Gör',
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
            Icons.location_off_rounded,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Yakınınızda berber bulunamadı',
            style: AppTypography.h6.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Harita sayfasından daha geniş alanda arama yapabilirsiniz',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _navigateToMap,
            icon: Icon(Icons.map_rounded),
            label: Text('Haritada Ara'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
