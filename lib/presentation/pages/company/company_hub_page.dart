import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import 'my_branch_page.dart';
import 'company_services_page.dart';
import 'company_posts_page.dart';
import 'company_products_page.dart';
import 'company_orders_page.dart';
import 'add_company_service_page.dart';
import 'add_post_page.dart';
import 'add_product_page.dart';
import 'employees/company_employees_page.dart';

class CompanyHubPage extends StatefulWidget {
  const CompanyHubPage({super.key});

  @override
  State<CompanyHubPage> createState() => _CompanyHubPageState();
}

class _CompanyHubPageState extends State<CompanyHubPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _myBranchPageRefreshKey = 0;
  int _servicesPageRefreshKey = 0;
  int _postsPageRefreshKey = 0;
  int _productsPageRefreshKey = 0;
  int _ordersPageRefreshKey = 0;
  int _employeesPageRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB visibility
    });

    // Check if we should navigate to specific tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map) {
        if (args['subtab'] == 'branch') {
          _tabController.animateTo(0); // Navigate to my branch tab
        } else if (args['subtab'] == 'services') {
          _tabController.animateTo(1); // Navigate to services tab
        } else if (args['subtab'] == 'posts') {
          _tabController.animateTo(2); // Navigate to posts tab
        } else if (args['subtab'] == 'employees') {
          _tabController.animateTo(3); // Navigate to employees tab
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false, // Navbar için
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MyBranchPage(key: ValueKey(_myBranchPageRefreshKey)),
                  CompanyServicesPage(key: ValueKey(_servicesPageRefreshKey)),
                  CompanyPostsPage(key: ValueKey(_postsPageRefreshKey)),
                  CompanyEmployeesPage(
                    key: ValueKey(_employeesPageRefreshKey),
                    hideBackButton: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // FAB - Sadece servis ve post tablarında göster (şubem ve çalışanlar hariç)
      floatingActionButton: (_tabController.index == 0 || _tabController.index == 3)
          ? null
          : Padding(
              padding: const EdgeInsets.only(
                bottom: 100, // Navigation bar'ın üstünde
                right: 8,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, animationValue, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * animationValue),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXxl),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: AppColors.shadowStrong,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: () async {
                          Widget targetPage;
                          if (_tabController.index == 1) {
                            targetPage = const AddCompanyServicePage();
                          } else if (_tabController.index == 2) {
                            targetPage = const AddPostPage();
                          } else {
                            // My Branch tab or Employees - no FAB action needed here
                            return;
                          }

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => targetPage),
                          );

                          if (result == true) {
                            setState(() {
                              if (_tabController.index == 1) {
                                _servicesPageRefreshKey++;
                              } else if (_tabController.index == 2) {
                                _postsPageRefreshKey++;
                              }
                            });
                          }
                        },
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true, // Scrollable yapalım çünkü 4 tane sığmayabilir
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.body2.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontSize: 13,
        ),
        unselectedLabelStyle: AppTypography.body2.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16), // Padding ekleyelim scrollable olduğu için
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business, size: 16),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.myBranch,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business_center, size: 16),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.services,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_outlined, size: 16),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.posts,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.employees,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
