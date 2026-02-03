import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/usecases/company_service_usecases.dart';
import '../../../data/repositories/company_service_repository_impl.dart';
import '../../../domain/usecases/branch_usecases.dart';
import '../../../data/repositories/branch_repository_impl.dart';
import '../../../data/services/service_api_service.dart';
import '../../../data/models/company_service_model.dart';
import '../../../data/models/service_model.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/duration_picker_widget.dart';
import '../../../l10n/app_localizations.dart';

enum PriceType { single, range }

class EditCompanyServicePage extends StatefulWidget {
  final CompanyServiceModel companyService;

  const EditCompanyServicePage({super.key, required this.companyService});

  @override
  State<EditCompanyServicePage> createState() => _EditCompanyServicePageState();
}

class _EditCompanyServicePageState extends State<EditCompanyServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  final CompanyServiceUseCases _companyServiceUseCases = CompanyServiceUseCases(
    CompanyServiceRepositoryImpl(),
  );
  final BranchUseCases _branchUseCases = BranchUseCases(BranchRepositoryImpl());
  final ServiceApiService _serviceApiService = ServiceApiService();

  // Companies (branches) - only for display
  // Can contain both int (numeric ID) and String (UUID)
  List<dynamic> _selectedCompanyIds = [];
  bool _isLoadingCompanies = true;
  String? _companyName; // Display only

  // Services
  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  bool _isLoadingServices = true;

  // Price type
  PriceType _priceType = PriceType.single;

  // Duration
  int _durationInMinutes = 30;

  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadCompanies();
    _loadServices();
  }

  void _initializeForm() {
    // Set initial values from existing company service
    // companyIds List<dynamic> olabilir (int veya String), hepsini al
    _selectedCompanyIds = List.from(widget.companyService.companyIds);
    _minPriceController.text = widget.companyService.minPrice.toString();

    if (widget.companyService.maxPrice != null &&
        widget.companyService.maxPrice! > widget.companyService.minPrice) {
      _priceType = PriceType.range;
      _maxPriceController.text = widget.companyService.maxPrice.toString();
    } else {
      _priceType = PriceType.single;
    }

    _durationInMinutes = widget.companyService.duration;
  }

  Future<void> _loadCompanies() async {
    try {
      setState(() => _isLoadingCompanies = true);
      final companies = await _branchUseCases.getBranches();
      
      // Find company name from companyIds
      // companyIds can contain both int (numeric ID) and String (UUID)
      String? companyName;
      if (_selectedCompanyIds.isNotEmpty) {
        final companyId = _selectedCompanyIds.first;
        final company = companies.firstWhere(
          (c) {
            // Try to match by type
            if (companyId is int) {
              // Compare int with int
              final parsedId = int.tryParse(c.id);
              return parsedId != null && parsedId == companyId;
            } else if (companyId is String) {
              // Compare string with string (UUID)
              return c.id == companyId;
            }
            // Fallback: try string comparison
            return c.id == companyId.toString();
          },
          orElse: () => companies.isNotEmpty ? companies.first : throw StateError('No companies available'),
        );
        companyName = company.name;
      }
      
      setState(() {
        _companyName = companyName;
        _isLoadingCompanies = false;
      });
    } catch (e) {
      setState(() => _isLoadingCompanies = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
            '${AppLocalizations.of(context)!.errorLoadingCompanies}: $e',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadServices() async {
    try {
      setState(() => _isLoadingServices = true);
      final services = await _serviceApiService.getServices();
      setState(() {
        _services = services;
        // Set selected service based on widget.companyService.serviceId
        _selectedService = _services.firstWhere(
          (s) => s.id == widget.companyService.serviceId,
          orElse:
              () => _services.isNotEmpty ? _services.first : _services.first,
        );
        _isLoadingServices = false;
      });
    } catch (e) {
      setState(() => _isLoadingServices = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorLoadingServices}: $e',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.editService,
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.error),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.xl),
                _buildCompanySelection(),
                const SizedBox(height: AppSpacing.xl),
                _buildServiceSelection(),
                const SizedBox(height: AppSpacing.xl),
                _buildPriceSection(),
                const SizedBox(height: AppSpacing.xl),
                _buildDurationSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildUpdateButton(),
                const SizedBox(height: AppSpacing.md),
                _buildDeleteButton(),
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.updateServiceInfo,
          style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context)!.updateServiceInfoSubtitle,
          style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCompanySelection() {
    if (_isLoadingCompanies) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.barber, // "Firma" in TR -> "Company" in EN key
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _companyName ?? AppLocalizations.of(context)!.loading,
            style: AppTypography.body1.copyWith(
              color: _companyName != null 
                  ? AppColors.textPrimary 
                  : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSelection() {
    if (_isLoadingServices) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.service,
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _selectedService?.name ??
                widget.companyService.serviceName ??
                '${AppLocalizations.of(context)!.serviceNotFound}',
            style: AppTypography.body1.copyWith(
              color:
                  _selectedService != null ||
                          widget.companyService.serviceName != null
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.price,
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' *',
              style: AppTypography.body2.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Price type selection
        Row(
          children: [
            Expanded(
              child: RadioListTile<PriceType>(
                title: Text(
                  AppLocalizations.of(context)!.singlePrice,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                value: PriceType.single,
                groupValue: _priceType,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (PriceType? value) {
                  setState(() {
                    _priceType = value!;
                    _maxPriceController.clear();
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<PriceType>(
                title: Text(
                  AppLocalizations.of(context)!.priceRange,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                value: PriceType.range,
                groupValue: _priceType,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (PriceType? value) {
                  setState(() {
                    _priceType = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Price inputs
        if (_priceType == PriceType.single) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.priceCurrency,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _minPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '200',
                  hintStyle: AppTypography.body1.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.priceRequired;
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return AppLocalizations.of(context)!.invalidPrice;
                  }
                  return null;
                },
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.minPrice,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _minPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '100',
                        hintStyle: AppTypography.body1.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.error),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.minPriceRequired;
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return AppLocalizations.of(context)!.invalidPrice;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.maxPrice,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _maxPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '200',
                        hintStyle: AppTypography.body1.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          borderSide: BorderSide(color: AppColors.error),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.maxPriceRequired;
                        }
                        final maxPrice = double.tryParse(value);
                        final minPrice = double.tryParse(
                          _minPriceController.text,
                        );
                        if (maxPrice == null || maxPrice <= 0) {
                          return AppLocalizations.of(context)!.invalidPrice;
                        }
                        if (minPrice != null && maxPrice <= minPrice) {
                          return AppLocalizations.of(context)!.maxPriceError;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDurationSection() {
    return DurationPickerWidget(
      initialDurationInMinutes: _durationInMinutes,
      onDurationChanged: (minutes) {
        setState(() {
          _durationInMinutes = minutes;
        });
      },
      label: AppLocalizations.of(context)!.duration,
      isRequired: true,
    );
  }

  Widget _buildUpdateButton() {
    return PremiumButton(
      text: AppLocalizations.of(context)!.update,
      isLoading: _isLoading,
      onPressed: _updateCompanyService,
    );
  }

  Widget _buildDeleteButton() {
    return OutlinedButton(
      onPressed: _isDeleting ? null : _showDeleteConfirmation,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error, width: 2),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child:
          _isDeleting
              ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                ),
              )
              : Text(
                AppLocalizations.of(context)!.delete,
                style: AppTypography.body1.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
    );
  }

  Future<void> _updateCompanyService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validation
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pleaseSelectService,
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_durationInMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.invalidDuration,
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final minPrice = double.parse(_minPriceController.text.trim());
      final maxPrice =
          _priceType == PriceType.range
              ? double.tryParse(_maxPriceController.text.trim())
              : null;

      await _companyServiceUseCases.updateCompanyService(
        id: widget.companyService.id,
        companyIds: _selectedCompanyIds,
        serviceId: _selectedService!.id,
        minPrice: minPrice,
        maxPrice: maxPrice,
        duration: _durationInMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.companyServiceUpdatedSuccess,
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.serviceUpdateError}: $e',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            AppLocalizations.of(context)!.deleteServiceTitle,
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.deleteServiceConfirm,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteCompanyService();
              },
              child: Text(
                AppLocalizations.of(context)!.delete,
                style: AppTypography.body2.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCompanyService() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _companyServiceUseCases.deleteCompanyService(
        widget.companyService.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Firma hizmeti başarıyla silindi',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hizmet silinirken hata oluştu: $e',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}
