import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

import '../../widgets/modern_nav_bar.dart';
import 'barber_dashboard_page.dart';
import 'barber_calendar_page.dart';
import 'barber_clients_page.dart';
import 'barber_profile_page.dart';

class BarberMainPage extends StatefulWidget {
  const BarberMainPage({super.key});

  @override
  State<BarberMainPage> createState() => _BarberMainPageState();
}

class _BarberMainPageState extends State<BarberMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const BarberDashboardPage(),
    const BarberCalendarPage(),
    const BarberClientsPage(),
    const BarberProfilePage(),
  ];

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
                items: const [
                  ModernNavBarItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                  ),
                  ModernNavBarItem(
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today_rounded,
                    label: 'Takvim',
                  ),
                  ModernNavBarItem(
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: 'Müşteriler',
                  ),
                  ModernNavBarItem(
                    icon: Icons.tune_outlined,
                    activeIcon: Icons.tune_rounded,
                    label: 'Ayarlar',
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
