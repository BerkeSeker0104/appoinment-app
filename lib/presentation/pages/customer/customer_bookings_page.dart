import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/api_client.dart';
import '../../../data/models/appointment_model.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/guest_auth_overlay.dart';
import '../../../domain/usecases/appointment_usecases.dart';
import '../../../data/repositories/appointment_repository_impl.dart';
import '../../../data/services/company_api_service.dart';
import '../../../domain/usecases/comment_usecases.dart';
import '../../../data/repositories/comment_repository_impl.dart';
import 'rating_page.dart';
import 'customer_appointment_detail_page.dart';
import '../../../l10n/app_localizations.dart';

class CustomerBookingsPage extends StatefulWidget {
  final int initialTab;

  const CustomerBookingsPage({super.key, this.initialTab = 0});

  @override
  State<CustomerBookingsPage> createState() => _CustomerBookingsPageState();
}

class _CustomerBookingsPageState extends State<CustomerBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentUseCases _appointmentUseCases =
      AppointmentUseCases(AppointmentRepositoryImpl());
  final CommentUseCases _commentUseCases =
      CommentUseCases(CommentRepositoryImpl());

  bool _isLoading = true;
  List<AppointmentModel> _upcomingAppointments = [];
  List<AppointmentModel> _pastAppointments = [];
  List<AppointmentModel> _cancelledAppointments = [];
  Set<String> _appointmentsWithComments = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    // Check if user is guest - don't load appointments for guests
    final apiClient = ApiClient();
    final token = await apiClient.getToken();
    if (token == null) {
      // Guest user - don't show error, overlay will handle it
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _upcomingAppointments = [];
        _pastAppointments = [];
        _cancelledAppointments = [];
      });
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Fetch appointments with timeout to prevent indefinite loading
      var appointments = await _appointmentUseCases
          .fetchAppointments()
          .timeout(const Duration(seconds: 15));

      // İlk aşama: Mevcut verilerle listeleri oluştur ve göster
      _processAppointments(appointments);
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      // İkinci aşama: Eksik işletme isimlerini arka planda tamamla (non-blocking)
      _fetchMissingCompanyNames(appointments).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('CustomerBookings: Company names fetch timeout');
          }
        },
      ).catchError((e) {
        if (kDebugMode) {
          debugPrint('CustomerBookings: Company names fetch error: $e');
        }
      });

      // Üçüncü aşama: Tamamlanan randevular için yorum kontrolü yap (non-blocking)
      _checkCommentsForCompletedAppointments(appointments).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('CustomerBookings: Comments check timeout');
          }
        },
      ).catchError((e) {
        if (kDebugMode) {
          debugPrint('CustomerBookings: Comments check error: $e');
        }
      });

    } catch (e) {
      if (!mounted) return;

      // Check if error is due to unauthorized (guest user)
      final errorString = e.toString().toLowerCase();
      final isUnauthorized = errorString.contains('unauthorized') ||
          errorString.contains('401') ||
          errorString.contains('yetkisiz');

      // Don't show error for guest users - overlay will handle it
      if (isUnauthorized) {
        setState(() {
          _isLoading = false;
          _upcomingAppointments = [];
          _pastAppointments = [];
          _cancelledAppointments = [];
        });
        return;
      }

      setState(() => _isLoading = false);

      // Only show error for logged-in users with actual errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.appointmentsLoadError}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GuestAuthOverlay(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            AppLocalizations.of(context)!.appointmentsLoading,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            AppLocalizations.of(context)!.pleaseWait,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildUpcomingBookings(),
                        _buildPastBookings(),
                        _buildCancelledBookings(),
                      ],
                    ),
            ),
          ],
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
      decoration: const BoxDecoration(color: AppColors.background),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.myAppointments,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context)!.manageAllAppointments,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadAppointments,
            icon: Icon(Icons.refresh_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.bodyMedium,
        tabs: [
          Tab(text: '${AppLocalizations.of(context)!.upcoming} (${_upcomingAppointments.length})'),
          Tab(text: '${AppLocalizations.of(context)!.past} (${_pastAppointments.length})'),
          Tab(text: '${AppLocalizations.of(context)!.cancelled} (${_cancelledAppointments.length})'),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    if (_upcomingAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available_rounded,
        title: AppLocalizations.of(context)!.noUpcomingAppointments,
        subtitle: AppLocalizations.of(context)!.createNewAppointment,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.separated(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          top: AppSpacing.screenHorizontal,
          bottom: 100, // Bottom navigation bar
        ),
        itemCount: _upcomingAppointments.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final appointment = _upcomingAppointments[index];
          return AppointmentCard(
            appointment: appointment,
            type: AppointmentCardType.upcoming,
            onTap: () => _navigateToAppointmentDetail(appointment),
            onCancel: () => _cancelAppointment(appointment),
          );
        },
      ),
    );
  }

  Widget _buildPastBookings() {
    if (_pastAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: AppLocalizations.of(context)!.noPastAppointments,
        subtitle: AppLocalizations.of(context)!.completedAppointmentsWillAppearHere,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.separated(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          top: AppSpacing.screenHorizontal,
          bottom: 100, // Bottom navigation bar
        ),
        itemCount: _pastAppointments.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final appointment = _pastAppointments[index];
          final hasRated = _appointmentsWithComments.contains(appointment.id);
          return AppointmentCard(
            appointment: appointment,
            type: AppointmentCardType.past,
            onTap: () => _navigateToAppointmentDetail(appointment),
            hasRated: hasRated,
            onRate: appointment.status == AppointmentStatus.completed &&
                    !hasRated
                ? () => _openRating(appointment)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildCancelledBookings() {
    if (_cancelledAppointments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_rounded,
        title: AppLocalizations.of(context)!.noCancelledAppointments,
        subtitle: AppLocalizations.of(context)!.cancelledAppointmentsWillAppearHere,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.separated(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          top: AppSpacing.screenHorizontal,
          bottom: 100, // Bottom navigation bar
        ),
        itemCount: _cancelledAppointments.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final appointment = _cancelledAppointments[index];
          return AppointmentCard(
            appointment: appointment,
            type: AppointmentCardType.cancelled,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _navigateToAppointmentDetail(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerAppointmentDetailPage(
          appointment: appointment,
        ),
      ),
    ).then((_) {
      // Refresh appointments when returning from detail page
      _loadAppointments();
    });
  }

  Future<void> _openRating(AppointmentModel appointment) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RatingPage(
          barberName: appointment.companyName ?? 'İşletme',
          serviceName: appointment.services.isNotEmpty
              ? appointment.services.first.name
              : 'Hizmet',
          appointmentId: appointment.id,
        ),
      ),
    );

    if (result == true) {
      // Yorum yapıldı, bu randevuyu yorumlu randevular listesine ekle
      setState(() {
        _appointmentsWithComments.add(appointment.id);
      });
      
      await _loadAppointments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.thankYouForRating,
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
    }
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
                    appointment.companyName ?? 'İşletme',
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
                AppLocalizations.of(context)!.cancelAppointment,
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
      await _appointmentUseCases.cancelAppointment(appointment.id);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.appointmentCancelledSuccess,
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

      // Update local state instead of reloading all appointments
      setState(() {
        // Remove from upcoming or past appointments using immutable updates
        _upcomingAppointments = List.of(_upcomingAppointments)
          ..removeWhere((a) => a.id == appointment.id);
        _pastAppointments = List.of(_pastAppointments)
          ..removeWhere((a) => a.id == appointment.id);

        // Add to cancelled appointments with updated status
        final cancelledAppointment = appointment.copyWith(
          status: AppointmentStatus.cancelled,
          updatedAt: DateTime.now(),
        );
        
        // Use immutable update for cancelled list too
        _cancelledAppointments = List.of(_cancelledAppointments)
          ..insert(0, cancelledAppointment);
      });
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Ocak',
        'Şubat',
        'Mart',
        'Nisan',
        'Mayıs',
        'Haziran',
        'Temmuz',
        'Ağustos',
        'Eylül',
        'Ekim',
        'Kasım',
        'Aralık',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _processAppointments(List<AppointmentModel> appointments) {
    final now = DateTime.now();

    // Categorize appointments
    final upcoming = <AppointmentModel>[];
    final past = <AppointmentModel>[];
    final cancelled = <AppointmentModel>[];

    for (final appointment in appointments) {
      if (appointment.status == AppointmentStatus.cancelled) {
        cancelled.add(appointment);
      } else {
        try {
          final appointmentDate = DateTime.parse(appointment.startDate);

          // Tamamlanmış veya geçmiş tarihli randevular geçmişe
          if (appointment.status == AppointmentStatus.completed) {
            past.add(appointment);
          } else if (appointmentDate.isBefore(now) && 
                     !appointmentDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
             // Sadece bugünden öncekileri geçmişe at, bugünküler yaklaşanlarda kalsın
             past.add(appointment);
          } else {
            // Gelecek ve bugünkü randevular
            upcoming.add(appointment);
          }
        } catch (e) {
          // If date parsing fails, add to past
          past.add(appointment);
        }
      }
    }

    // Sort by date
    upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
    past.sort((a, b) => b.startDate.compareTo(a.startDate));
    cancelled.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _upcomingAppointments = upcoming;
      _pastAppointments = past;
      _cancelledAppointments = cancelled;
    });
  }

  Future<void> _fetchMissingCompanyNames(List<AppointmentModel> appointments) async {
    final missingCompanyIds = appointments
        .where((a) => a.companyName == null || a.companyName!.isEmpty)
        .map((a) => a.companyId)
        .toSet();

    if (missingCompanyIds.isEmpty) return;

    final companyService = CompanyApiService();
    final companyNames = <String, String>{};

    // İsimleri paralel olarak çek, maksimum süre tanı
    await Future.wait(missingCompanyIds.map((id) async {
      try {
        final company = await companyService.getCompanyById(id).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw Exception('Timeout'),
        );
        companyNames[id] = company.name;
      } catch (_) {
        // Hata durumunda sessiz kal
      }
    }));

    if (!mounted || companyNames.isEmpty) return;

    // Listeleri güncelle
    final updateList = (List<AppointmentModel> list) {
      return list.map((a) {
        if ((a.companyName == null || a.companyName!.isEmpty) &&
            companyNames.containsKey(a.companyId)) {
          return a.copyWith(companyName: companyNames[a.companyId]);
        }
        return a;
      }).toList();
    };

    setState(() {
      _upcomingAppointments = updateList(_upcomingAppointments);
      _pastAppointments = updateList(_pastAppointments);
      _cancelledAppointments = updateList(_cancelledAppointments);
    });
  }

  Future<void> _checkCommentsForCompletedAppointments(
      List<AppointmentModel> appointments) async {
    // Sadece tamamlanan randevuları kontrol et
    final completedAppointments = appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .toList();

    if (completedAppointments.isEmpty) return;

    // Her şirket için yorumları al (tekrar çağrıları önlemek için)
    final companyIds = completedAppointments
        .map((a) => a.companyId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final appointmentsWithComments = <String>{};

    // Her şirket için yorumları çek ve hangi randevuların yorumu olduğunu bul
    await Future.wait(companyIds.map((companyId) async {
      try {
        final comments = await _commentUseCases.fetchCompanyComments(
          companyId: companyId,
          page: 1,
          limit: 100, // Yeterli sayıda yorum al
        );

        // Bu şirkete ait tamamlanan randevuları bul
        final companyAppointments = completedAppointments
            .where((a) => a.companyId == companyId)
            .toList();

        // Her randevu için yorum var mı kontrol et
        for (final appointment in companyAppointments) {
          final hasComment = comments.any(
            (comment) => comment.appointmentId == appointment.id,
          );
          if (hasComment) {
            appointmentsWithComments.add(appointment.id);
          }
        }
      } catch (e) {
        // Hata durumunda sessiz kal, sadece o şirket için kontrol edilemez
      }
    }));

    if (!mounted) return;

    setState(() {
      _appointmentsWithComments = appointmentsWithComments;
    });
  }
}
