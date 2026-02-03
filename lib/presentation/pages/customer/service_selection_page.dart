import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/services/company_service_api_service.dart';
import '../../widgets/premium_button.dart';
import '../auth/phone_login_page.dart';
import '../auth/sign_up_page.dart';
import 'appointment_booking_page.dart';
import '../../../data/models/company_user_model.dart';

class ServiceSelectionPage extends StatefulWidget {
  final String barberId;
  final String barberName;
  final String barberImage;
  final BranchModel? branch; // Branch bilgisi - çalışma saatleri için

  const ServiceSelectionPage({
    super.key,
    required this.barberId,
    required this.barberName,
    required this.barberImage,
    this.branch, // Optional - eğer geçilmezse AppointmentBookingPage'de yüklenecek
    this.selectedEmployee,
  });

  final CompanyUserModel? selectedEmployee;

  @override
  State<ServiceSelectionPage> createState() => _ServiceSelectionPageState();
}

class _ServiceSelectionPageState extends State<ServiceSelectionPage> {
  final CompanyServiceApiService _companyServiceService =
      CompanyServiceApiService();
  final Set<String> _selectedServiceIds = {};
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('ServiceSelectionPage: selectedEmployee = ${widget.selectedEmployee?.userId ?? "NULL"}');
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      setState(() => _isLoading = true);

      // Fetch services from backend
      final companyServices = await _companyServiceService
          .getCompanyServicesByCompanyId(widget.barberId);

      // Convert CompanyServiceModel to ServiceModel
      final services = companyServices.map((companyService) {
        return ServiceModel(
          id: companyService.serviceId, // Use serviceId for display
          name: companyService.serviceName ?? 'Hizmet',
          description: '',
          price: companyService.minPrice,
          durationMinutes: companyService.duration,
          iconName: 'content_cut', // Default icon
          barberId: widget.barberId,
          companyServiceId: companyService.id, // Store company-service ID for appointment creation
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hizmetler yüklenirken hata oluştu: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  double get _totalPrice => _services
      .where((service) => _selectedServiceIds.contains(service.id))
      .fold(0.0, (sum, service) => sum + service.price);

  int get _totalDuration => _services
      .where((service) => _selectedServiceIds.contains(service.id))
      .fold(0, (sum, service) => sum + service.durationMinutes);

  List<ServiceModel> get _selectedServices => _services
      .where((service) => _selectedServiceIds.contains(service.id))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _services.isEmpty
                      ? _buildEmptyState()
                      : CustomScrollView(
                          slivers: [
                            _buildBarberInfo(),
                            _buildServicesList(),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 120),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      bottomSheet: _selectedServiceIds.isNotEmpty ? _buildBottomSheet() : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hizmet Seçimi',
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Almak istediğiniz hizmetleri seçin',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarberInfo() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: widget.barberImage.isNotEmpty
                  ? Image.network(
                      widget.barberImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.barberName,
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${_services.length} hizmet mevcut',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Icon(Icons.store, size: 30, color: AppColors.textTertiary),
    );
  }

  Widget _buildServicesList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final service = _services[index];
        final isSelected = _selectedServiceIds.contains(service.id);

        return Container(
          margin: EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            index == 0 ? AppSpacing.lg : AppSpacing.xs,
            AppSpacing.screenHorizontal,
            index == _services.length - 1 ? AppSpacing.lg : AppSpacing.xs,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedServiceIds.remove(service.id);
                  } else {
                    _selectedServiceIds.add(service.id);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color:
                              isSelected ? AppColors.primary : AppColors.border,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${service.durationMinutes} ${AppLocalizations.of(context)!.minuteShort}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₺${_formatPrice(service.price)}',
                      style: AppTypography.h6.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }, childCount: _services.length),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_selectedServiceIds.length} Hizmet Seçildi',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        '₺${_formatPrice(_totalPrice)}',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '$_totalDuration dk',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumButton(
            text: 'Devam Et',
            onPressed: () => _handleContinue(),
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
          Icon(Icons.content_cut, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)!.noServicesYet,
            style: AppTypography.h5.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)!.noServicesMessage,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    // Eğer fiyat 0 ise "Ücretsiz" göster
    if (price == 0.0) {
      return AppLocalizations.of(context)!.free;
    }

    // Ondalık kısmı kontrol et
    if (price == price.toInt().toDouble()) {
      // Tam sayı ise ondalık kısmı gösterme
      return price.toInt().toString();
    } else {
      // Ondalık sayı ise 2 basamak göster
      return price.toStringAsFixed(2);
    }
  }

  Future<void> _handleContinue() async {
    // Check if user is guest
    final apiClient = ApiClient();
    final token = await apiClient.getToken();

    if (token == null) {
      // Show dialog for guest users
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            l10n.mustSignUpFirst,
            style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
          ),
          content: Text(
            'Randevu almak için önce üye olmanız gerekiyor.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: AppTypography.buttonMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PhoneLoginPage()),
                );
              },
              child: Text(
                l10n.signIn,
                style: AppTypography.buttonMedium.copyWith(color: AppColors.primary),
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
                style: AppTypography.buttonMedium.copyWith(color: AppColors.secondary),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to appointment booking page
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentBookingPage(
          barberId: widget.barberId,
          barberName: widget.barberName,
          barberImage: widget.barberImage,
          selectedServices: _selectedServices,
          totalPrice: _totalPrice,
          totalDuration: _totalDuration,
          branch: widget.branch, // Branch bilgisini geçir
          selectedEmployee: widget.selectedEmployee,
        ),
      ),
    );
  }
}
