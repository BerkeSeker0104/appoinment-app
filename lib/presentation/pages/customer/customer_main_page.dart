import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/settings_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/custom_nav_bar.dart';
import 'customer_home_page.dart';
import 'customer_search_page.dart';
import 'customer_profile_page.dart';
import 'market_page.dart';
import 'customer_bookings_page.dart';
import '../../../core/services/push_notification_service.dart';

class CustomerMainPage extends StatefulWidget {
  final int? initialTab;

  const CustomerMainPage({super.key, this.initialTab});

  @override
  State<CustomerMainPage> createState() => _CustomerMainPageState();

  // Static method to navigate to map tab
  static void navigateToMapTab(BuildContext context) {
    final state = context.findAncestorStateOfType<_CustomerMainPageState>();
    state?.navigateToMapTab();
  }

  // Static method to navigate to profile tab
  static void navigateToProfileTab(BuildContext context) {
    final state = context.findAncestorStateOfType<_CustomerMainPageState>();
    state?.navigateToProfileTab();
  }

  // Static method to navigate to market tab
  static void navigateToMarketTab(BuildContext context) {
    final state = context.findAncestorStateOfType<_CustomerMainPageState>();
    state?.navigateToMarketTab();
  }

  // Static method to navigate to appointments tab
  static void navigateToAppointmentsTab(BuildContext context) {
    final state = context.findAncestorStateOfType<_CustomerMainPageState>();
    state?.navigateToAppointmentsTab();
  }

  // Static method to navigate to home tab
  static void navigateToHomeTab(BuildContext context) {
    final state = context.findAncestorStateOfType<_CustomerMainPageState>();
    state?.navigateToHomeTab();
  }
}

class _CustomerMainPageState extends State<CustomerMainPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  // Services
  final SettingsService _settingsService = SettingsService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();

  // Harita sekmesine geçmek için public method
  void navigateToMapTab() {
    setState(() {
      _currentIndex = 1; // Harita sekmesi index 1
    });
  }

  // Profil sekmesine geçmek için public method
  void navigateToProfileTab() {
    setState(() {
      _currentIndex = 4; // Profil sekmesi index 4
    });
  }

  // Market sekmesine geçmek için public method
  void navigateToMarketTab() {
    setState(() {
      _currentIndex = 3; // Market sekmesi index 3
    });
  }

  // Randevu sekmesine geçmek için public method
  void navigateToAppointmentsTab() {
    setState(() {
      _currentIndex = 2; // Randevu sekmesi index 2
    });
  }

  // Ana sayfa sekmesine geçmek için public method
  void navigateToHomeTab() {
    setState(() {
      _currentIndex = 0; // Ana sayfa sekmesi index 0
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize pages once to prevent re-creation
    _pages = [
      const CustomerHomePage(),
      const CustomerSearchPage(),
      const CustomerBookingsPage(),
      const MarketPage(),
      const CustomerProfilePage(),
    ];

    // Set initial tab if provided
    if (widget.initialTab != null) {
      _currentIndex = widget.initialTab!;
    }

    // Request permissions on first launch
    _requestPermissionsIfNeeded();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService().markAppReady();
    });
  }

  /// Request permissions on first launch after login
  Future<void> _requestPermissionsIfNeeded() async {
    try {
      // Check if permissions have been requested before
      final permissionsRequested =
          await _settingsService.getPermissionsRequested();

      if (!permissionsRequested) {
        // Wait a bit for the UI to settle
        await Future.delayed(const Duration(milliseconds: 1500));

        if (!mounted) return;

        // Request location permission first
        await _requestLocationPermission();

        // Wait a bit between permission requests
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Request notification permission
        await _requestNotificationPermission();

        // Mark permissions as requested
        await _settingsService.setPermissionsRequested(true);
      }
    } catch (e) {
    }
  }

  /// Request location permission directly from device
  Future<void> _requestLocationPermission() async {
    try {
      // Check if already granted
      final hasPermission = await _locationService.hasLocationPermission();
      if (hasPermission) return;

      // Check if permission is permanently denied
      final isPermanentlyDenied =
          await _locationService.isLocationPermissionPermanentlyDenied();

      if (isPermanentlyDenied) {
        // Show dialog explaining that permission is needed and offer to go to settings
        await _showLocationPermissionDeniedDialog();
        return;
      }

      // Request permission directly from device (iOS will show native dialog)
      final granted = await _locationService.requestLocationPermission();
      
      // If permission was granted, we're done - no need to show any dialog
      if (granted) return;
      
      // Permission was denied, check if permanently denied
      final stillPermanentlyDenied =
          await _locationService.isLocationPermissionPermanentlyDenied();
      
      if (stillPermanentlyDenied) {
        // Show dialog to go to settings only if permanently denied
        await _showLocationPermissionDeniedDialog();
      }
      // If just denied (not permanently), silently continue
      // User can grant permission later when needed
    } catch (e) {
    }
  }

  /// Request notification permission directly from device
  Future<void> _requestNotificationPermission() async {
    try {
      // Check if already granted
      final hasPermission =
          await _notificationService.hasNotificationPermission();
      if (hasPermission) return;

      // Check if permission is permanently denied
      final isPermanentlyDenied = await _notificationService
          .isNotificationPermissionPermanentlyDenied();

      if (isPermanentlyDenied) {
        // Show dialog explaining that permission is needed and offer to go to settings
        await _showNotificationPermissionDeniedDialog();
        return;
      }

      // Request permission directly from device (iOS will show native dialog)
      final granted =
          await _notificationService.requestNotificationPermission();
      
      // If permission was granted, we're done - no need to show any dialog
      if (granted) return;
      
      // Permission was denied, check if permanently denied
      final stillPermanentlyDenied = await _notificationService
          .isNotificationPermissionPermanentlyDenied();
      
      if (stillPermanentlyDenied) {
        // Show dialog to go to settings only if permanently denied
        await _showNotificationPermissionDeniedDialog();
      }
      // If just denied (not permanently), silently continue
      // User can grant permission later when needed
    } catch (e) {
    }
  }

  /// Show dialog when location permission is denied
  Future<void> _showLocationPermissionDeniedDialog() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Text(
              l10n.locationPermissionRequired,
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          l10n.locationPermissionMessage,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.later,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.goToSettings,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldOpenSettings == true) {
      await _locationService.openLocationSettings();
    }
  }

  /// Show dialog when notification permission is denied
  Future<void> _showNotificationPermissionDeniedDialog() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications_off, color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Text(
              l10n.notificationPermissionRequired,
              style: AppTypography.h6.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          l10n.notificationPermissionMessage,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.later,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.goToSettings,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldOpenSettings == true) {
      await _notificationService.openNotificationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Koşullu SafeArea - Arama sayfası (index 1) için SafeArea kullanma
          _currentIndex == 1
              ? _pages[_currentIndex] // CustomerSearchPage için SafeArea yok
              : SafeArea(
                  child:
                      _pages[_currentIndex], // Diğer sayfalar için SafeArea var
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                FocusScope.of(context).unfocus();
                setState(() => _currentIndex = index);
              },
              items: [
                CustomNavBarItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: l10n.homeTab,
                ),
                CustomNavBarItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map_rounded,
                  label: l10n.mapTab,
                ),
                CustomNavBarItem(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: l10n.appointmentsTab,
                ),
                CustomNavBarItem(
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: l10n.marketTab,
                ),
                CustomNavBarItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: l10n.profileTab,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
