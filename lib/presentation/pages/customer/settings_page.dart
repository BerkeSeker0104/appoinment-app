import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/api_client.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/entities/user.dart';
import '../../../data/services/profile_api_service.dart';
import '../../widgets/guest_auth_overlay.dart';
import '../auth/welcome_page.dart';
import 'customer_edit_profile_page.dart';
import 'customer_change_phone_page.dart';
import '../company/company_edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService();
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());
  final ProfileApiService _profileApiService = ProfileApiService();

  String _selectedLanguage = 'tr';
  bool _isLoading = true;
  bool _isDeleting = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      await _settingsService.initialize();

      final results = await Future.wait([
        _settingsService.getAppLanguage(),
        _authUseCases.getCurrentUser(),
      ]);

      if (mounted) {
        setState(() {
          _selectedLanguage = results[0] as String;
          _currentUser = results[1] as User?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildLanguageSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildResetSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildLanguageSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSettingsCard(
      title: l10n.language,
      icon: Icons.language_outlined,
      children: [
        _buildLanguageDropdown(),
      ],
    );
  }

  Widget _buildProfileSection() {
    final isCompany = _currentUser?.isCompany ?? false;
    
    return GuestAuthOverlay(
      child: _buildSettingsCard(
        title: AppLocalizations.of(context)!.profileSettings,
        icon: Icons.person_outlined,
        children: [
          _buildActionOption(
            isCompany ? AppLocalizations.of(context)!.editIban : AppLocalizations.of(context)!.editProfileTitle,
            isCompany ? AppLocalizations.of(context)!.editIbanSubtitle : AppLocalizations.of(context)!.editProfileSubtitle,
            Icons.edit_outlined,
            () => _navigateToEditProfile(),
          ),
          _buildMenuDivider(),
          _buildActionOption(
            AppLocalizations.of(context)!.changePhone,
            AppLocalizations.of(context)!.changePhoneSubtitle,
            Icons.phone_outlined,
            () => _navigateToChangePhone(),
          ),
        ],
      ),
    );
  }

  Widget _buildResetSection() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSettingsCard(
      title: l10n.account,
      icon: Icons.account_circle_outlined,
      children: [
        _buildActionOption(
          AppLocalizations.of(context)!.deleteAccount,
          AppLocalizations.of(context)!.deleteAccountConfirmMessage,
          Icons.delete_outline,
          () => _showDeleteAccountDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }


  Widget _buildLanguageDropdown() {
    final l10n = AppLocalizations.of(context)!;
    final localeService = Provider.of<LocaleService>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appLanguage,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.appLanguageSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _selectedLanguage,
            underline: Container(),
            items: localeService.availableLanguages.map((language) {
              return DropdownMenuItem<String>(
                value: language['code'],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      language['flag']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      language['name']!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                _updateLanguage(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDestructive
                          ? AppColors.error
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      color: AppColors.border,
    );
  }

  void _navigateToEditProfile() async {
    // Check if user is guest
    final apiClient = ApiClient();
    final token = await apiClient.getToken();
    if (token == null) {
      // Guest user - overlay will handle it
      return;
    }

    final isCompany = _currentUser?.isCompany ?? false;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => isCompany
            ? const CompanyEditProfilePage()
            : CustomerEditProfilePage(
                initialUser: _currentUser,
              ),
      ),
    );

    // If profile was updated, reload user data
    if (result == true) {
      _loadSettings();
    }
  }

  void _navigateToChangePhone() async {
    // Check if user is guest
    final apiClient = ApiClient();
    final token = await apiClient.getToken();
    if (token == null) {
      // Guest user - overlay will handle it
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerChangePhonePage(),
      ),
    );

    // If phone was changed, reload user data
    if (result == true) {
      _loadSettings();
    }
  }

  Future<void> _updateLanguage(String languageCode) async {
    try {
      await _settingsService.setAppLanguage(languageCode);
      final localeService = Provider.of<LocaleService>(context, listen: false);
      await localeService.setLanguage(languageCode);

      setState(() {
        _selectedLanguage = languageCode;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSuccessSnackBar(l10n.languageUpdateSuccess);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorSnackBar(l10n.languageUpdateError);
      }
    }
  }



  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
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
        _showErrorSnackBar('Kullanıcı bilgileri yüklenemedi');
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
        _showErrorSnackBar(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }
}
