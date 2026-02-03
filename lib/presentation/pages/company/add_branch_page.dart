import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/usecases/branch_usecases.dart';
import '../../../data/repositories/branch_repository_impl.dart';
import '../../../data/services/company_api_service.dart';
import '../../../data/services/extra_feature_api_service.dart';
import '../../../data/models/company_type_model.dart';
import '../../../data/models/extra_feature_model.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_input.dart';
import '../../widgets/address_picker_widget.dart';
import '../../widgets/location_dropdown_widget.dart';

class AddBranchPage extends StatefulWidget {
  const AddBranchPage({super.key});

  @override
  State<AddBranchPage> createState() => _AddBranchPageState();
}

class _AddBranchPageState extends State<AddBranchPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final BranchUseCases _branchUseCases = BranchUseCases(BranchRepositoryImpl());
  final CompanyApiService _companyApiService = CompanyApiService();
  final ExtraFeatureApiService _extraFeatureApiService =
      ExtraFeatureApiService();
  final ImagePicker _imagePicker = ImagePicker();

  CompanyTypeModel? _selectedBranchType;
  List<CompanyTypeModel> _branchTypes = [];
  bool _isLoadingTypes = true;
  bool _is24Hours = false;
  bool _isLoading = false;
  File? _profileImage; // Profil görseli (tek)
  List<File> _interiorImages = []; // İç görseller (3-10 adet)

  // Address data
  String? _selectedAddress;
  double? _selectedLatitude;
  double? _selectedLongitude;

  // Location dropdowns
  int? _selectedCountryId;
  int? _selectedCityId;
  int? _selectedStateId;

  // Location isimleri (bias için)
  String? _selectedCountryName;
  String? _selectedCityName;
  String? _selectedStateName;

  // Extra features - Backend'den çekilecek
  List<ExtraFeatureModel> _availableFeatures = [];
  bool _isLoadingFeatures = true;

  // Working hours for each day - using TimeOfDay
  final Map<String, Map<String, dynamic>> _workingHours = {
    'monday': {
      'open': const TimeOfDay(hour: 9, minute: 0),
      'close': const TimeOfDay(hour: 18, minute: 0),
      'closed': false
    },
    'tuesday': {
      'open': const TimeOfDay(hour: 9, minute: 0),
      'close': const TimeOfDay(hour: 18, minute: 0),
      'closed': false
    },
    'wednesday': {
      'open': const TimeOfDay(hour: 9, minute: 0),
      'close': const TimeOfDay(hour: 18, minute: 0),
      'closed': false
    },
    'thursday': {
      'open': const TimeOfDay(hour: 9, minute: 0),
      'close': const TimeOfDay(hour: 18, minute: 0),
      'closed': false
    },
    'friday': {
      'open': const TimeOfDay(hour: 9, minute: 0),
      'close': const TimeOfDay(hour: 18, minute: 0),
      'closed': false
    },
    'saturday': {
      'open': const TimeOfDay(hour: 9, minute: 0),
      'close': const TimeOfDay(hour: 18, minute: 0),
      'closed': false
    },
    'sunday': {
      'open': const TimeOfDay(hour: 9, minute: 0),
      'close': const TimeOfDay(hour: 18, minute: 0),
      'closed': false
    },
  };

  final List<int> _selectedFeatureIds = []; // Artık ID saklayacağız

  // Payment types
  List<String> _selectedPaidTypes = [];

  @override
  void initState() {
    super.initState();
    _loadBranchTypes();
    _loadExtraFeatures();
  }

  Future<void> _loadBranchTypes() async {
    try {
      setState(() => _isLoadingTypes = true);
      final types = await _companyApiService.getCompanyTypes();
      setState(() {
        _branchTypes = types;
        if (_branchTypes.isNotEmpty) {
          _selectedBranchType = _branchTypes.first;
        }
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTypes = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Şube türleri yüklenemedi',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadExtraFeatures() async {
    try {
      setState(() => _isLoadingFeatures = true);
      final features = await _extraFeatureApiService.getExtraFeatures();
      setState(() {
        _availableFeatures = features;
        _isLoadingFeatures = false;
      });
    } catch (e) {
      setState(() => _isLoadingFeatures = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Özellikler yüklenemedi',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final int fileSizeInBytes = await imageFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Dosya boyutu 5MB\'dan küçük olmalıdır',
                  style: AppTypography.body1.copyWith(color: AppColors.surface),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _profileImage = imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profil görseli seçilirken hata oluştu',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickInteriorImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      // Toplam görsel sayısı kontrolü
      if (_interiorImages.length + images.length > 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maksimum 10 iç görsel ekleyebilirsiniz',
                style: AppTypography.body1.copyWith(color: AppColors.surface),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Her görseli kontrol et ve ekle
      final List<File> validImages = [];
      for (final image in images) {
        final File imageFile = File(image.path);
        final int fileSizeInBytes = await imageFile.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${image.name} dosyası 5MB\'dan büyük, atlandı',
                  style: AppTypography.body1.copyWith(color: AppColors.surface),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          continue;
        }

        validImages.add(imageFile);
      }

      if (validImages.isNotEmpty) {
        setState(() {
          _interiorImages.addAll(validImages);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'İç görseller seçilirken hata oluştu',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeInteriorImage(int index) {
    setState(() {
      _interiorImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Yeni Şube Ekle',
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
                _buildProfileImageSection(),
                const SizedBox(height: AppSpacing.xl),
                _buildInteriorImagesSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildBasicInfoSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildPaymentTypesSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildWorkingHoursSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildExtraFeaturesSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildSaveButton(),
                const SizedBox(height: 100), // Navigation bar space
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
          'Şube Bilgileri',
          style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Yeni şube eklemek için gerekli bilgileri doldurun',
          style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Şube Profil Görseli',
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Zorunlu',
                style: AppTypography.caption.copyWith(
                  color: AppColors.error,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _pickProfileImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: _profileImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: Image.file(
                          _profileImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _profileImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppColors.surface,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Profil Görseli Seçin',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Maksimum 5MB • JPG, PNG',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteriorImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Şube İç Görselleri',
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Min: 3, Max: 10',
                style: AppTypography.caption.copyWith(
                  color: AppColors.error,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_interiorImages.length}/10 görsel seçildi (minimum 3 gerekli)',
          style: AppTypography.caption.copyWith(
            color: _interiorImages.length >= 3
                ? AppColors.success
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Grid görünümü
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1,
          ),
          itemCount: _interiorImages.length + 1, // +1 for add button
          itemBuilder: (context, index) {
            if (index == _interiorImages.length) {
              // Add button
              return GestureDetector(
                onTap: _interiorImages.length < 10 ? _pickInteriorImages : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: _interiorImages.length < 10
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: _interiorImages.length < 10
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _interiorImages.length < 10
                            ? 'Görsel Ekle'
                            : 'Maksimum\nUlaşıldı',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: _interiorImages.length < 10
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Image tile
            final image = _interiorImages[index];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.file(image, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeInteriorImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: AppColors.surface,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.surface,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        // Branch Name
        PremiumInput(
          controller: _nameController,
          label: 'Şube Adı',
          hint: 'Örn: Merkez Şube',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Şube adı gerekli';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Branch Type
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Şube Türü',
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
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
              child: _isLoadingTypes
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
                  : _branchTypes.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'Şube türleri yüklenemedi',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<CompanyTypeModel>(
                            value: _selectedBranchType,
                            isExpanded: true,
                            style: AppTypography.body1.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            items: _branchTypes.map((CompanyTypeModel type) {
                              return DropdownMenuItem<CompanyTypeModel>(
                                value: type,
                                child: Text(type.name),
                              );
                            }).toList(),
                            onChanged: (CompanyTypeModel? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedBranchType = newValue;
                                });
                              }
                            },
                          ),
                        ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Location Dropdowns
        LocationDropdownWidget(
          label: 'Konum',
          hint: 'Ülke, İl ve İlçe seçin',
          isRequired: true,
          validator: (value) {
            if (_selectedCountryId == null) {
              return 'Ülke seçimi gerekli';
            }
            if (_selectedCityId == null) {
              return 'İl seçimi gerekli';
            }
            if (_selectedStateId == null) {
              return 'İlçe seçimi gerekli';
            }
            return null;
          },
          onLocationSelected: (countryId, cityId, stateId) {
            setState(() {
              _selectedCountryId = countryId;
              _selectedCityId = cityId;
              _selectedStateId = stateId;
            });
          },
          onLocationNamesSelected: (countryName, cityName, stateName) {
            setState(() {
              _selectedCountryName = countryName;
              _selectedCityName = cityName;
              _selectedStateName = stateName;
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Address - Google Places
        AddressPickerWidget(
          label: 'Şube Adresi',
          hint: 'Sokak, cadde ve kapı numarasını girin',
          isRequired: true,
          countryCode: _selectedCountryName, // Bias için
          cityName: _selectedCityName, // Bias için
          districtName: _selectedStateName, // Bias için
          enableGeocoding: true,
          onAddressSelected: (address, lat, lng) {
            setState(() {
              _selectedAddress = address;
              _selectedLatitude = lat;
              _selectedLongitude = lng;
              _addressController.text = address;
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Phone
        PremiumInput(
          controller: _phoneController,
          label: 'Şube Telefonu',
          hint: '555 555 5555',
          isPhoneNumber: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Telefon numarası gerekli';
            }
            final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
            if (digitsOnly.length != 10) {
              return 'Telefon numarası 10 haneli olmalı';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Email
        PremiumInput(
          controller: _emailController,
          label: 'Şube Emaili',
          hint: 'ornek@company.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'E-posta adresi gerekli';
            }
            if (!value.contains('@')) {
              return 'Geçerli bir e-posta adresi girin';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ödeme Tipleri',
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Şubenizde kabul ettiğiniz ödeme yöntemlerini seçin',
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Payment types multi-select
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payment, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Ödeme Yöntemleri',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Payment options
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildPaymentTypeChip('cash', 'Nakit'),
                  _buildPaymentTypeChip('creditCard', 'Kredi Kartı'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeChip(String value, String label) {
    final isSelected = _selectedPaidTypes.contains(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPaidTypes.remove(value);
          } else {
            _selectedPaidTypes.add(value);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: AppColors.surface,
              ),
            if (isSelected) const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.body2.copyWith(
                color: isSelected ? AppColors.surface : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Çalışma Saatleri',
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 24/7 Checkbox
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _is24Hours,
                onChanged: (value) =>
                    setState(() => _is24Hours = value ?? false),
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '7/24 Açık',
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Working hours for each day
        if (!_is24Hours) ...[
          ..._workingHours.entries.map(
            (entry) => _buildDayWorkingHours(entry.key, entry.value),
          ),
        ],
      ],
    );
  }

  // Helper method to format TimeOfDay to string (HH:mm format)
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Show time picker for opening time
  Future<void> _selectOpeningTime(String day) async {
    final currentTime = _workingHours[day]!['open'] as TimeOfDay;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (pickedTime != null) {
      setState(() {
        _workingHours[day]!['open'] = pickedTime;
      });
    }
  }

  // Show time picker for closing time
  Future<void> _selectClosingTime(String day) async {
    final currentTime = _workingHours[day]!['close'] as TimeOfDay;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (pickedTime != null) {
      setState(() {
        _workingHours[day]!['close'] = pickedTime;
      });
    }
  }

  Widget _buildDayWorkingHours(String day, Map<String, dynamic> hours) {
    final dayNames = {
      'monday': 'Pazartesi',
      'tuesday': 'Salı',
      'wednesday': 'Çarşamba',
      'thursday': 'Perşembe',
      'friday': 'Cuma',
      'saturday': 'Cumartesi',
      'sunday': 'Pazar',
    };

    final openTime = hours['open'] as TimeOfDay;
    final closeTime = hours['close'] as TimeOfDay;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dayNames[day] ?? day,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Checkbox(
                value: hours['closed'] ?? false,
                onChanged: (value) {
                  setState(() {
                    _workingHours[day]!['closed'] = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Kapalı',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (!(hours['closed'] ?? false)) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Açılış',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      InkWell(
                        onTap: () => _selectOpeningTime(day),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatTimeOfDay(openTime),
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '-',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kapanış',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      InkWell(
                        onTap: () => _selectClosingTime(day),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatTimeOfDay(closeTime),
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtraFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ekstra Özellikler',
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Şubenizde mevcut olan özellikleri seçin',
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Multi-select dropdown
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Seçim Yapınız',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Features list
              _isLoadingFeatures
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _availableFeatures.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(
                            'Özellik bulunamadı',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _availableFeatures.map((feature) {
                            final featureId = feature.id;
                            final isSelected = _selectedFeatureIds.contains(featureId);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedFeatureIds.remove(featureId);
                                  } else {
                                    _selectedFeatureIds.add(featureId);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      Icon(
                                        Icons.check,
                                        size: 16,
                                        color: AppColors.surface,
                                      ),
                                    if (isSelected)
                                      const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      feature.name,
                                      style: AppTypography.body2.copyWith(
                                        color: isSelected
                                            ? AppColors.surface
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return PremiumButton(
      text: 'Şube Ekle',
      isLoading: _isLoading,
      onPressed: _saveBranch,
    );
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBranchType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen şube türü seçin',
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen adres seçin',
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Profil görseli kontrolü
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen profil görseli ekleyin',
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // İç görseller kontrolü
    if (_interiorImages.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'En az 3 iç görsel eklemelisiniz (şu an ${_interiorImages.length} adet)',
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_interiorImages.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maksimum 10 iç görsel ekleyebilirsiniz',
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
      // Backend JWT token'dan user bilgisini otomatik alıyor, manuel göndermeye gerek yok

      final featureIdList =
          _selectedFeatureIds.where((id) => id > 0).toList();

      await _branchUseCases.createBranch(
        name: _nameController.text.trim(),
        type: _selectedBranchType!.id, // ID gönder, backend bunu bekliyor
        address: _selectedAddress!,
        phone: _phoneController.text.replaceAll(' ', ''),
        email: _emailController.text.trim(),
        profileImage: _profileImage!.path, // Profil görseli path'i
        interiorImages: _interiorImages
            .map((file) => file.path)
            .toList(), // İç görseller path listesi
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        countryId: _selectedCountryId!, // YENİ
        cityId: _selectedCityId!, // YENİ
        stateId: _selectedStateId!, // YENİ
        companyId: '', // Backend JWT token'dan otomatik alıyor
        workingHours: _is24Hours
            ? {'all': '7/24 Açık'}
            : _workingHours.map((key, value) {
                if (value['closed'] == true) {
                  return MapEntry(key, 'Kapalı');
                }
                final openTime = value['open'] as TimeOfDay;
                final closeTime = value['close'] as TimeOfDay;
                return MapEntry(
                  key,
                  '${_formatTimeOfDay(openTime)} - ${_formatTimeOfDay(closeTime)}',
                );
              }),
        featureIds: featureIdList,
        paidTypes:
            _selectedPaidTypes.join(','), // YENİ - virgülle ayrılmış string
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Şube başarıyla eklendi',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
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
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
