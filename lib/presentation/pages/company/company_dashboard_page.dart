import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/notification_provider.dart';
import '../../../presentation/providers/message_provider.dart';
import '../../../presentation/widgets/notification_badge.dart';
import '../../../presentation/widgets/announcement_ribbon.dart';
// TEMPORARILY COMMENTED OUT - Branch management feature
// import '../../../data/models/branch_model.dart';
// import '../../../domain/usecases/branch_usecases.dart';
// import '../../../data/repositories/branch_repository_impl.dart';
// import 'add_branch_page.dart';
// import 'branch_detail_page.dart';
import 'company_main_page.dart';
import 'company_market_page.dart';
import 'company_notifications_page.dart';
import '../customer/customer_search_page.dart';
import 'follower_list_page.dart';
import 'employees/company_employees_page.dart';

class CompanyDashboardPage extends StatefulWidget {
  const CompanyDashboardPage({super.key});

  @override
  State<CompanyDashboardPage> createState() => _CompanyDashboardPageState();
}

class _CompanyDashboardPageState extends State<CompanyDashboardPage> {
  // TEMPORARILY COMMENTED OUT - Branch management feature
  // final BranchUseCases _branchUseCases = BranchUseCases(BranchRepositoryImpl());
  // List<BranchModel> _recentBranches = [];
  // int _totalBranches = 0;

  @override
  void initState() {
    super.initState();
    // Lazy load - load data when user actually views the dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboardData();
        // Load notification and message counts
        _loadProviderData();
      }
    });
  }

  void _loadProviderData() {
    try {
      final notificationProvider = context.read<NotificationProvider>();
      final messageProvider = context.read<MessageProvider>();

      // Only load counts once - don't start auto-refresh on dashboard
      // Auto-refresh will be started when user opens respective pages
      // This prevents unnecessary battery drain and API calls
      notificationProvider.loadUnreadCount();
      
      // Load messages list once to calculate unread count
      messageProvider.loadMessagesList();
    } catch (e) {
      // Provider not available yet, will be loaded when widget tree is ready
    }
  }

  Future<void> _loadDashboardData() async {
    // Currently no data to load, but keep async structure for future metrics
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.xl),

                _buildQuickActions(),
                const SizedBox(height: AppSpacing.xxxl),
                // Navigation bar için extra space
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.screenHorizontal),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 28),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Welcome Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Text(
                        AppLocalizations.of(context)!.welcomeCompany,
                        style: AppTypography.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Text(
                        AppLocalizations.of(context)!.welcomeCompanySubtitle,
                        style: AppTypography.body1.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TEMPORARILY COMMENTED OUT - Branch management feature
  // Widget _buildRecentBranches() { ... }
  // Widget _buildEmptyState() { ... }
  // Widget _buildErrorState() { ... }
  // Widget _buildBranchItem(BranchModel branch) { ... }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Announcement Panel
        const AnnouncementRibbon(),
        
        const SizedBox(height: AppSpacing.md),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Text(
            AppLocalizations.of(context)!.quickActions,
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Column(
            children: [
              // TEMPORARILY COMMENTED OUT - Branch management feature
              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildQuickAction(
              //         AppLocalizations.of(context)!.newBranch,
              //         Icons.add_business,
              //         AppColors.primary,
              //         actionId: 'new_branch',
              //       ),
              //     ),
              //     const SizedBox(width: AppSpacing.md),
              //     Expanded(
              //       child: _buildQuickAction(
              //         AppLocalizations.of(context)!.appointments,
              //         Icons.calendar_month,
              //         AppColors.primary,
              //         actionId: 'appointments',
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      AppLocalizations.of(context)!.appointments,
                      Icons.calendar_month,
                      AppColors.primary,
                      actionId: 'appointments',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildQuickAction(
                      AppLocalizations.of(context)!.services,
                      Icons.business_center,
                      AppColors.primary,
                      actionId: 'services',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      AppLocalizations.of(context)!.posts,
                      Icons.camera_alt_outlined,
                      AppColors.primary,
                      actionId: 'posts',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Consumer<MessageProvider>(
                      builder: (context, messageProvider, _) {
                        final unreadCount = messageProvider.getUnreadCount();
                        return _buildQuickAction(
                          AppLocalizations.of(context)!.messages,
                          Icons.message_outlined,
                          AppColors.primary,
                          actionId: 'messages',
                          badgeCount: unreadCount,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      AppLocalizations.of(context)!.mapTab,
                      Icons.map_outlined,
                      AppColors.primary,
                      actionId: 'map',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildQuickAction(
                      'Market',
                      Icons.store_outlined,
                      AppColors.primary,
                      actionId: 'market',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                   Expanded(
                    child: _buildQuickAction(
                      'Takipçiler',
                      Icons.people_alt_outlined,
                      AppColors.primary,
                      actionId: 'followers',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildQuickAction(
                      AppLocalizations.of(context)!.myBranch,
                      Icons.apartment,
                      AppColors.primary,
                      actionId: 'branch',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                   Expanded(
                    child: _buildQuickAction(
                      'Çalışanlar',
                      Icons.badge_outlined,
                      AppColors.primary,
                      actionId: 'employees',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Consumer<NotificationProvider>(
                      builder: (context, notificationProvider, _) {
                        return _buildQuickAction(
                          AppLocalizations.of(context)!.notifications,
                          Icons.notifications_outlined,
                          AppColors.primary,
                          actionId: 'notifications',
                          badgeCount: notificationProvider.unreadCount,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color, {
    String? actionId,
    int badgeCount = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.7 + (0.3 * animationValue),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                // TEMPORARILY COMMENTED OUT - Branch management feature
                // if (actionId == 'new_branch') {
                //   final result = await Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => const AddBranchPage(),
                //     ),
                //   );
                //   if (result == true && mounted) {
                //     _loadDashboardData(); // Refresh dashboard
                //   }
                // } else
                if (actionId == 'services') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyMainPage(),
                      settings: const RouteSettings(
                        arguments: {'tab': 'corporate', 'subtab': 'services'},
                      ),
                    ),
                  );
                } else if (actionId == 'appointments') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyMainPage(),
                      settings: const RouteSettings(
                        arguments: {'tab': 'appointments'},
                      ),
                    ),
                  );
                } else if (actionId == 'posts') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyMainPage(),
                      settings: const RouteSettings(
                        arguments: {'tab': 'corporate', 'subtab': 'posts'},
                      ),
                    ),
                  );
                } else if (actionId == 'messages') {
                  // Navigate to messages tab in CompanyMainPage
                  CompanyMainPage.navigateToMessagesTab(context);
                } else if (actionId == 'map') {
                  // Navigate to map page with back button
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerSearchPage(
                        showBackButton: true,
                      ),
                    ),
                  );
                } else if (actionId == 'market') {
                  // Navigate to market page (viewing only for companies)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyMarketPage(),
                    ),
                  );
                } else if (actionId == 'notifications') {
                  // Navigate to notifications page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyNotificationsPage(),
                    ),
                  );
                } else if (actionId == 'followers') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FollowerListPage(),
                    ),
                  );
                } else if (actionId == 'branch') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyMainPage(),
                      settings: const RouteSettings(
                        arguments: {'tab': 'corporate', 'subtab': 'branch'},
                      ),
                    ),
                  );
                } else if (actionId == 'employees') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyMainPage(),
                      settings: const RouteSettings(
                        arguments: {'tab': 'corporate', 'subtab': 'employees'},
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: Container(
                height: 80,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with circular background and badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 20, // Reduced icon size from default AppSpacing.iconMd
                          ),
                        ),
                        if (badgeCount > 0)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: NotificationBadge(
                              count: badgeCount,
                              size: 18,
                              backgroundColor: AppColors.error,
                              textColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1, // Restrict to single line
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
