import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/entities/user.dart';
import '../../../data/services/profile_api_service.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../auth/welcome_page.dart';
import '../../widgets/premium_input.dart';
import '../../widgets/premium_button.dart';

class CustomerEditProfilePage extends StatefulWidget {
  final User? initialUser;

  const CustomerEditProfilePage({super.key, this.initialUser});

  @override
  State<CustomerEditProfilePage> createState() => _CustomerEditProfilePageState();
}

class _CustomerEditProfilePageState extends State<CustomerEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ProfileApiService _profileApiService = ProfileApiService();
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());

  bool _isLoading = false;
  bool _isLoadingUser = true;
  bool _isDeleting = false;
  String? _errorMessage;
  String _selectedGender = 'none';
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoadingUser = true;
        _errorMessage = null;
      });

      // Get current user from auth or profile API
      User? user = widget.initialUser;
      if (user == null) {
        user = await _authUseCases.getCurrentUser();
      }

      String? name;
      String? surname;
      String? email;
      Map<String, dynamic>? rawProfileData;

      // Her zaman profile API'den raw data'yı al (gender, surname gibi ek bilgiler için)
      try {
        rawProfileData = await _profileApiService.getProfileRaw();
        if (user == null) {
          final profileUser = await _profileApiService.getProfile();
          user = profileUser.toEntity();
        }
      } catch (e) {
        // Profile API'den alınamazsa devam et
      }

      // User bilgilerini al
      if (user == null) {
        user = await _authUseCases.getCurrentUser();
      }
      
      if (user != null) {
        name = user.name;
        email = user.email;
      }

      // Backend'den surname geliyorsa onu kullan, yoksa name'den ayır
      if (rawProfileData != null && rawProfileData['surname'] != null) {
        surname = rawProfileData['surname'].toString();
      } else if (name != null && name.isNotEmpty) {
        // Ad ve soyadı ayır
        // Eğer name "Berke Şeker" gibi birleşik geliyorsa, boşluktan böl
        final nameParts = name.trim().split(' ');
        if (nameParts.length > 1) {
          // İlk kısım ad, geri kalanı soyad
          name = nameParts.first;
          surname = nameParts.sublist(1).join(' ');
        } else {
          // Sadece tek kelime varsa, o ad
          name = nameParts.first;
          surname = '';
        }
      }

      // Backend'den gender bilgisini al
      // NOT: Backend'den gender field'ı gelmiyor (sadece: id, phone, phoneCode, email, type, name, permission)
      // Bu yüzden varsayılan olarak 'none' kullanıyoruz
      String? gender;
      if (rawProfileData != null && rawProfileData.isNotEmpty) {
        // Farklı field isimlerini kontrol et
        gender = rawProfileData['gender']?.toString() ?? 
                 rawProfileData['Gender']?.toString() ?? 
                 rawProfileData['userGender']?.toString() ?? 
                 rawProfileData['user_gender']?.toString();
        
        if (gender != null) {
          gender = gender.toLowerCase().trim();
        }
      }

      if (mounted) {
        setState(() {
          if (user != null) {
            _currentUser = user;
            _nameController.text = name ?? '';
            _surnameController.text = surname ?? '';
            _emailController.text = email ?? '';
            
            // Gender bilgisini ayarla
            if (gender != null && gender.isNotEmpty) {
              final genderLower = gender.toLowerCase().trim();
              if (genderLower == 'male' || genderLower == 'erkek' || genderLower == 'm') {
                _selectedGender = 'male';
              } else if (genderLower == 'female' || genderLower == 'kadın' || genderLower == 'f' || genderLower == 'kadin') {
                _selectedGender = 'female';
              } else {
                _selectedGender = 'none';
              }
            } else {
              // Gender bilgisi yoksa varsayılan olarak 'none'
              _selectedGender = 'none';
            }
          }
          _isLoadingUser = false;
          if (user == null) {
            _errorMessage = AppLocalizations.of(context)!.userDataLoadError;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
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
        title: Text(
          AppLocalizations.of(context)!.editProfilePageTitle,
          style: AppTypography.h5.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildForm(context),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _buildErrorMessage(),
                      ],
                      const SizedBox(height: AppSpacing.xxxl),
                      _buildSaveButton(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDeleteAccountButton(),
                      const SizedBox(height: AppSpacing.xl),
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
          AppLocalizations.of(context)!.editProfileHeader,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context)!.editProfileSubHeader,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
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
        _buildGenderSelector(),
        const SizedBox(height: AppSpacing.lg),
        PremiumInput(
          label: AppLocalizations.of(context)!.passwordOptionalLabel,
          hint: AppLocalizations.of(context)!.newPasswordHint,
          controller: _passwordController,
          isPassword: true,
          prefixIcon: Icons.lock_outlined,
          isRequired: false,
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length < 6) {
              return AppLocalizations.of(context)!.passwordMinLengthError;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumInput(
          label: AppLocalizations.of(context)!.confirmPasswordLabel,
          hint: AppLocalizations.of(context)!.confirmPasswordHint,
          controller: _confirmPasswordController,
          isPassword: true,
          prefixIcon: Icons.lock_outlined,
          isRequired: false,
          validator: (value) {
            // Eğer şifre girildiyse, confirm password da girilmeli
            if (_passwordController.text.isNotEmpty) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.reEnterPasswordError;
              }
              if (value != _passwordController.text) {
                return AppLocalizations.of(context)!.passwordsDoNotMatchError;
              }
            }
            // Eğer şifre girilmediyse, confirm password boş olabilir
            return null;
          },
        ),
      ],
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
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return PremiumButton(
      text: AppLocalizations.of(context)!.save,
      onPressed: _isLoading ? null : _handleSave,
      isLoading: _isLoading,
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      width: double.infinity,
      height: AppSpacing.buttonLarge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          onTap: _isDeleting ? null : _showDeleteAccountDialog,
          child: Container(
            height: AppSpacing.buttonLarge,
            alignment: Alignment.center,
            child: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.deleteAccount,
                    style: AppTypography.buttonMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Şifre kontrolü: Eğer şifre girildiyse, confirm password ile eşleşmeli
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    if (password.isNotEmpty && password != confirmPassword) {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.passwordsDoNotMatchError;
        _isLoading = false;
      });
      return;
    }

    try {
      await _profileApiService.updateCustomerProfile(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        gender: _selectedGender,
        password: password.isEmpty ? null : password,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profileUpdateSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteAccountConfirmTitle,
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteAccountConfirmMessage,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isDeleting ? null : () => _deleteAccount(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.delete,
                    style: AppTypography.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.userDataLoadError),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _profileApiService.deleteUser(_currentUser!.id);
      
      // Logout after successful deletion
      await _authUseCases.signOut();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.accountDeleteSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

