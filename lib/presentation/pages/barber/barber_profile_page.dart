import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../widgets/premium_button.dart';
import '../auth/welcome_page.dart';

class BarberProfilePage extends StatefulWidget {
  const BarberProfilePage({super.key});

  @override
  State<BarberProfilePage> createState() => _BarberProfilePageState();
}

class _BarberProfilePageState extends State<BarberProfilePage> {
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());
  User? _currentUser;
  bool _isLoading = true;
  bool isOpen = true;
  bool notificationsEnabled = true;
  bool autoAcceptAppointments = false;
  bool showPhoneNumber = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authUseCases.getCurrentUser().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Bağlantı zaman aşımına uğradı'),
      );
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Check if this is an auth error (401 or unauthorized)
      if (_isAuthError(e)) {
        _navigateToLogin();
        return;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
        errorString.contains('unauthorized') ||
        errorString.contains('oturum') ||
        errorString.contains('token');
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppSpacing.lg),
              _buildProfileSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildBusinessSettingsSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildServicesSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildNotificationSettings(),
              const SizedBox(height: AppSpacing.lg),
              _buildSupportSection(),
              const SizedBox(height: AppSpacing.lg),
              _buildAccountSection(),
              const SizedBox(height: AppSpacing.xxxl),
              // Navigation bar için extra space
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Hesap ayarlarınızı yönetin',
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

  Widget _buildProfileSection() {
    final name = _currentUser?.name ?? '-';
    final email = _currentUser?.email ?? '-';
    final phone = _currentUser?.phone ?? '-';
    final createdAt =
        _currentUser?.createdAt != null
            ? _formatDate(_currentUser!.createdAt)
            : '-';

    return _buildSection(
      title: 'Profil Bilgileri',
      icon: Icons.person,
      children: [
        _buildSettingItem('Ad Soyad', _isLoading ? 'Yükleniyor...' : name),
        _buildSettingItem('E-posta', _isLoading ? 'Yükleniyor...' : email),
        _buildSettingItem('Telefon', _isLoading ? 'Yükleniyor...' : phone),
        _buildSettingItem(
          'Kayıt Tarihi',
          _isLoading ? 'Yükleniyor...' : createdAt,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildBusinessSettingsSection() {
    final companyName = _currentUser?.name ?? '-';

    return _buildSection(
      title: 'İşletme Ayarları',
      icon: Icons.business,
      children: [
        _buildSettingItem(
          'İşletme Durumu',
          isOpen ? 'Açık' : 'Kapalı',
          trailing: Switch(
            value: isOpen,
            onChanged: (value) => setState(() => isOpen = value),
            activeColor: AppColors.success,
          ),
        ),
        _buildSettingItem(
          'İşletme Adı',
          _isLoading ? 'Yükleniyor...' : companyName,
        ),
        _buildSettingItem('Adres', '-'),
        _buildSettingItem('Çalışma Saatleri', '-'),
        _buildSettingItem(
          'Telefon Numarasını Göster',
          showPhoneNumber ? 'Evet' : 'Hayır',
          trailing: Switch(
            value: showPhoneNumber,
            onChanged: (value) => setState(() => showPhoneNumber = value),
            activeColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    return _buildSection(
      title: 'Hizmetler',
      icon: Icons.content_cut,
      children: [
        // TODO: Replace with real services data from API
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Hizmetler yükleniyor...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: PremiumButton(
                text: 'Hizmet Ekle',
                onPressed: () {},
                variant: ButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: PremiumButton(
                text: 'Düzenle',
                onPressed: () {},
                variant: ButtonVariant.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return _buildSection(
      title: 'Bildirim Ayarları',
      icon: Icons.notifications,
      children: [
        _buildSettingItem(
          'Bildirimleri Etkinleştir',
          notificationsEnabled ? 'Açık' : 'Kapalı',
          trailing: Switch(
            value: notificationsEnabled,
            onChanged: (value) => setState(() => notificationsEnabled = value),
            activeColor: AppColors.primary,
          ),
        ),
        _buildSettingItem(
          'Otomatik Randevu Onayı',
          autoAcceptAppointments ? 'Açık' : 'Kapalı',
          trailing: Switch(
            value: autoAcceptAppointments,
            onChanged:
                (value) => setState(() => autoAcceptAppointments = value),
            activeColor: AppColors.primary,
          ),
        ),
        _buildSettingItem('E-posta Bildirimleri', 'Açık'),
        _buildSettingItem('SMS Bildirimleri', 'Kapalı'),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildSection(
      title: 'Destek',
      icon: Icons.help,
      children: [
        _buildSettingItem('Yardım Merkezi', ''),
        _buildSettingItem('İletişim', ''),
        _buildSettingItem('Geri Bildirim Gönder', ''),
        _buildSettingItem('Hakkında', 'Versiyon 1.0.0'),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Hesap',
      icon: Icons.account_circle,
      children: [
        PremiumButton(
          text: 'Şifremi Değiştir',
          onPressed: () {},
          variant: ButtonVariant.secondary,
          isFullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        PremiumButton(
          text: 'Çıkış Yap',
          onPressed: _logout,
          variant: ButtonVariant.secondary,
          isFullWidth: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        PremiumButton(
          text: 'Hesabı Sil',
          onPressed: _deleteAccount,
          variant: ButtonVariant.secondary,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTypography.h6.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, String value, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (value.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else
            Icon(
              Icons.arrow_forward_ios,
              size: AppSpacing.iconSm,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Çıkış Yap'),
            content: const Text(
              'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => _performLogout(context),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hesabı Sil'),
            content: const Text(
              'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement account deletion
                },
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }

  // JWT Token Destroy - No API call needed
  void _performLogout(BuildContext dialogContext) async {
    // Store the navigator before any async operations
    final navigator = Navigator.of(context);
    
    try {
      // Close confirmation dialog first
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Perform JWT logout with timeout - destroy token locally
      try {
        await _authUseCases.signOut().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            // Timeout - still proceed with logout
          },
        );
      } catch (_) {
        // Ignore errors - we'll navigate to welcome page anyway
      }

      // Navigate to welcome page - close all dialogs and routes
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      // Even if anything fails, still navigate to welcome page
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
        );
      }
    }
  }
}
