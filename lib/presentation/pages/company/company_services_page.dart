import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/company_service_model.dart';
import '../../../domain/usecases/company_service_usecases.dart';
import '../../../data/repositories/company_service_repository_impl.dart';
import 'edit_company_service_page.dart';

class CompanyServicesPage extends StatefulWidget {
  const CompanyServicesPage({Key? key}) : super(key: key);

  @override
  State<CompanyServicesPage> createState() => _CompanyServicesPageState();
}

class _CompanyServicesPageState extends State<CompanyServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  final CompanyServiceUseCases _companyServiceUseCases = CompanyServiceUseCases(
    CompanyServiceRepositoryImpl(),
  );
  List<CompanyServiceModel> _companyServices = [];
  List<CompanyServiceModel> _filteredCompanyServices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCompanyServices();
    // Search controller listener for clear button visibility
    _searchController.addListener(() {
      setState(() {}); // Rebuild to show/hide clear button
    });
  }

  Future<void> _loadCompanyServices() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final services = await _companyServiceUseCases.getCompanyServices();

      setState(() {
        _companyServices = services;
        _filteredCompanyServices = services;
        _isLoading = false;
      });
    } catch (e) {
      // If error, show empty state instead of error message
      setState(() {
        _companyServices = [];
        _filteredCompanyServices = [];
        _isLoading = false;
        // Only show error for non-404 errors
        if (!e.toString().toLowerCase().contains('404')) {
          _errorMessage = e.toString();
        }
      });
    }
  }

  void _filterCompanyServices(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCompanyServices = _companyServices;
      } else {
        _filteredCompanyServices = _companyServices.where((service) {
          final serviceName = service.serviceName?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return serviceName.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _buildCompanyServicesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      margin: const EdgeInsets.only(
        top: AppSpacing.screenHorizontal,
        bottom: AppSpacing.lg,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, animationValue, child) {
          return Transform.translate(
            offset: Offset(0, 10 * (1 - animationValue)),
            child: Opacity(
              opacity: animationValue,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterCompanyServices,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.serviceNameSearch,
                    hintStyle: AppTypography.body1.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textTertiary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppColors.textTertiary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterCompanyServices('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocalizations.of(context)!.servicesLoadError,
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _errorMessage ?? AppLocalizations.of(context)!.unknownError,
            style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadCompanyServices,
            child: Text(
              AppLocalizations.of(context)!.retry,
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyServicesList() {
    if (_filteredCompanyServices.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadCompanyServices,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.screenHorizontal,
          AppSpacing.screenHorizontal,
          AppSpacing.screenHorizontal +
              AppSpacing.navigationBarHeight +
              AppSpacing.lg,
        ),
        itemCount: _filteredCompanyServices.length,
        itemBuilder: (context, index) {
          final service = _filteredCompanyServices[index];
          return _buildCompanyServiceCard(service);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    // Check if empty because of search filter
    final isSearchActive = _searchController.text.isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surface, AppColors.backgroundSecondary],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                border: Border.all(color: AppColors.border, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSearchActive
                            ? [
                                AppColors.textTertiary.withValues(alpha: 0.1),
                                AppColors.textQuaternary.withValues(alpha: 0.05),
                              ]
                            : [
                                AppColors.primary.withValues(alpha: 0.1),
                                AppColors.primaryLight.withValues(alpha: 0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                    ),
                    child: Icon(
                      isSearchActive
                          ? Icons.search_off
                          : Icons.business_center_outlined,
                      size: AppSpacing.iconHuge,
                      color: isSearchActive
                          ? AppColors.textTertiary.withValues(alpha: 0.6)
                          : AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    isSearchActive
                        ? AppLocalizations.of(context)!.serviceNotFound
                        : 'Henüz hizmet eklenmemiş',
                    style: AppTypography.h5.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isSearchActive
                        ? 'Arama kriterlerinize uygun hizmet bulunamadı'
                        : 'İlk hizmetinizi eklemek için + butonuna tıklayın',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isSearchActive) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Text(
                        'Hemen Başla',
                        style: AppTypography.body2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompanyServiceCard(CompanyServiceModel service) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue.clamp(0.0, 1.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surface, AppColors.backgroundSecondary],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _editCompanyService(service),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        // Service icon with gradient (48x48)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.content_cut,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Content section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title Row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      service.serviceName ??
                                          'Hizmet #${service.serviceId}',
                                      style: AppTypography.body1.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  // Compact edit button
                                  GestureDetector(
                                    onTap: () => _editCompanyService(service),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              // Info Row (inline badges)
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  // Firma badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.business,
                                          size: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${service.companyIds.length} firma',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Price badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.attach_money,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          service.priceDisplay,
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Duration badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryLight,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          service.durationDisplay,
                                          style: AppTypography.caption.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _editCompanyService(CompanyServiceModel service) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCompanyServicePage(companyService: service),
      ),
    );
    if (result == true) {
      _loadCompanyServices(); // Refresh list
    }
  }
}
