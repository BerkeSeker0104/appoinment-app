import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../../domain/usecases/auth_usecases.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/entities/user.dart';
import '../../../data/services/appointment_api_service.dart';
import '../../../data/services/favorite_api_service.dart';
import '../../providers/notification_provider.dart';
import '../../../data/services/profile_api_service.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/premium_button.dart';
import '../auth/welcome_page.dart';
import '../auth/phone_login_page.dart';
import '../auth/sign_up_page.dart';
import 'customer_bookings_page.dart';
import 'favorites_page.dart';
import 'customer_notifications_page.dart';
import 'following_list_page.dart';
import 'settings_page.dart';
import 'help_support_page.dart';
import 'about_page.dart';
import 'addresses_page.dart';
import 'customer_orders_page.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final AuthUseCases _authUseCases = AuthUseCases(AuthRepositoryImpl());
  final AppointmentApiService _appointmentService = AppointmentApiService();
  final FavoriteApiService _favoriteService = FavoriteApiService();
  final ProfileApiService _profileApiService = ProfileApiService();

  User? _currentUser;
  bool _isLoading = true;
  int _appointmentsCount = 0;
  int _favoritesCount = 0;
  String? _showAuthOverlay; // 'appointments' or 'favorites' or null

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // First, load user data from API for fresh data with referenceNumber
      final user = await _profileApiService.getProfile();
      
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
      
      // Then load counts in parallel - these are API calls that might fail
      // Don't let their failure affect the main user display
      try {
        final counts = await Future.wait([
          _loadAppointmentsCount(),
          _loadFavoritesCount(),
        ]).timeout(const Duration(seconds: 10));
        
        if (mounted) {
          setState(() {
            _appointmentsCount = counts[0];
            _favoritesCount = counts[1];
          });
        }
      } catch (e) {
        // Counts failed to load - that's okay, just use defaults
        if (kDebugMode) {
          debugPrint('CustomerProfilePage: Error loading counts: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CustomerProfilePage: Error loading user: $e');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<int> _loadAppointmentsCount() async {
    try {
      final appointments = await _appointmentService.getAppointments();
      return appointments.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _loadFavoritesCount() async {
    try {
      final favorites = await _favoriteService.getFavoritesList();
      return favorites.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildProfileCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickActions(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildMenuItems(context),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLogoutButton(),
                    const SizedBox(height: AppSpacing.xxxl),
                    // Navigation bar için extra space
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            // Auth overlay for guest users
            if (_showAuthOverlay != null) _buildAuthOverlay(),
          ],
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
                  AppLocalizations.of(context)!.profileTitle,
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.profileSubtitle,
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

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
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
        children: [
          // Profile Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: AppSpacing.md),

          // Name and Email
          Text(
            _isLoading
                ? AppLocalizations.of(context)!.userNameLoading
                : (_currentUser?.name ?? AppLocalizations.of(context)!.userNameDefault),
            style: AppTypography.h5.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _isLoading
                ? AppLocalizations.of(context)!.loading
                : (_currentUser?.email ?? 'email@example.com'),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          
          // Reference Number - tıklanınca kopyalama
          if (!_isLoading && _currentUser?.referenceNumber != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildReferenceNumberWidget(),
          ],
          
          const SizedBox(height: AppSpacing.lg),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(AppLocalizations.of(context)!.appointments, _appointmentsCount.toString()),
              Container(width: 1, height: 40, color: AppColors.divider),
              _buildStatItem(AppLocalizations.of(context)!.favorites, _favoritesCount.toString()),
              Container(width: 1, height: 40, color: AppColors.divider),
              _buildStatItem(
                  AppLocalizations.of(context)!.comments, '0'), // Yorumlar henüz implement edilmedi
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceNumberWidget() {
    final referenceNumber = _currentUser?.referenceNumber ?? '';
    // Sadece 6 rakamı çıkart (M&W- prefix'i olmadan)
    final digits = referenceNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    return GestureDetector(
      onTap: () {
        if (digits.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: digits));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.referenceNumberCopied),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              referenceNumber,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.people_outline_rounded,
                title: AppLocalizations.of(context)!.followingList,
                subtitle: AppLocalizations.of(context)!.followingListSubtitle,
                onTap: () => _navigateToFollowingList(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.favorite_outline,
                title: AppLocalizations.of(context)!.myFavorites,
                subtitle: AppLocalizations.of(context)!.likedBarbers,
                onTap: () => _navigateToFavorites(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
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
        children: [
          _buildMenuItem(
            Icons.notifications_outlined,
            AppLocalizations.of(context)!.notifications,
            () => _navigateToNotifications(),
            showBadge: true,
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            Icons.location_on_outlined,
            AppLocalizations.of(context)!.myAddresses,
            () => _navigateToAddresses(),
          ),
          _buildMenuDivider(),

          _buildMenuItem(
            Icons.shopping_bag_outlined,
            AppLocalizations.of(context)!.myOrders,
            () => _navigateToOrders(),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
              Icons.settings_outlined, AppLocalizations.of(context)!.settings, () => _navigateToSettings()),
          _buildMenuDivider(),
          _buildMenuItem(
            Icons.help_outline_rounded,
            AppLocalizations.of(context)!.helpSupport,
            () => _navigateToSupport(context),
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            Icons.info_outline_rounded,
            AppLocalizations.of(context)!.about,
            () => _navigateToAbout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
    bool showBadge = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (showBadge)
              Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  return BadgedIcon(
                    icon: Icon(
                      icon,
                      color: isDestructive
                          ? AppColors.error
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    badgeCount: provider.unreadCount,
                    badgeColor: AppColors.error,
                  );
                },
              )
            else
              Icon(
                icon,
                color:
                    isDestructive ? AppColors.error : AppColors.textSecondary,
                size: 20,
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color:
                      isDestructive ? AppColors.error : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
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

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(color: AppColors.error, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
          onTap: () => _showLogoutDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.radiusMd,
                    ),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  AppLocalizations.of(context)!.logout,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToBookings() async {
    // Check if user is guest
    final apiClient = ApiClient();
    final token = await apiClient.getToken();
    
    if (token == null) {
      // Show overlay on profile page
      setState(() {
        _showAuthOverlay = 'appointments';
      });
      return;
    }

    // Navigate to bookings page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerBookingsPage(),
      ),
    );
  }

  void _navigateToFavorites() async {
    // Check if user is guest
    final apiClient = ApiClient();
    final token = await apiClient.getToken();
    
    if (token == null) {
      // Show overlay on profile page
      setState(() {
        _showAuthOverlay = 'favorites';
      });
      return;
    }

    // Navigate to favorites page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FavoritesPage(),
      ),
    );
  }

  Widget _buildAuthOverlay() {
    final l10n = AppLocalizations.of(context)!;
    final title = _showAuthOverlay == 'appointments' 
        ? l10n.myAppointments 
        : l10n.myFavorites;
    
    return Stack(
      children: [
        // Blurred background
        Positioned.fill(
          child: Container(
            color: AppColors.background.withValues(alpha: 0.95),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
        // Auth card
        Positioned.fill(
          child: IgnorePointer(
            ignoring: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow.withValues(alpha: 0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showAuthOverlay = null;
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          l10n.pleaseSignInOrSignUp,
                          style: AppTypography.h5.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '${l10n.pleaseSignInOrSignUpMessage} ${l10n.toUseFeature(title)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        PremiumButton(
                          text: l10n.signIn,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PhoneLoginPage(),
                              ),
                            ).then((_) {
                              // Reload user data after login
                              _loadUserData();
                              setState(() {
                                _showAuthOverlay = null;
                              });
                            });
                          },
                          variant: ButtonVariant.primary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PremiumButton(
                          text: l10n.signUp,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpPage(),
                              ),
                            ).then((_) {
                              // Reload user data after signup
                              _loadUserData();
                              setState(() {
                                _showAuthOverlay = null;
                              });
                            });
                          },
                          variant: ButtonVariant.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HelpSupportPage(),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerNotificationsPage(),
      ),
    );
  }

  void _navigateToAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutPage(),
      ),
    );
  }

  void _navigateToAddresses() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressesPage(),
      ),
    );
  }

  void _navigateToFollowingList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FollowingListPage(),
      ),
    );
  }

  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerOrdersPage(),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Çıkış Yap',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Vazgeç',
              style: AppTypography.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _performLogout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Çıkış Yap',
              style: AppTypography.buttonMedium.copyWith(
                color: Colors.white,
              ),
            ),
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
