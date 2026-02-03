import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_input.dart';
import '../../widgets/address_picker_widget.dart';
import '../../widgets/location_dropdown_widget.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/company_type_model.dart';
import '../../../data/models/feature_model.dart';
import '../../../domain/usecases/branch_usecases.dart';
import '../../../data/repositories/branch_repository_impl.dart';
import '../../../data/services/company_api_service.dart';
import '../../../data/services/feature_api_service.dart';

class EditBranchPage extends StatefulWidget {
  final BranchModel branch;

  const EditBranchPage({super.key, required this.branch});

  @override
  State<EditBranchPage> createState() => _EditBranchPageState();
}

class _EditBranchPageState extends State<EditBranchPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final BranchUseCases _branchUseCases = BranchUseCases(BranchRepositoryImpl());
  final CompanyApiService _companyApiService = CompanyApiService();
  final FeatureApiService _featureApiService = FeatureApiService();
  final ImagePicker _imagePicker = ImagePicker();

  CompanyTypeModel? _selectedBranchType;
  List<CompanyTypeModel> _branchTypes = [];
  List<FeatureModel> _availableFeatures = [];
  bool _isLoadingTypes = false;
  bool _isLoadingFeatures = false;
  bool _is24Hours = false;
  bool _isLoading = false;
  String? _errorMessage;
  File? _selectedImage;
  String? _existingImageUrl;
  final List<File> _newInteriorImages = [];
  // Existing interior pictures with ID, URL, and order
  List<Map<String, dynamic>> _existingInteriorPictures = [];

  // Location dropdowns
  int? _selectedCountryId;
  int? _selectedCityId;
  int? _selectedStateId;

  // Location isimleri (bias için)
  String? _selectedCountryName;
  String? _selectedCityName;
  String? _selectedStateName;

  // Address data
  String? _selectedAddress;
  double? _selectedLatitude;
  double? _selectedLongitude;

  // Extra features - Backend'den çekilecek

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

  final List<int> _selectedFeatureIds = [];

  // Payment types
  List<String> _selectedPaidTypes = [];

  // Güncel branch verisi - API'den yeniden yüklenecek
  BranchModel? _currentBranch;

  @override
  void initState() {
    super.initState();
    _loadBranchFromApi(); // Branch'i API'den yeniden yükle
    _initializeData();
    _loadBranchTypes();
    _loadFeatures();
  }

  /// Branch'i API'den yeniden yükleyerek güncel featureIds ile birlikte getirir
  Future<void> _loadBranchFromApi() async {
    try {
      BranchModel updatedBranch;
      try {
        updatedBranch = await _branchUseCases.getBranch(widget.branch.id);
      } catch (e) {
        updatedBranch = widget.branch;
      }

      if (updatedBranch.featureIds == null ||
          updatedBranch.featureIds!.isEmpty) {
        try {
          final allBranches = await _branchUseCases.getBranches();

          BranchModel? branchFromList;
          try {
            branchFromList = allBranches.firstWhere(
              (b) =>
                  b.id.toString() == widget.branch.id.toString() ||
                  b.id == widget.branch.id,
            );
          } catch (e) {
            branchFromList = null;
          }

          if (branchFromList != null &&
              branchFromList.featureIds != null &&
              branchFromList.featureIds!.isNotEmpty) {
            updatedBranch =
                updatedBranch.copyWith(featureIds: branchFromList.featureIds);
          } else if (widget.branch.featureIds != null &&
              widget.branch.featureIds!.isNotEmpty) {
            updatedBranch =
                updatedBranch.copyWith(featureIds: widget.branch.featureIds);
          }
        } catch (e) {
          if (widget.branch.featureIds != null &&
              widget.branch.featureIds!.isNotEmpty) {
            updatedBranch =
                updatedBranch.copyWith(featureIds: widget.branch.featureIds);
          }
        }
      }

      final branchToUse = updatedBranch;

      setState(() {
        _currentBranch = branchToUse;
        // Güncel branch'e göre form verilerini güncelle
        _nameController.text = updatedBranch.name;
        _addressController.text = updatedBranch.address;

        // Telefon numarasından ülke kodunu kaldır (90 veya +90)
        // Backend'den phoneCode + phone birleşik geliyor (örn: 905111110193)
        String phone = updatedBranch.phone;
        if (phone.startsWith('+90')) {
          phone = phone.substring(3);
        } else if (phone.startsWith('90') && phone.length > 10) {
          phone = phone.substring(2);
        }
        _phoneController.text = phone;

        _emailController.text = updatedBranch.email;
        _selectedCountryId = updatedBranch.countryId;
        _selectedCityId = updatedBranch.cityId;
        _selectedStateId = updatedBranch.stateId;
        _selectedAddress = updatedBranch.address;
        _selectedLatitude = updatedBranch.latitude;
        _selectedLongitude = updatedBranch.longitude;
        _existingImageUrl = updatedBranch.image;
        _selectedPaidTypes = updatedBranch.paidTypes
                ?.split(',')
                .where((e) => e.isNotEmpty)
                .toList() ??
            [];
        _newInteriorImages.clear();

        // CRITICAL: Çalışma saatlerini API'den gelen güncel verilerle güncelle
        _is24Hours = updatedBranch.workingHours.containsKey('all') &&
            updatedBranch.workingHours['all'] == '7/24 Açık';

        // Çalışma saatlerini parse et ve güncelle
        updatedBranch.workingHours.forEach((day, hours) {
          if (_workingHours.containsKey(day)) {
            if (hours.toLowerCase() == 'kapalı' ||
                hours.toLowerCase() == 'closed') {
              _workingHours[day]!['closed'] = true;
              _workingHours[day]!['open'] = const TimeOfDay(hour: 9, minute: 0);
              _workingHours[day]!['close'] =
                  const TimeOfDay(hour: 18, minute: 0);
            } else {
              // "09:00 - 18:00" formatını parse et
              // Hem " - " hem de "-" ile ayrılmış formatları destekle
              String normalizedHours = hours.trim();
              List<String> parts;

              if (normalizedHours.contains(' - ')) {
                parts = normalizedHours.split(' - ');
              } else if (normalizedHours.contains('-')) {
                parts = normalizedHours.split('-');
              } else {
                // Format tanınmıyorsa default değerler kullan
                parts = ['09:00', '18:00'];
              }

              if (parts.length >= 2) {
                _workingHours[day]!['open'] = _parseTimeString(parts[0].trim());
                _workingHours[day]!['close'] =
                    _parseTimeString(parts[1].trim());
                _workingHours[day]!['closed'] = false;
              } else {
                // Parse edilemezse default değerler
                _workingHours[day]!['open'] =
                    const TimeOfDay(hour: 9, minute: 0);
                _workingHours[day]!['close'] =
                    const TimeOfDay(hour: 18, minute: 0);
                _workingHours[day]!['closed'] = false;
              }
            }
          }
        });
      });

      // Parse existing interior pictures with ID, URL, and order (outside setState)
      final parsedPictures = await _parseExistingPictures(updatedBranch);
      setState(() {
        _existingInteriorPictures = parsedPictures;
      });

      if (_availableFeatures.isNotEmpty) {
        _initializeSelectedFeatures();
      }
    } catch (e) {
      setState(() {
        _currentBranch = widget.branch;
        _newInteriorImages.clear();
        _existingInteriorPictures = [];
      });
    }
  }

  Future<void> _loadBranchTypes() async {
    try {
      setState(() => _isLoadingTypes = true);
      final types = await _companyApiService.getCompanyTypes();
      setState(() {
        _branchTypes = types;
        // Mevcut şube türünü bul (ID veya name ile)
        _selectedBranchType = types.firstWhere(
          (t) => t.id == widget.branch.type || t.name == widget.branch.type,
          orElse: () => types.isNotEmpty ? types.first : types.first,
        );
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTypes = false);
    }
  }

  Future<void> _loadFeatures() async {
    try {
      setState(() => _isLoadingFeatures = true);
      final features = await _featureApiService.getFeatures();
      setState(() {
        _availableFeatures = features;
        _isLoadingFeatures = false;
      });
      _initializeSelectedFeatures();
    } catch (e) {
      setState(() {
        _availableFeatures = _getDefaultFeatures();
        _isLoadingFeatures = false;
      });
      _initializeSelectedFeatures();
    }
  }

  void _initializeSelectedFeatures() {
    _selectedFeatureIds.clear();
    final branchToUse = _currentBranch ?? widget.branch;

    if (branchToUse.featureIds != null && branchToUse.featureIds!.isNotEmpty) {
      for (int featureId in branchToUse.featureIds!) {
        final featureIdString = featureId.toString();

        try {
          final matchingFeature = _availableFeatures.firstWhere(
            (feature) {
              final featureIdInt = int.tryParse(feature.id);
              return feature.id == featureIdString ||
                  feature.id == featureId.toString() ||
                  (featureIdInt != null && featureIdInt == featureId) ||
                  feature.id.toString() == featureId.toString();
            },
          );

          if (matchingFeature.id.isNotEmpty &&
              !_selectedFeatureIds.contains(featureId)) {
            _selectedFeatureIds.add(featureId);
          }
        } catch (e) {
          // Feature not found, skip
        }
      }
    } else {
      for (String service in branchToUse.services) {
        String parsedServiceName = service.trim();
        if (service.trim().startsWith('{') && service.contains('"tr"')) {
          try {
            final decoded = jsonDecode(service);
            if (decoded is Map<String, dynamic>) {
              parsedServiceName = (decoded['tr']?.toString() ??
                      decoded['en']?.toString() ??
                      service)
                  .trim();
            }
          } catch (e) {
            parsedServiceName = service.trim();
          }
        }

        final normalizedServiceName = parsedServiceName.toLowerCase().trim();

        try {
          final matchingFeature = _availableFeatures.firstWhere(
            (feature) {
              final normalizedFeatureName = feature.name.toLowerCase().trim();
              return normalizedFeatureName == normalizedServiceName;
            },
          );

          final parsedId = int.tryParse(matchingFeature.id);
          if (parsedId != null && !_selectedFeatureIds.contains(parsedId)) {
            _selectedFeatureIds.add(parsedId);
          }
        } catch (e) {
          // Feature not found, skip
        }
      }
    }
  }

  List<FeatureModel> _getDefaultFeatures() {
    return [
      const FeatureModel(id: '1', name: 'WiFi'),
      const FeatureModel(id: '2', name: 'Klima'),
      const FeatureModel(id: '3', name: 'Otopark'),
      const FeatureModel(id: '4', name: 'Engelli Erişimi'),
      const FeatureModel(id: '5', name: 'Kartla Ödeme'),
      const FeatureModel(id: '6', name: 'Vale Hizmeti'),
      const FeatureModel(id: '7', name: 'Çocuk Oyun Alanı'),
      const FeatureModel(id: '8', name: 'Kahve/Çay İkramı'),
      const FeatureModel(id: '9', name: 'Masaj'),
      const FeatureModel(id: '10', name: 'Sakal Tasarımı'),
      const FeatureModel(id: '11', name: 'Boya/Röfle'),
      const FeatureModel(id: '12', name: 'Cilt Bakımı'),
    ];
  }

  void _initializeData() {
    _nameController.text = widget.branch.name;
    _addressController.text = widget.branch.address;
    _selectedAddress = widget.branch.address;
    _selectedLatitude = widget.branch.latitude;
    _selectedLongitude = widget.branch.longitude;

    // Telefon numarasından ülke kodunu kaldır (90 veya +90)
    String phone = widget.branch.phone;
    if (phone.startsWith('+90')) {
      phone = phone.substring(3);
    } else if (phone.startsWith('90') && phone.length > 10) {
      phone = phone.substring(2);
    }
    _phoneController.text = phone;

    _emailController.text = widget.branch.email;

    // Initialize location data
    _selectedCountryId = widget.branch.countryId;
    _selectedCityId = widget.branch.cityId;
    _selectedStateId = widget.branch.stateId;

    // Initialize paidTypes
    if (widget.branch.paidTypes != null &&
        widget.branch.paidTypes!.isNotEmpty) {
      _selectedPaidTypes = widget.branch.paidTypes!.split(',');
    } else {
      _selectedPaidTypes = [];
    }

    // Branch type - backend'den type ID olarak gelirse direkt kullan
    // _selectedBranchType'ı dropdown yüklendiğinde set edeceğiz
    _existingImageUrl = widget.branch.image;
    _newInteriorImages.clear();

    // Initialize working hours from branch data
    // Check if it's 24/7 open
    _is24Hours = widget.branch.workingHours.containsKey('all') &&
        widget.branch.workingHours['all'] == '7/24 Açık';

    widget.branch.workingHours.forEach((day, hours) {
      if (_workingHours.containsKey(day)) {
        if (hours.toLowerCase() == 'kapalı' ||
            hours.toLowerCase() == 'closed') {
          _workingHours[day]!['closed'] = true;
          _workingHours[day]!['open'] = const TimeOfDay(hour: 9, minute: 0);
          _workingHours[day]!['close'] = const TimeOfDay(hour: 18, minute: 0);
        } else {
          // "09:00 - 18:00" formatını parse et
          // Hem " - " hem de "-" ile ayrılmış formatları destekle
          String normalizedHours = hours.trim();
          List<String> parts;

          if (normalizedHours.contains(' - ')) {
            parts = normalizedHours.split(' - ');
          } else if (normalizedHours.contains('-')) {
            parts = normalizedHours.split('-');
          } else {
            // Format tanınmıyorsa default değerler kullan
            parts = ['09:00', '18:00'];
          }

          if (parts.length >= 2) {
            _workingHours[day]!['open'] = _parseTimeString(parts[0].trim());
            _workingHours[day]!['close'] = _parseTimeString(parts[1].trim());
            _workingHours[day]!['closed'] = false;
          } else {
            // Parse edilemezse default değerler
            _workingHours[day]!['open'] = const TimeOfDay(hour: 9, minute: 0);
            _workingHours[day]!['close'] = const TimeOfDay(hour: 18, minute: 0);
            _workingHours[day]!['closed'] = false;
          }
        }
      }
    });

    // Extra features will be initialized after features are loaded from backend
  }

  Future<void> _pickImage() async {
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
          _selectedImage = imageFile;
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Resim seçilirken hata oluştu',
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

      final int currentCount = _newInteriorImages.length;
      if (currentCount + images.length > 10) {
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
          _newInteriorImages.addAll(validImages);
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

  /// Parse existing interior pictures from branch data
  /// Returns list of maps with {"id": int, "url": String, "order": int}
  Future<List<Map<String, dynamic>>> _parseExistingPictures(
      BranchModel branch) async {
    try {
      // Try to get raw branch data to access pictures array with order
      final rawData = await _companyApiService.getRawBranchData(branch.id);
      final pictures = rawData['pictures'] ?? rawData['interior_images'];

      if (pictures != null && pictures is List) {
        final List<Map<String, dynamic>> parsedPictures = [];
        for (var picture in pictures) {
          if (picture is Map<String, dynamic>) {
            final id = picture['id'];
            final pictureUrl = picture['picture'];
            final order = picture['order'] ?? 0;

            if (id != null && pictureUrl != null) {
              // Parse URL - convert relative path to full URL if needed
              String url = pictureUrl.toString();
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                url =
                    '${ApiConstants.fileUrl}${url.startsWith('/') ? url : '/$url'}';
              }

              parsedPictures.add({
                'id': id is int ? id : int.tryParse(id.toString()) ?? 0,
                'url': url,
                'order': order is int
                    ? order
                    : (order is String ? int.tryParse(order) ?? 0 : 0),
              });
            }
          }
        }
        // Sort by order
        parsedPictures
            .sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
        return parsedPictures;
      }
    } catch (e) {
      // Fall through to fallback method
    }

    // Fallback: Match IDs with URLs by index
    final List<Map<String, dynamic>> parsedPictures = [];
    if (branch.interiorImageIds != null && branch.interiorImages != null) {
      final ids = branch.interiorImageIds!;
      final urls = branch.interiorImages!;

      for (int i = 0; i < ids.length && i < urls.length; i++) {
        parsedPictures.add({
          'id': ids[i],
          'url': urls[i],
          'order': i, // Use index as order
        });
      }
    }

    return parsedPictures;
  }

  void _removeNewInteriorImage(int index) {
    setState(() {
      _newInteriorImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Şube Düzenle',
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        // TEMPORARILY COMMENTED OUT - Branch delete feature
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.delete, color: AppColors.error),
        //     onPressed: _showDeleteDialog,
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: AppSpacing.xxxl),
              _buildInteriorImagesSection(),
              const SizedBox(height: AppSpacing.xxxl),
              _buildBranchInfoSection(),
              const SizedBox(height: AppSpacing.xxxl),
              _buildPaymentTypesSection(),
              const SizedBox(height: AppSpacing.xxxl),
              _buildWorkingHoursSection(),
              const SizedBox(height: AppSpacing.xxxl),
              _buildExtraFeaturesSection(),
              const SizedBox(height: AppSpacing.xxxl),
              _buildSaveButton(),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildErrorMessage(),
              ],
              const SizedBox(height: 100), // Navigation bar space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Şube Görseli',
          style: AppTypography.body2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: _selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedImage = null;
                            _existingImageUrl = widget.branch.image;
                          }),
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
                : _existingImageUrl != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            child: Image.network(
                              _existingImageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit,
                                color: AppColors.surface,
                                size: 16,
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
                            'Görsel Seçin',
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
    final existingCount = _existingInteriorPictures.length;
    final newCount = _newInteriorImages.length;
    final totalCount = existingCount + newCount;
    final bool canAddMore = totalCount < 10;

    // Combine existing and new pictures for display
    final List<Map<String, dynamic>> allPictures = [];

    // Add existing pictures (with type marker)
    for (var picture in _existingInteriorPictures) {
      allPictures.add({
        ...picture,
        'type': 'existing',
      });
    }

    // Add new pictures (with type marker)
    for (int i = 0; i < _newInteriorImages.length; i++) {
      allPictures.add({
        'type': 'new',
        'index': i,
        'file': _newInteriorImages[i],
      });
    }

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
                'Max: 10',
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
          existingCount > 0
              ? 'Mevcut: $existingCount görsel • Yeni: $newCount görsel (Toplam: $totalCount/10)'
              : (newCount == 0
                  ? 'Mevcut iç görseller backend tarafından gösterilmiyor. Yeni görseller yüklerseniz eskilerinin yerine geçer.'
                  : '$newCount/10 yeni görsel seçildi (en az 3 görsel eklemeniz önerilir).'),
          style: AppTypography.caption.copyWith(
            color: totalCount == 0
                ? AppColors.textSecondary
                : (totalCount >= 3 ? AppColors.success : AppColors.error),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Use ReorderableGridView for existing pictures, Wrap for new pictures and add button
        Column(
          children: [
            // Existing pictures with ReorderableGridView
            if (_existingInteriorPictures.isNotEmpty)
              ReorderableGridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.0,
                onReorder: (oldIndex, newIndex) {
                  _onPictureReorder(oldIndex, newIndex);
                },
                // State'ten direkt al - List.generate yerine map kullan
                children:
                    _existingInteriorPictures.asMap().entries.map((entry) {
                  final index = entry.key;
                  final picture = entry.value;
                  return _buildExistingPictureItemForReorder(picture, index);
                }).toList(),
              ),
            // New pictures and Add button with Wrap
            if (_newInteriorImages.isNotEmpty || canAddMore)
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  // New pictures
                  ...List.generate(_newInteriorImages.length, (index) {
                    return _buildNewPictureItem(
                        _newInteriorImages[index], index);
                  }),
                  // Add button
                  if (canAddMore) _buildAddPictureButton(),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildExistingPictureItemForReorder(
      Map<String, dynamic> picture, int index) {
    final pictureId = picture['id'] as int;
    final imageUrl = picture['url'] as String;

    return Container(
      key: ValueKey('existing_$pictureId'),
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
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.surface,
                  child: Icon(
                    Icons.broken_image,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                );
              },
            ),
          ),
          // Drag handle indicator
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.drag_handle,
                color: AppColors.surface,
                size: 16,
              ),
            ),
          ),
          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _showDeletePictureDialog(pictureId, index),
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
        ],
      ),
    );
  }

  Widget _buildNewPictureItem(File imageFile, int index) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width -
              AppSpacing.screenHorizontal * 2 -
              AppSpacing.md) /
          2,
      height: (MediaQuery.of(context).size.width -
              AppSpacing.screenHorizontal * 2 -
              AppSpacing.md) /
          2,
      child: Container(
        key: ValueKey('new_$index'),
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
              child: Image.file(imageFile, fit: BoxFit.cover),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeNewInteriorImage(index),
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
                  color: AppColors.primary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Yeni',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPictureButton() {
    final totalCount =
        _existingInteriorPictures.length + _newInteriorImages.length;
    final bool canAddMore = totalCount < 10;

    return SizedBox(
      width: (MediaQuery.of(context).size.width -
              AppSpacing.screenHorizontal * 2 -
              AppSpacing.md) /
          2,
      height: (MediaQuery.of(context).size.width -
              AppSpacing.screenHorizontal * 2 -
              AppSpacing.md) /
          2,
      child: GestureDetector(
        onTap: canAddMore ? _pickInteriorImages : null,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: canAddMore ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: 40,
                color: canAddMore ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                canAddMore ? 'Görsel Ekle' : 'Maksimum\nUlaşıldı',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color:
                      canAddMore ? AppColors.primary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Şube Bilgileri',
          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Branch Name
        PremiumInput(
          controller: _nameController,
          label: 'Şube Adı',
          hint: 'Şube adını girin',
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
                            _selectedBranchType?.name ??
                                'Şube türleri yüklenemedi',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
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
                            onChanged: (value) =>
                                setState(() => _selectedBranchType = value),
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
          initialCountryId: _selectedCountryId,
          initialCityId: _selectedCityId,
          initialStateId: _selectedStateId,
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
          initialValue: _selectedAddress,
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
          hint: 'ornek@email.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email adresi gerekli';
            }
            if (!value.contains('@')) {
              return 'Geçerli bir email adresi girin';
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

  // Helper method to parse string to TimeOfDay
  // Supports both "HH:mm" and "HH:mm:ss" formats
  TimeOfDay _parseTimeString(String timeString) {
    final trimmed = timeString.trim();
    final parts = trimmed.split(':');
    
    // Support both "HH:mm" and "HH:mm:ss" formats
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    
    return const TimeOfDay(hour: 9, minute: 0);
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
              if (_isLoadingFeatures)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _availableFeatures.map((feature) {
                    final featureId = int.tryParse(feature.id);
                    final isSelected = featureId != null &&
                        _selectedFeatureIds.contains(featureId);
                    return GestureDetector(
                      onTap: () {
                        if (featureId == null) return;
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
      text: 'Değişiklikleri Kaydet',
      onPressed: _isLoading ? null : _saveBranch,
      isLoading: _isLoading,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.body2.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeletePictureDialog(int pictureId, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          title: Text(
            'Görseli Sil',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Bu görseli silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
            style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'İptal',
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteExistingPicture(pictureId, index);
              },
              child: Text(
                'Sil',
                style: AppTypography.body1.copyWith(
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

  Future<void> _deleteExistingPicture(int pictureId, int index) async {
    // Optimistic update
    final deletedPicture = _existingInteriorPictures[index];
    setState(() {
      _existingInteriorPictures.removeAt(index);
    });

    try {
      await _companyApiService.deletePicture(pictureId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Görsel başarıyla silindi',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        // Reload branch to get updated data
        await _loadBranchFromApi();
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _existingInteriorPictures.insert(index, deletedPicture);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Görsel silinirken hata oluştu: ${e.toString().replaceFirst('Exception: ', '')}',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _onPictureReorder(int oldIndex, int newIndex) async {
    // Only allow reordering of existing pictures
    if (oldIndex >= _existingInteriorPictures.length ||
        newIndex >= _existingInteriorPictures.length) {
      return;
    }

    if (oldIndex == newIndex) return;

    // ReorderableGridView'ın onReorder callback'i çağrıldığında,
    // widget zaten kendi içinde reorder yapmış oluyor.
    // Biz sadece state'i güncellemeliyiz.
    // Önce kopya al (revert için)
    final picturesCopy =
        List<Map<String, dynamic>>.from(_existingInteriorPictures);

    // State'i güncelle
    // ReorderableGridView'ın onReorder callback'i:
    // - oldIndex: taşınan öğenin eski index'i
    // - newIndex: taşınan öğenin yeni index'i
    // ReorderableGridView paketi newIndex'i zaten doğru şekilde veriyor
    setState(() {
      final movedPicture = _existingInteriorPictures.removeAt(oldIndex);
      _existingInteriorPictures.insert(newIndex, movedPicture);

      // Order değerlerini güncelle
      for (int i = 0; i < _existingInteriorPictures.length; i++) {
        _existingInteriorPictures[i] = {
          ..._existingInteriorPictures[i],
          'order': i,
        };
      }
    });

    // Update order on backend - tüm görsellerin order'ını güncelle
    try {
      // Tüm görsellerin order'ını güncelle (backend'in doğru sıralamayı alması için)
      final updatePromises = <Future>[];
      for (int i = 0; i < _existingInteriorPictures.length; i++) {
        updatePromises.add(
          _companyApiService.updatePictureOrder(
            _existingInteriorPictures[i]['id'] as int,
            i,
          ),
        );
      }

      // Tüm güncellemeleri paralel olarak yap
      await Future.wait(updatePromises);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Görsel sırası başarıyla güncellendi',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on error - kopyadan geri yükle
      setState(() {
        _existingInteriorPictures = picturesCopy;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Görsel sırası güncellenirken hata oluştu: ${e.toString().replaceFirst('Exception: ', '')}',
              style: AppTypography.body1.copyWith(color: AppColors.surface),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) return;

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

    if (_selectedFeatureIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lütfen en az bir ekstra özellik seçiniz',
            style: AppTypography.body1.copyWith(color: AppColors.surface),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final featureIdsInt = _selectedFeatureIds.where((id) => id > 0).toList();

      final newInteriorImagePaths =
          _newInteriorImages.map((file) => file.path).toList();

      if (newInteriorImagePaths.isNotEmpty &&
          newInteriorImagePaths.length < 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'En az 3 iç görsel seçili olmalıdır',
                style: AppTypography.body1.copyWith(color: AppColors.surface),
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Şube görseli varsa dosya yolunu hazırla
      String? profileImagePath;
      if (_selectedImage != null) {
        profileImagePath = _selectedImage!.path;
      }

      await _branchUseCases.updateBranch(
        branchId: widget.branch.id,
        name: _nameController.text.trim(),
        type: _selectedBranchType?.id, // ID gönder, backend bunu bekliyor
        address: _selectedAddress!,
        phone: _phoneController.text.replaceAll(' ', ''),
        email: _emailController.text.trim(),
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        countryId: _selectedCountryId, // YENİ
        cityId: _selectedCityId, // YENİ
        stateId: _selectedStateId, // YENİ
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
        // Feature ID'lerini int array olarak gönder (backend bunu bekliyor)
        featureIds: featureIdsInt,
        paidTypes:
            _selectedPaidTypes.join(','), // YENİ - virgülle ayrılmış string
        profileImagePath: profileImagePath, // YENİ - şube görseli
        newInteriorImagePaths: newInteriorImagePaths,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şube başarıyla güncellendi'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // TEMPORARILY COMMENTED OUT - Branch delete feature
  // void _showDeleteDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         backgroundColor: AppColors.surface,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
  //         ),
  //         title: Text(
  //           'Şubeyi Sil',
  //           style: AppTypography.heading3.copyWith(
  //             color: AppColors.textPrimary,
  //           ),
  //         ),
  //         content: Text(
  //           '${widget.branch.name} şubesini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
  //           style: AppTypography.body1.copyWith(color: AppColors.textSecondary),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text(
  //               'İptal',
  //               style: AppTypography.body1.copyWith(
  //                 color: AppColors.textSecondary,
  //               ),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //               _deleteBranch();
  //             },
  //             child: Text(
  //               'Sil',
  //               style: AppTypography.body1.copyWith(
  //                 color: AppColors.error,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Future<void> _deleteBranch() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = null;
  //   });

  //   try {
  //     await _branchUseCases.deleteBranch(widget.branch.id);

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Şube başarıyla silindi'),
  //           backgroundColor: AppColors.success,
  //         ),
  //       );
  //       Navigator.pop(context, true); // Return true to refresh list
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         _errorMessage = 'Şube silinirken hata oluştu: ${e.toString()}';
  //         _isLoading = false;
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(_errorMessage!),
  //           backgroundColor: AppColors.error,
  //         ),
  //       );
  //     }
  //   }
  // }
}
