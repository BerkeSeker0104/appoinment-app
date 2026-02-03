import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/premium_input.dart';
import '../../widgets/iban_input.dart';
import '../../widgets/address_picker_widget.dart';
import '../../widgets/location_dropdown_widget.dart';
import 'sms_verification_page.dart';
import '../customer/terms_of_use_page.dart';
import '../../../data/services/company_api_service.dart';
import '../../../data/models/company_type_model.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/services/auth_api_service.dart';

class CompanyRegisterPage extends StatefulWidget {
  const CompanyRegisterPage({super.key});

  @override
  State<CompanyRegisterPage> createState() => _CompanyRegisterPageState();
}

class _CompanyRegisterPageState extends State<CompanyRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneCodeController = TextEditingController(text: '90');
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Company fields
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyPhoneCodeController = TextEditingController(text: '90');
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _taxNumberController = TextEditingController();

  // Company location coordinates
  double? _companyLatitude;
  double? _companyLongitude;

  // Location dropdowns
  int? _selectedCountryId;
  int? _selectedCityId;
  int? _selectedStateId;

  // Location isimleri (bias için)
  String? _selectedCountryName;
  String? _selectedCityName;
  String? _selectedStateName;

  // Document fields - UPDATED
  final _ibanController = TextEditingController(); // YENİ
  final _referenceCodeController = TextEditingController(); // REFERANS KODU

  // Payment types
  List<String> _selectedPaidTypes = [];

  bool _isLoading = false;
  bool _isLoadingCompanyTypes = false;
  bool _isUploadingFile = false;
  String? _errorMessage;
  String _selectedGender = 'none';
  int? _selectedCompanyTypeId;
  bool _acceptedTerms = false; // Terms of Use acceptance status

  // Company types
  List<CompanyTypeModel> _companyTypes = [];
  final CompanyApiService _companyApiService = CompanyApiService();
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());

  // File picker
  final ImagePicker _picker = ImagePicker();
  File? _taxPlate; // YENİ (eski: _proQualification)
  File? _masterCertificate;
  // _idCardFront ve _idCardBack KALDIRILACAK

  @override
  void initState() {
    super.initState();
    _loadCompanyTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneCodeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyPhoneCodeController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _taxNumberController.dispose();
    _ibanController.dispose();
    _referenceCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                _buildHeader(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildPersonalInfoSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildCompanyInfoSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildPaymentTypesSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildDocumentsSection(),
                const SizedBox(height: AppSpacing.xxxl),
                _buildTermsAcceptanceSection(),
                const SizedBox(height: AppSpacing.lg),
                _buildRegisterButton(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildErrorMessage(),
                ],
                const SizedBox(height: AppSpacing.xl),
                _buildLoginPrompt(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.companyRegisterTitle,
          style: AppTypography.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.companyRegisterSubtitle,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.personalInfo,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: PremiumInput(
                label: l10n.firstName,
                hint: l10n.enterFirstName,
                controller: _nameController,
                prefixIcon: Icons.person_outline,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.firstNameRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PremiumInput(
                label: l10n.lastName,
                hint: l10n.enterLastName,
                controller: _surnameController,
                prefixIcon: Icons.person_outline,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.lastNameRequired;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumInput(
          label: l10n.email,
          hint: l10n.enterEmail,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.emailRequired;
            }
            if (!value.contains('@')) {
              return l10n.validEmail;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: PremiumInput(
                label: l10n.countryCode,
                hint: '90',
                controller: _phoneCodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                prefixIcon: Icons.flag,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.countryCodeRequired;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              flex: 5,
              child: PremiumInput(
                label: l10n.phoneNumber,
                hint: '555 555 5555',
                controller: _phoneController,
                isPhoneNumber: true,
                prefixIcon: Icons.phone,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.phoneNumberRequired;
                  }
                  // Sadece rakamları kontrol et
                  final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (digitsOnly.length != 10) {
                    return l10n.phoneNumber10Digits;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildGenderSelector(),
        const SizedBox(height: AppSpacing.lg),
        PremiumInput(
          label: l10n.password,
          hint: l10n.enterPasswordPlaceholder,
          controller: _passwordController,
          isPassword: true,
          prefixIcon: Icons.lock_outlined,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.passwordRequired;
            }
            if (value.length < 6) {
              return l10n.passwordLengthError;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumInput(
          label: l10n.confirmPassword,
          hint: l10n.enterConfirmPassword,
          controller: _confirmPasswordController,
          isPassword: true,
          prefixIcon: Icons.lock_outlined,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.confirmPasswordRequired;
            }
            if (value != _passwordController.text) {
              return l10n.passwordsDoNotMatch;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        // Referans Kodu
        _buildReferenceCodeField(),
      ],
    );
  }

  Widget _buildReferenceCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referans Kodu (Opsiyonel)',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusMd),
                    bottomLeft: Radius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  'M&W-',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _referenceCodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: '6 haneli kod girin',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Bir arkadaşınız sizi davet ettiyse kodunu girin',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyInfoSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.companyInfo,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumInput(
          label: 'İşletme Adı',
          hint: 'İşletme adınızı girin',
          controller: _companyNameController,
          prefixIcon: Icons.business,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'İşletme adı gerekli';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildCompanyTypeDropdown(),
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
        AddressPickerWidget(
          label: 'İşletme Adresi',
          hint: 'Sokak, cadde ve kapı numarasını girin',
          initialValue: _companyAddressController.text.isNotEmpty
              ? _companyAddressController.text
              : null,
          isRequired: true,
          countryCode: _selectedCountryName, // Bias için
          cityName: _selectedCityName, // Bias için
          districtName: _selectedStateName, // Bias için
          enableGeocoding: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'İşletme adresi gerekli';
            }
            if (_companyLatitude == null || _companyLongitude == null) {
              return 'Lütfen listeden bir adres seçin veya geçerli bir adres girin';
            }
            return null;
          },
          onAddressSelected: (address, latitude, longitude) {
            _companyAddressController.text = address;
            _companyLatitude = latitude;
            _companyLongitude = longitude;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: PremiumInput(
                label: 'Ülke Kodu',
                hint: '90',
                controller: _companyPhoneCodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                prefixIcon: Icons.flag,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ülke kodu gerekli';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              flex: 5,
              child: PremiumInput(
                label: 'İşletme Telefonu',
                hint: '555 555 5555',
                controller: _companyPhoneController,
                isPhoneNumber: true, // DÜZELTİLDİ: Telefon formatı aktif
                textInputAction:
                    TextInputAction.done, // DÜZELTİLDİ: Otomatik geçişi engelle
                prefixIcon: Icons.phone,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'İşletme telefonu gerekli';
                  }
                  if (value.length < 10) {
                    return 'Geçerli bir telefon numarası girin';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumInput(
          label: 'İşletme E-posta',
          hint: 'İşletme e-posta adresinizi girin',
          controller: _companyEmailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'İşletme e-posta adresi gerekli';
            }
            if (!value.contains('@')) {
              return 'Geçerli bir e-posta adresi girin';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumInput(
          label: 'Vergi Numarası',
          hint: 'Vergi numaranızı girin',
          controller: _taxNumberController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.receipt_long,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vergi numarası gerekli';
            }
            // Sadece rakamları kontrol et
            final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
            if (digitsOnly.length != 10) {
              return 'Vergi numarası 10 haneli olmalıdır';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Belgeler',
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // IBAN Input
        IbanInput(
          label: 'IBAN',
          hint: 'IBAN numaranızı girin',
          controller: _ibanController,
          prefixIcon: Icons.account_balance,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'IBAN gerekli';
            }
            // Temiz IBAN kontrolü (TR + 24 rakam)
            final cleanIban =
                value.replaceAll(RegExp(r'[^\dA-Za-z]'), '').toUpperCase();
            if (!cleanIban.startsWith('TR') || cleanIban.length != 26) {
              return 'Geçerli bir TR IBAN girin (TR + 24 hane)';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        // Vergi Levhası
        _buildDocumentPicker(
          'Vergi Levhası',
          _taxPlate,
          (file) => setState(() => _taxPlate = file),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Ustalık, Kalfalık, Mesleki yeterlilik belgesi (Korunuyor)
        _buildDocumentPicker(
          'Ustalık, Kalfalık, Mesleki yeterlilik belgesi',
          _masterCertificate,
          (file) => setState(() => _masterCertificate = file),
        ),
      ],
    );
  }

  Widget _buildDocumentPicker(
    String title,
    File? file,
    Function(File?) onFileSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _isUploadingFile ? null : () => _pickImage(onFileSelected),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: file != null ? AppColors.primary : AppColors.border,
                width: 1,
              ),
            ),
            child: _isUploadingFile
                ? _buildFileUploadingIndicator()
                : file != null
                    ? _buildFilePreview(file, onFileSelected)
                    : _buildFileUploadPrompt(),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadPrompt() {
    return Row(
      children: [
        Icon(
          Icons.upload_file,
          color: AppColors.textSecondary,
          size: AppSpacing.iconMd,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dosya seçin',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'JPG, PNG, GIF, WEBP, AVIF formatları desteklenir',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary,
          size: AppSpacing.iconSm,
        ),
      ],
    );
  }

  Widget _buildFileUploadingIndicator() {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dosya işleniyor...',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lütfen bekleyin',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.7, // %70 progress
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePreview(File file, Function(File?) onFileSelected) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Icon(
                _getFileIcon(file.path),
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.path.split('/').last,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getFileSize(file),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _previewFile(file),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.visibility,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onFileSelected(null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.close, color: AppColors.error, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 1.0, // Dosya yüklendi, %100
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getFileIcon(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'avif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Boyut bilinmiyor';
    }
  }

  void _previewFile(File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dosya Önizleme',
                        style: AppTypography.h6.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Dosya önizlenemedi',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bu dosya türü desteklenmiyor',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gender,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _buildGenderOption(l10n.male, 'male')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildGenderOption(l10n.female, 'female')),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildGenderOption(l10n.none, 'none'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, String value) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    final l10n = AppLocalizations.of(context)!;
    return PremiumButton(
      text: l10n.createAccount,
      onPressed: _isLoading ? null : _handleRegister,
      isLoading: _isLoading,
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppSpacing.iconSm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${l10n.alreadyHaveAccount} ",
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            l10n.signIn,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(Function(File?) onFileSelected) async {
    // Show bottom sheet with options
    final dynamic source = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageSourceBottomSheet(),
    );

    if (source == null) {
      return;
    }

    setState(() {
      _isUploadingFile = true;
      _errorMessage = null;
    });

    try {
      File? file;
      if (source == 'file') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        );
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
        }
      } else if (source is ImageSource) {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          file = File(image.path);
        }
      }

      if (file != null) {
        final fileSize = file.lengthSync();
        final maxSize = 10 * 1024 * 1024; // 10MB limit

        if (fileSize > maxSize) {
          setState(() {
            _errorMessage = 'Dosya boyutu çok büyük. Maksimum 10MB olmalıdır.';
          });
          return;
        }

        // Dosya formatı kontrolü
        final extension = file.path.split('.').last.toLowerCase();
        final allowedFormats = ['jpg', 'jpeg', 'png', 'pdf'];
        if (!allowedFormats.contains(extension)) {
          setState(() {
            _errorMessage =
                'Desteklenmeyen dosya formatı. Sadece JPG, PNG ve PDF dosyaları kabul edilir.';
          });
          return;
        }

        // Simulate file processing delay
        await Future.delayed(const Duration(milliseconds: 500));
        onFileSelected(file);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Dosya seçilirken hata oluştu: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUploadingFile = false;
      });
    }
  }

  Widget _buildImageSourceBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Dosya Seç',
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              title: Text(
                'Galeri',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Galeriden fotoğraf seç',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              title: Text(
                'Kamera',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Fotoğraf çek',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_open,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              title: Text(
                'Dosya',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'PDF veya diğer dosyalar',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCompanyTypes() async {
    setState(() {
      _isLoadingCompanyTypes = true;
      _errorMessage = null;
    });

    try {
      final companyTypes = await _companyApiService.getCompanyTypes();
      if (mounted) {
        setState(() {
          _companyTypes = companyTypes;
          _isLoadingCompanyTypes = false;
        });

        // Eğer hiç company type yoksa kullanıcıya bilgi ver
        if (companyTypes.isEmpty) {
          setState(() {
            _errorMessage =
                'İşletme türleri bulunamadı. Lütfen daha sonra tekrar deneyin.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'İşletme türleri yüklenemedi: ${e.toString()}';
          _isLoadingCompanyTypes = false;
        });
      }
    }
  }

  Widget _buildCompanyTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İşletme Türü',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedCompanyTypeId == null
                  ? AppColors.border
                  : AppColors.primary,
            ),
          ),
          child: _isLoadingCompanyTypes
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'İşletme türleri yükleniyor...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCompanyTypeId,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _companyTypes.isEmpty
                            ? 'İşletme türü bulunamadı'
                            : 'İşletme türü seçin',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    isExpanded: true,
                    items: _companyTypes.isEmpty
                        ? []
                        : _companyTypes.map((
                            CompanyTypeModel companyType,
                          ) {
                            return DropdownMenuItem<int>(
                              value: int.parse(companyType.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  companyType.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    onChanged: _companyTypes.isEmpty
                        ? null
                        : (int? newValue) {
                            setState(() {
                              _selectedCompanyTypeId = newValue;
                            });
                          },
                  ),
                ),
        ),
        if (_selectedCompanyTypeId == null && !_isLoadingCompanyTypes)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              'İşletme türü gerekli',
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ),
        if (_companyTypes.isEmpty && !_isLoadingCompanyTypes)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'İşletme türleri yüklenemedi',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadCompanyTypes,
                  child: Text(
                    'Tekrar Dene',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'İşletmenizde kabul ettiğiniz ödeme yöntemlerini seçin',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
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

  Widget _buildTermsAcceptanceSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() {
                _acceptedTerms = value ?? false;
                // Clear error message when user accepts terms
                if (_acceptedTerms && _errorMessage == l10n.termsAcceptanceRequired) {
                  _errorMessage = null;
                }
              });
            },
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: () {
                  // Navigate to Terms of Use page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TermsOfUsePage(),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: l10n.termsAcceptance.split('Kullanım Koşulları')[0],
                      ),
                      TextSpan(
                        text: l10n.termsOfUse,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      if (l10n.termsAcceptance.split('Kullanım Koşulları').length > 1)
                        TextSpan(
                          text: l10n.termsAcceptance.split('Kullanım Koşulları')[1],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCompanyTypeId == null) {
      setState(() {
        _errorMessage = 'İşletme türü seçin';
      });
      return;
    }

    // Check if terms are accepted
    final l10n = AppLocalizations.of(context)!;
    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = l10n.termsAcceptanceRequired;
      });
      return;
    }

    if (_selectedCountryId == null ||
        _selectedCityId == null ||
        _selectedStateId == null) {
      setState(() {
        _errorMessage = 'Konum bilgilerini tamamlayın';
      });
      return;
    }

    // Koordinat kontrolü - hem dropdown hem adres seçimi için gerekli
    if (_companyLatitude == null || _companyLongitude == null) {
      setState(() {
        _errorMessage = 'Lütfen geçerli bir adres seçin veya girin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Referans kodu - sadece 6 haneli ise gönder
      final refCode = _referenceCodeController.text.trim();
      final referenceNumber = refCode.length == 6 ? 'M&W-$refCode' : null;

      // Önce kullanıcıyı kaydet
      await _authUseCases.companyRegister(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        phoneCode: _phoneCodeController.text.trim(),
        phone: _phoneController.text.replaceAll(' ', ''),
        password: _passwordController.text,
        gender: _selectedGender,
        companyName: _companyNameController.text.trim(),
        companyType: _selectedCompanyTypeId!,
        companyAddress: _companyAddressController.text.trim(),
        companyPhoneCode: _companyPhoneCodeController.text.trim(),
        companyPhone: _companyPhoneController.text.replaceAll(' ', ''),
        companyEmail: _companyEmailController.text.trim(),
        companyLatitude: _companyLatitude, // ✅ KORUNUYOR
        companyLongitude: _companyLongitude, // ✅ KORUNUYOR
        countryId: _selectedCountryId!, // YENİ
        cityId: _selectedCityId!, // YENİ
        stateId: _selectedStateId!, // YENİ
        iban: _ibanController.text.trim(), // YENİ
        taxNumber: _taxNumberController.text.replaceAll(RegExp(r'[^\d]'), ''), // YENİ
        taxPlate: _taxPlate, // YENİ
        masterCertificate: _masterCertificate, // MEVCUT
        paidTypes:
            _selectedPaidTypes.join(','), // YENİ - virgülle ayrılmış string
        referenceNumber: referenceNumber, // REFERANS KODU
      );

      // Kayıt başarılı olduktan sonra SMS doğrulama sayfasına yönlendir
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SmsVerificationPage(
              phoneCode: _phoneCodeController.text.trim(),
              phone: _phoneController.text.replaceAll(' ', ''),
              name: _nameController.text.trim(),
              surname: _surnameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              gender: _selectedGender,
              companyName: _companyNameController.text.trim(),
              companyType: _selectedCompanyTypeId!.toString(),
              companyAddress: _companyAddressController.text.trim(),
              companyPhoneCode: _companyPhoneCodeController.text.trim(),
              companyPhone: _companyPhoneController.text.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', ''),
              companyEmail: _companyEmailController.text.trim(),
              isCompanyRegistration: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // CompanyRegistrationSuccessException yakalanırsa SMS sayfasına yönlendir
        if (e is CompanyRegistrationSuccessException ||
            e.toString().contains('SMS doğrulama için yönlendiriliyorsunuz')) {
          // Kayıt başarılı, SMS doğrulama sayfasına yönlendir
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SmsVerificationPage(
                phoneCode: _phoneCodeController.text.trim(),
                phone: _phoneController.text.replaceAll(' ', ''),
                name: _nameController.text.trim(),
                surname: _surnameController.text.trim(),
                email: _emailController.text.trim(),
                password: _passwordController.text,
                gender: _selectedGender,
                companyName: _companyNameController.text.trim(),
                companyType: _selectedCompanyTypeId!.toString(),
                companyAddress: _companyAddressController.text.trim(),
                companyPhoneCode: _companyPhoneCodeController.text.trim(),
                companyPhone: _companyPhoneController.text.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', ''),
                companyEmail: _companyEmailController.text.trim(),
                isCompanyRegistration: true,
              ),
            ),
          );
          return;
        }

        String errorMessage = e.toString().replaceFirst('Exception: ', '');

        // Eğer sunucu hatası ise retry önerisi ekle
        if (errorMessage.contains('Sunucu hatası')) {
          errorMessage += '\n\nLütfen birkaç dakika sonra tekrar deneyin.';
        }

        setState(() {
          _errorMessage = errorMessage;
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
}
