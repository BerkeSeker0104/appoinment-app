import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/services/profile_api_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/entities/user.dart';
import '../auth/welcome_page.dart';
import '../../widgets/premium_input.dart';
import '../../widgets/premium_button.dart';
import '../../widgets/iban_input_formatter.dart';

class CompanyEditProfilePage extends StatefulWidget {
  const CompanyEditProfilePage({super.key});

  @override
  State<CompanyEditProfilePage> createState() => _CompanyEditProfilePageState();
}

class _CompanyEditProfilePageState extends State<CompanyEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _ibanController = TextEditingController();

  final ProfileApiService _profileApiService = ProfileApiService();
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());

  bool _isLoading = false;
  bool _isLoadingUser = true;
  bool _isDeleting = false;
  String? _errorMessage;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authUseCases.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      // Ignore error
    }
  }

  @override
  void dispose() {
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoadingUser = true;
        _errorMessage = null;
      });

      // Get current user from profile API (raw data to access IBAN)
      final profileData = await _profileApiService.getProfileRaw();
      
      // IBAN bilgisini profile'dan al (eğer varsa)
      // Backend'den gelen response'da iban field'ı olabilir
      if (profileData['iban'] != null) {
        final iban = profileData['iban'].toString();
        // IBAN'dan sadece rakamları çıkar (boşlukları ve TR'yi kaldır)
        final cleanIban = iban.replaceAll(RegExp(r'[^\d]'), '');
        
        // TR'yi kaldır (ilk 2 rakam genelde 50)
        String digitsOnly;
        if (cleanIban.length >= 2 && cleanIban.substring(0, 2) == '50') {
          // TR50 ile başlıyorsa, ilk 2 rakamı dahil et
          digitsOnly = cleanIban.length > 24 
              ? cleanIban.substring(0, 24) 
              : cleanIban;
        } else {
          // Sadece rakamlar varsa direkt kullan
          digitsOnly = cleanIban.length > 24 
              ? cleanIban.substring(0, 24) 
              : cleanIban;
        }
        
        // Formatter'ı kullanarak formatla
        final formattedValue = IbanInputFormatter.formatIban(digitsOnly);
        _ibanController.text = formattedValue;
      } else {
        // Eğer IBAN yoksa, sadece TR göster
        _ibanController.text = 'TR';
      }
      
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
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
          AppLocalizations.of(context)!.editProfileTitle,
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
                      _buildForm(),
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
          AppLocalizations.of(context)!.editIban,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context)!.youCanUpdateIban,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        PremiumInput(
          label: AppLocalizations.of(context)!.iban,
          hint: 'TR50 0000 0022 3333 4444 77',
          controller: _ibanController,
          prefixIcon: Icons.account_balance_outlined,
          isRequired: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            IbanInputFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty || value == 'TR') {
              return AppLocalizations.of(context)!.ibanRequired;
            }
            // Basic IBAN format validation (TR followed by 24 digits)
            final cleanIban = value.replaceAll(' ', '').toUpperCase();
            if (!cleanIban.startsWith('TR')) {
              return AppLocalizations.of(context)!.ibanStartExact;
            }
            final digitsOnly = cleanIban.substring(2);
            if (digitsOnly.length != 24) {
              return AppLocalizations.of(context)!.ibanLengthExact;
            }
            if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
              return AppLocalizations.of(context)!.ibanDigitsOnly;
            }
            return null;
          },
        ),
      ],
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

    try {
      // IBAN zaten formatter tarafından boşluklu formatta formatlanmış durumda
      // Direkt olarak gönderebiliriz: "TR50 0000 0022 3333 4444 77"
      final formattedIban = _ibanController.text.toUpperCase().trim();

      await _profileApiService.updateCompanyProfile(
        iban: formattedIban,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.ibanUpdateSuccess),
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

