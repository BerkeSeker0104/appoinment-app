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
import '../../../data/models/branch_model.dart';
import '../../../data/models/service_model.dart';
import '../../widgets/premium_button.dart';
// TEMPORARILY COMMENTED OUT - Company selection widget (only one branch now)
// import '../../widgets/multi_select_company_dropdown.dart';
import '../../widgets/duration_picker_widget.dart';
import '../../../l10n/app_localizations.dart';

enum PriceType { single, range }

class AddCompanyServicePage extends StatefulWidget {
  const AddCompanyServicePage({super.key});

  @override
  State<AddCompanyServicePage> createState() => _AddCompanyServicePageState();
}

class _AddCompanyServicePageState extends State<AddCompanyServicePage> {
  final _formKey = GlobalKey<FormState>();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  final CompanyServiceUseCases _companyServiceUseCases = CompanyServiceUseCases(
    CompanyServiceRepositoryImpl(),
  );
  final BranchUseCases _branchUseCases = BranchUseCases(BranchRepositoryImpl());
  final ServiceApiService _serviceApiService = ServiceApiService();

  // Companies (branches)
  List<BranchModel> _companies = [];
  List<int> _selectedCompanyIds = [];

  // Services
  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  bool _isLoadingServices = true;

  // Price type
  PriceType _priceType = PriceType.single;

  // Duration
  int _durationInMinutes = 30; // Default 30 dakika

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    // _loadServices(); // Şirket seçildikten sonra çağrılacak
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await _branchUseCases.getBranches();
      if (!mounted) return;
      setState(() {
        _companies = companies;
        // TEMPORARILY: Auto-select the first branch since there's only one branch now
        if (_companies.isNotEmpty) {
          // Get the branch ID (can be string UUID or numeric)
          final branchId = _companies.first.id;
          final parsedId = int.tryParse(branchId);
          // Use hash code for selection ID (matching MultiSelectCompanyDropdown logic)
          final selectionId = parsedId != null && parsedId > 0
              ? parsedId
              : branchId.hashCode;
          _selectedCompanyIds = [selectionId];

          // Seçilen şirketin tipine göre hizmetleri getir
          final typeId = _companies.first.typeId;
          _loadServices(typeId);
        }
      });
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _loadServices([String? typeId]) async {
    try {
      setState(() => _isLoadingServices = true);
      final services = await _serviceApiService.getServices(typeId: typeId);
      setState(() {
        _services = services;
        if (_services.isNotEmpty) {
          _selectedService = _services.first;
        }
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
          AppLocalizations.of(context)!.newServiceTitle,
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
                // TEMPORARILY COMMENTED OUT - Company selection (only one branch now, auto-selected)
                // _buildCompanySelection(),
                // const SizedBox(height: AppSpacing.xl),
                _buildServiceSelection(),
                const SizedBox(height: AppSpacing.xl),
                _buildPriceSection(),
                const SizedBox(height: AppSpacing.xl),
                _buildDurationSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildSaveButton(),
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
          AppLocalizations.of(context)!.companyServiceInfo,
          style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context)!.companyServiceInfoSubtitle,
          style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // TEMPORARILY COMMENTED OUT - Company selection (only one branch now, auto-selected)
  // Widget _buildCompanySelection() {
  //   if (_isLoadingCompanies) {
  //     return Container(
  //       padding: const EdgeInsets.all(AppSpacing.lg),
  //       child: const Center(child: CircularProgressIndicator()),
  //     );
  //   }

  //   if (_companies.isEmpty) {
  //     return Container(
  //       padding: const EdgeInsets.all(AppSpacing.lg),
  //       decoration: BoxDecoration(
  //         color: AppColors.error.withValues(alpha: 0.1),
  //         borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
  //         border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(Icons.warning, color: AppColors.error),
  //           const SizedBox(width: AppSpacing.sm),
  //           Expanded(
  //             child: Text(
  //               'Firma bulunamadı. Lütfen önce firma ekleyin.',
  //               style: AppTypography.body2.copyWith(color: AppColors.error),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   return MultiSelectCompanyDropdown(
  //     companies: _companies,
  //     selectedCompanyIds: _selectedCompanyIds,
  //     onSelectionChanged: (ids) {
  //       setState(() {
  //         _selectedCompanyIds = ids;
  //       });
  //     },
  //     label: 'Firmalar',
  //     isRequired: true,
  //   );
  // }

  Widget _buildServiceSelection() {
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child:
              _isLoadingServices
                  ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                  : _services.isEmpty
                  ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      AppLocalizations.of(context)!.serviceNotFound,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  )
                  : DropdownButtonHideUnderline(
                    child: DropdownButton<ServiceModel>(
                      value: _selectedService,
                      isExpanded: true,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.textTertiary,
                      ),
                      items:
                          _services.map((ServiceModel service) {
                            return DropdownMenuItem<ServiceModel>(
                              value: service,
                              child: Text(service.name),
                            );
                          }).toList(),
                      onChanged: (ServiceModel? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedService = newValue;
                          });
                        }
                      },
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

  Widget _buildSaveButton() {
    return PremiumButton(
      text: AppLocalizations.of(context)!.addServiceButton,
      isLoading: _isLoading,
      onPressed: _saveCompanyService,
    );
  }

  // Seçilen şubelerin gerçek ID'lerini (UUID veya sayısal) döner
  // Hash değerlerinden gerçek ID'lere dönüştürür
  // UUID geçişinden sonra backend tüm ID'leri string olarak bekliyor
  List<dynamic> _getBackendCompanyIds() {
    return _selectedCompanyIds.map((selectionId) {
      // Seçilen şubeyi bul
      final company = _companies.firstWhere(
        (c) {
          final parsedId = int.tryParse(c.id);
          final selectionHash = parsedId != null && parsedId > 0
              ? parsedId
              : c.id.hashCode;
          return selectionHash == selectionId;
        },
      );
      
      // UUID geçişinden sonra backend tüm ID'leri string olarak bekliyor
      // Hem sayısal ID'ler (Merkez Şube gibi) hem de UUID'ler string olarak gönderilmeli
      return company.id; // Her zaman string olarak döner
    }).toList();
  }

  Future<void> _saveCompanyService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // TEMPORARILY: Company validation - since we auto-select the only branch
    // The branch should already be selected in _loadCompanies()
    if (_selectedCompanyIds.isEmpty || _companies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.branchNotFoundError,
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

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

      // Seçilen şubelerin gerçek ID'lerini al (UUID veya sayısal)
      final backendCompanyIds = _getBackendCompanyIds();

      await _companyServiceUseCases.createCompanyService(
        companyIds: backendCompanyIds,
        serviceId: _selectedService!.id,
        minPrice: minPrice,
        maxPrice: maxPrice,
        duration: _durationInMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.companyServiceAddedSuccess,
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
              '${AppLocalizations.of(context)!.serviceAddError}: $e',
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

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}
