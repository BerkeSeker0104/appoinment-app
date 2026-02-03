import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/company_api_service.dart';
import '../../../data/services/appointment_api_service.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/appointment_model.dart';
import '../../widgets/barber_card.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/category_item.dart';
import '../../widgets/announcement_ribbon.dart';
import '../../providers/company_type_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/message_provider.dart';
import '../../widgets/notification_badge.dart';
import 'barber_detail_page.dart';
import 'service_selection_page.dart';
import 'employee_selection_page.dart';
import 'top_rated_barbers_page.dart';
import 'nearby_barbers_page.dart';
import 'messages/messages_list_page.dart';
import 'customer_appointment_detail_page.dart';
import 'favorites_page.dart';
import 'customer_notifications_page.dart';
import 'customer_main_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());
  final LocationService _locationService = LocationService();
  final CompanyApiService _companyService = CompanyApiService();
  final AppointmentApiService _appointmentService = AppointmentApiService();

  // Home search
  final TextEditingController _homeSearchController = TextEditingController();
  String _homeSearchQuery = '';
  Timer? _homeSearchDebounce;

  bool _matchesQuery(BranchModel b) {
    if (_homeSearchQuery.isEmpty) return true;
    final q = _homeSearchQuery.toLowerCase();
    return b.name.toLowerCase().contains(q) ||
        b.address.toLowerCase().contains(q);
  }

  List<BranchModel> _applyQuery(List<BranchModel> list) {
    if (_homeSearchQuery.isEmpty) return list;
    return list.where(_matchesQuery).toList();
  }

  // Location variables - used for background functionality (finding nearby barbers)
  // ignore: unused_field
  String _locationText = 'Konum alınıyor...';
  // ignore: unused_field
  bool _isLoadingLocation = true;
  bool _isLoadingAppointments = true;
  bool _isLoadingNearby = true;
  bool _isLoadingTopRated = true;

  List<AppointmentModel> _upcomingAppointments = [];
  List<BranchModel> _nearbyBarbers = [];
  List<BranchModel> _topRatedBarbers = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadLocation();
    _loadAppointments();
    _loadCompanies();

    // Load announcements when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementProvider>().loadAnnouncements();
      // Load notification count
      context.read<NotificationProvider>().loadUnreadCount();
      // Start message auto-refresh
      context.read<MessageProvider>().startAutoRefresh();
      // Load favorites
      context.read<FavoriteProvider>().loadFavorites();
    });
  }

  Future<void> _loadUser() async {
    await _authUseCases.getCurrentUser();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _homeSearchDebounce?.cancel();
    _homeSearchController.dispose();
    // Stop message auto-refresh
    try {
      if (mounted) {
        context.read<MessageProvider>().stopAutoRefresh();
      }
    } catch (e) {
      // Dispose sırasında hata olursa ignore et
    }
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      setState(() => _isLoadingLocation = true);

      // Check if location permission is available before trying to get location
      final hasPermission = await _locationService.hasLocationPermission();

      if (!hasPermission) {
        // Permission not granted, show appropriate message
        if (!mounted) return;
        setState(() {
          _locationText = 'Konum izni gerekli';
          _isLoadingLocation = false;
        });
        return;
      }

      final shortAddress = await _locationService.getShortAddress();

      if (!mounted) return;
      setState(() {
        _locationText = shortAddress ?? 'Konum bulunamadı';
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationText = 'Konum alınamadı';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadAppointments() async {
    try {
      setState(() => _isLoadingAppointments = true);
      final appointments = await _appointmentService.getAppointments();

      if (!mounted) return;
      setState(() {
        // Yaklaşan randevular: sadece gelecekteki tarihler ve aktif statuslar
        final now = DateTime.now();
        _upcomingAppointments = appointments.where(
          (a) {
            // Status kontrolü
            final isActiveStatus = a.status == AppointmentStatus.pending ||
                a.status == AppointmentStatus.confirmed ||
                a.status == AppointmentStatus.inProgress;

            if (!isActiveStatus) return false;

            // Tarih kontrolü - randevu tarihi bugünden sonra olmalı
            try {
              final appointmentDate = DateTime.parse(a.startDate);
              final today = DateTime(now.year, now.month, now.day);
              final appointmentDay = DateTime(appointmentDate.year,
                  appointmentDate.month, appointmentDate.day);

              // Randevu tarihi bugün veya gelecekte olmalı
              return appointmentDay.isAtSameMomentAs(today) ||
                  appointmentDay.isAfter(today);
            } catch (e) {
              // Tarih parse edilemezse güvenli tarafta kal ve göster
              return true;
            }
          },
        ).toList();
        _isLoadingAppointments = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAppointments = false);
    }
  }

  Future<void> _loadCompanies({String? selectedCategoryId}) async {
    // Load nearby and top rated in parallel
    _loadNearbyBarbers(selectedCategoryId: selectedCategoryId);
    _loadTopRatedBarbers(selectedCategoryId: selectedCategoryId);
  }

  Future<void> _loadNearbyBarbers({String? selectedCategoryId}) async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingNearby = true);

      // Check if location permission is available
      final hasLocationPermission =
          await _locationService.hasLocationPermission();
      
      // Try to use last known position first for speed, otherwise get current
      var position = await _locationService.getCachedLocation();
      if (position == null && hasLocationPermission) {
        position = await _locationService.getCurrentLocation();
      }

      List<BranchModel> nearby;
      if (selectedCategoryId != null) {
        // Filter by category
        nearby = await _companyService.getCompaniesByType(selectedCategoryId);
        // Apply location filtering if position available
        if (position != null) {
          nearby = nearby.where((company) {
            if (company.latitude == null || company.longitude == null)
              return false;
            final distance = _locationService.calculateDistance(
              position!.latitude,
              position.longitude,
              company.latitude!,
              company.longitude!,
            );
            return distance <= 10; // 10km radius
          }).toList();
          // Sort by distance
          nearby.sort((a, b) {
            final distanceA = _locationService.calculateDistance(
              position!.latitude,
              position.longitude,
              a.latitude!,
              a.longitude!,
            );
            final distanceB = _locationService.calculateDistance(
              position.latitude,
              position.longitude,
              b.latitude!,
              b.longitude!,
            );
            return distanceA.compareTo(distanceB);
          });
        }
      } else if (position != null) {
        nearby = await _companyService.getNearbyCompanies(
          position.latitude,
          position.longitude,
          radiusKm: 10,
        );
      } else {
        // No location permission or position, just show all companies
        nearby = await _companyService.getCompanies();
      }

      if (!mounted) return;
      setState(() {
        _nearbyBarbers = nearby.take(10).toList();
        _isLoadingNearby = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingNearby = false);
    }
  }

  Future<void> _loadTopRatedBarbers({String? selectedCategoryId}) async {
    try {
      if (!mounted) return;
      setState(() => _isLoadingTopRated = true);

      List<BranchModel> topRated;
      if (selectedCategoryId != null) {
        topRated = await _companyService.getCompaniesByType(selectedCategoryId);
        // Sort by rating when filtering by category
        topRated.sort((a, b) {
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
      } else {
        topRated = await _companyService.getTopRatedCompanies(limit: 10);
      }

      if (!mounted) return;
      setState(() {
        _topRatedBarbers = topRated.take(10).toList();
        _isLoadingTopRated = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingTopRated = false);
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
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadLocation(),
            _loadAppointments(),
            _loadCompanies(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.lg),

              // Announcements Ribbon
              const AnnouncementRibbon(),
              const SizedBox(height: AppSpacing.lg),

              // Global empty state when searching and no section has any match
              if (_homeSearchQuery.isNotEmpty &&
                  !_nearbyBarbers.any(_matchesQuery) &&
                  !_topRatedBarbers.any(_matchesQuery) &&
                  !context
                      .read<FavoriteProvider>()
                      .favoriteCompanies
                      .any(_matchesQuery))
                _buildEmptyState(AppLocalizations.of(context)!.noResults),

              // Categories Section
              _buildCategoriesSection(),
              const SizedBox(height: AppSpacing.lg),

              // Favori İşletmelerim Section
              _buildFavoritesSection(),
              const SizedBox(height: AppSpacing.xxxl),

              // 1. Yakınındaki Berberler (ÜST)
              _buildNearbySection(),
              const SizedBox(height: AppSpacing.lg),
              _buildBarberList(),
              const SizedBox(height: AppSpacing.xxxl),

              // 2. En Yüksek Puanlılar
              _buildTopRatedSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildTopRatedList(),
              const SizedBox(height: AppSpacing.xxxl),

              // 3. Yaklaşan Randevular (varsa) - search aktifken gizle
              if (_homeSearchQuery.isEmpty &&
                  _upcomingAppointments.isNotEmpty) ...[
                _buildUpcomingAppointmentsSection(),
                const SizedBox(height: AppSpacing.xxxl),
              ],

              SizedBox(height: 100 + MediaQuery.of(context).viewInsets.bottom),
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
        MediaQuery.of(context).padding.top + AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Row(
        children: [
          // Search bar (inline active)
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _homeSearchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        if (_homeSearchDebounce?.isActive ?? false) {
                          _homeSearchDebounce!.cancel();
                        }
                        _homeSearchDebounce = Timer(
                          const Duration(milliseconds: 300),
                          () {
                            setState(() {
                              _homeSearchQuery = value.trim();
                            });
                          },
                        );
                      },
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchBarberPlaceholder,
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        suffixIcon: _homeSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: AppColors.textSecondary, size: 18),
                                onPressed: () {
                                  _homeSearchController.clear();
                                  setState(() {
                                    _homeSearchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Message button with badge
          Consumer<MessageProvider>(
            builder: (context, messageProvider, _) {
              final unreadCount = messageProvider.getUnreadCount();
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background, // same as app background
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagesListPage(),
                      ),
                    );
                  },
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: NotificationBadge(
                            count: unreadCount,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          // Notification button with badge
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerNotificationsPage(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.background, // same as app background
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: NotificationBadge(
                            count: notificationProvider.unreadCount,
                            size: 16,
                            backgroundColor: AppColors.error,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.upcomingAppointments,
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  CustomerMainPage.navigateToAppointmentsTab(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.seeAll,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _isLoadingAppointments
            ? _buildLoadingCard()
            : _upcomingAppointments.isEmpty
                ? _buildEmptyState(AppLocalizations.of(context)!.noAppointments)
                : SizedBox(
                    height: 370, // Updated to match new card height (360 + padding)
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      itemCount: _upcomingAppointments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final appointment = _upcomingAppointments[index];
                        return SizedBox(
                          width: 300, // Adjust width as needed
                          child: AppointmentCard(
                            appointment: appointment,
                            type: AppointmentCardType.upcoming,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerAppointmentDetailPage(
                                    appointment: appointment,
                                  ),
                                ),
                              );
                            },
                            onCancel: () => _cancelAppointment(appointment),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }

  Widget _buildNearbySection() {
    // If searching and no nearby results, hide the entire section
    final hasResults =
        _homeSearchQuery.isEmpty || _nearbyBarbers.any(_matchesQuery);
    if (!hasResults) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                    Icons.location_on,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${_nearbyBarbers.length} ${AppLocalizations.of(context)!.barbersFound}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NearbyBarbersPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Tümünü Gör',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarberList() {
    if (_isLoadingNearby) {
      return SizedBox(
        height: 300,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          itemCount: 3, // Placeholder for loading
          separatorBuilder: (context, index) =>
              const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, index) {
            return _buildLoadingCard();
          },
        ),
      );
    }

    // Apply search filter (name/address)
    final filtered = _applyQuery(_nearbyBarbers);

    if (filtered.isEmpty) {
      return _buildEmptyState(AppLocalizations.of(context)!.errorBarbersLoad);
    }

    return SizedBox(
      height: 300, // Updated to match new card height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        itemCount: filtered.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final barber = filtered[index];
          return BarberCard(
            barber: barber,
            distance: _calculateDistance(barber),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BarberDetailPage(companyId: barber.id),
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
                  builder: (context) => BarberDetailPage(companyId: barber.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopRatedSection() {
    // Hide section when searching and no matches
    final hasResults =
        _homeSearchQuery.isEmpty || _topRatedBarbers.any(_matchesQuery);
    if (!hasResults) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.topRatedBarbers,
            style: AppTypography.h5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TopRatedBarbersPage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Tümünü Gör',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRatedList() {
    if (_isLoadingTopRated) {
      return Container(
        height: 300,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = _applyQuery(_topRatedBarbers);

    if (filtered.isEmpty) {
      return _buildEmptyState('Henüz yüksek puanlı işletme bulunamadı.');
    }

    return SizedBox(
      height: 300, // Updated to match new card height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        itemCount: filtered.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final barber = filtered[index];
          return BarberCard(
            barber: barber,
            distance: _calculateDistance(barber),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BarberDetailPage(companyId: barber.id),
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
                  builder: (context) => BarberDetailPage(companyId: barber.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text(
          AppLocalizations.of(context)!.cancelAppointment,
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.cancelAppointmentConfirm,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.companyName ?? AppLocalizations.of(context)!.barberDefaultName,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_formatDate(appointment.startDate)} • ${appointment.startHour}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                AppLocalizations.of(context)!.cancelButton,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      await _appointmentService.cancelAppointment(appointment.id);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Update local state
      setState(() {
        _upcomingAppointments.removeWhere((a) => a.id == appointment.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.appointmentCancelled,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          icon: Icon(Icons.error_outline, color: AppColors.error, size: 48),
          title: Text(
            AppLocalizations.of(context)!.cancelFailed,
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
          ),
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  AppLocalizations.of(context)!.ok,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final l10n = AppLocalizations.of(context)!;
      final months = [
        l10n.january,
        l10n.february,
        l10n.march,
        l10n.april,
        l10n.may,
        l10n.june,
        l10n.july,
        l10n.august,
        l10n.september,
        l10n.october,
        l10n.november,
        l10n.december
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildCategoriesSection() {
    return Consumer<CompanyTypeProvider>(
      builder: (context, companyTypeProvider, child) {
        // Load categories on first build
        if (companyTypeProvider.companyTypes.isEmpty &&
            !companyTypeProvider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            companyTypeProvider.loadCompanyTypes();
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories list (title removed per design)
            if (companyTypeProvider.isLoading)
              _buildCategoriesLoading()
            else if (companyTypeProvider.error != null)
              _buildCategoriesError(companyTypeProvider.error!)
            else
              _buildCategoriesList(companyTypeProvider),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesLoading() {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 68,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                // label placeholder removed
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesError(String error) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Kategoriler yüklenemedi',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(CompanyTypeProvider provider) {
    final categories = provider.companyTypes;

    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
        itemCount: categories.length, // Removed +1 for "All" option
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryItem(
            id: category.id,
            name: category.name,
            imageUrl: category.fullImageUrl,
            isSelected: provider.isCategorySelected(category.id),
            onTap: () {
              provider.selectCategory(category.id);
              _loadCompanies(selectedCategoryId: category.id);
            },
          );
        },
      ),
    );
  }

  List<BranchModel> _filterCompaniesByCategory(
    List<BranchModel> companies,
    String? selectedCategoryId,
  ) {
    if (selectedCategoryId == null) return companies;
    return companies
        .where((company) => company.typeId == selectedCategoryId)
        .toList();
  }

  Widget _buildFavoritesSection() {
    return Consumer2<FavoriteProvider, CompanyTypeProvider>(
      builder: (context, favoriteProvider, companyTypeProvider, child) {
        final favoriteCompanies = favoriteProvider.favoriteCompanies;
        final selectedCategoryId = companyTypeProvider.selectedCategoryId;

        // Filter favorites by selected category
        final filteredFavorites = _filterCompaniesByCategory(
          favoriteCompanies,
          selectedCategoryId,
        );

        // Apply search filtering
        final searchFiltered = _applyQuery(filteredFavorites);

        // Only show section if there are filtered favorites
        if (searchFiltered.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.favoriteCompanies,
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: _navigateToFavoritesTab,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Tümünü Gör',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 300,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                itemCount: filteredFavorites.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final company = searchFiltered[index];
                  return BarberCard(
                    barber: company,
                    distance: _calculateDistance(company),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BarberDetailPage(companyId: company.id),
                        ),
                      );
                    },
                    onBookAppointment: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeSelectionPage(
                            barberId: company.id,
                            barberName: company.name,
                            barberImage: company.image ?? '',
                            branch: company,
                          ),
                        ),
                      );
                    },
                    onViewDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BarberDetailPage(companyId: company.id),
                        ),
                      );
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

  void _navigateToFavoritesTab() {
    // Navigate directly to FavoritesPage from home page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesPage(fromHome: true),
      ),
    );
  }
}
