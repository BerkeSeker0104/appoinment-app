import 'package:flutter/material.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/modern_nav_bar.dart';
import 'company_dashboard_page.dart';
import 'company_hub_page.dart';
import 'company_appointments_page.dart';
import 'company_profile_page.dart';
import 'company_messages_page.dart';

class CompanyMainPage extends StatefulWidget {
  const CompanyMainPage({super.key});

  @override
  State<CompanyMainPage> createState() => _CompanyMainPageState();

  // Static method to navigate to messages tab
  static void navigateToMessagesTab(BuildContext context) {
    final state = context.findAncestorStateOfType<_CompanyMainPageState>();
    state?.navigateToMessagesTab();
  }
}

class _CompanyMainPageState extends State<CompanyMainPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages once to prevent re-creation
    _pages = [
      const CompanyDashboardPage(),
      const CompanyHubPage(),
      const CompanyAppointmentsPage(),
      const CompanyMessagesPage(),
      const CompanyProfilePage(),
    ];
    // Check if we should navigate to a specific tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map) {
        if (args['tab'] == 'corporate') {
          setState(() {
            _currentIndex = 1; // Navigate to corporate tab
          });
        } else if (args['tab'] == 'appointments') {
          setState(() {
            _currentIndex = 2; // Navigate to appointments tab
          });
        } else if (args['tab'] == 'messages') {
          setState(() {
            _currentIndex = 3; // Navigate to messages tab
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService().markAppReady();
    });
  }

  // Navigate to messages tab
  void navigateToMessagesTab() {
    setState(() {
      _currentIndex = 3; // Messages tab index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false, // Bottom SafeArea'yı kapatıyoruz çünkü navbar var
        child: Stack(
          children: [
            _pages[_currentIndex],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ModernNavBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: [
                  ModernNavBarItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: AppLocalizations.of(context)!.dashboard,
                  ),
                  ModernNavBarItem(
                    icon: Icons.business_outlined,
                    activeIcon: Icons.business_rounded,
                    label: AppLocalizations.of(context)!.corporate,
                  ),
                  ModernNavBarItem(
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today_rounded,
                    label: AppLocalizations.of(context)!.appointmentsTab,
                  ),
                  ModernNavBarItem(
                    icon: Icons.message_outlined,
                    activeIcon: Icons.message_rounded,
                    label: AppLocalizations.of(context)!.messages,
                  ),
                  ModernNavBarItem(
                    icon: Icons.tune_outlined,
                    activeIcon: Icons.tune_rounded,
                    label: AppLocalizations.of(context)!.profile,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
