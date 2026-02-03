import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/token_storage.dart';
import '../../../data/models/order_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/order_api_service.dart';
import '../../../domain/entities/order.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/order_card.dart';
import 'company_order_detail_page.dart';

class CompanyOrdersPage extends StatefulWidget {
  const CompanyOrdersPage({super.key});

  @override
  State<CompanyOrdersPage> createState() => _CompanyOrdersPageState();
}

class _CompanyOrdersPageState extends State<CompanyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderApiService _orderService = OrderApiService();
  final TokenStorage _tokenStorage = TokenStorage();

  bool _isLoading = true;
  String? _companyId;
  List<OrderModel> _allOrders = [];
  List<OrderModel> _pendingOrders = [];
  List<OrderModel> _completedOrders = [];
  List<OrderModel> _cancelledOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
    );
    _loadCompanyId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyId() async {
    try {
      await _tokenStorage.initialize();
      final userJson = await _tokenStorage.getUserJson();
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        final user = UserModel.fromJson(userData);
        _companyId = user.id;
      }
    } catch (e) {
      // Error loading company ID
    }
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (_companyId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _allOrders = [];
        _pendingOrders = [];
        _completedOrders = [];
        _cancelledOrders = [];
      });
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Load all orders for company
      final orders = await _orderService.getOrdersByCompany(
        companyId: _companyId!,
        status: null,
      );

      // Categorize orders
      // Status: 0 = Ödenmedi, 1 = Alındı, 2 = Teslim edildi
      final all = <OrderModel>[];
      final pending = <OrderModel>[]; // Status 0: Sipariş Ödenmedi
      final completed = <OrderModel>[]; // Status 2: Sipariş Teslim edildi
      final cancelled =
          <OrderModel>[]; // İptal edilenler (şu an yok ama gelecekte olabilir)

      for (final order in orders) {
        all.add(order);
        switch (order.status) {
          case OrderStatus.pending: // 0: Sipariş Ödenmedi
            pending.add(order);
            break;
          case OrderStatus.confirmed: // 1: Sipariş Alındı
            // Status 1'i de pending'e ekle (bekleyen kategorisinde)
            pending.add(order);
            break;
          case OrderStatus.completed: // 2: Sipariş Teslim edildi
            completed.add(order);
            break;
          case OrderStatus.cancelled:
            cancelled.add(order);
            break;
          default:
            // Diğer status'lar (preparing, readyForPickup) pending'e ekle
            pending.add(order);
            break;
        }
      }

      // Sort by date (newest first)
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      cancelled.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _allOrders = all;
        _pendingOrders = pending;
        _completedOrders = completed;
        _cancelledOrders = cancelled;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final errorString = e.toString().toLowerCase();
      final isUnauthorized = errorString.contains('unauthorized') ||
          errorString.contains('401') ||
          errorString.contains('yetkisiz');

      if (isUnauthorized) {
        setState(() {
          _isLoading = false;
          _allOrders = [];
          _pendingOrders = [];
          _completedOrders = [];
          _cancelledOrders = [];
        });
        return;
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Siparişler yüklenemedi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllOrders(),
                      _buildPendingOrders(),
                      _buildCompletedOrders(),
                      _buildCancelledOrders(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
        AppSpacing.screenHorizontal,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(color: AppColors.background),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.orders,
                  style: AppTypography.h5.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tüm siparişlerinizi buradan görüntüleyin',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: 0,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border, width: 1),
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
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.bodyMedium,
        isScrollable: true,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        tabs: [
          Tab(text: 'Tümü (${_allOrders.length})'),
          Tab(text: 'Bekleyen (${_pendingOrders.length})'),
          Tab(text: 'Tamamlanan (${_completedOrders.length})'),
          Tab(text: 'İptal (${_cancelledOrders.length})'),
        ],
      ),
    );
  }

  Widget _buildAllOrders() {
    if (_allOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'Sipariş Yok',
        subtitle: 'Henüz sipariş almadınız',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        itemCount: _allOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _allOrders[index];
          return OrderCard(
            order: order,
            onTap: () => _navigateToOrderDetail(order),
          );
        },
      ),
    );
  }

  Widget _buildPendingOrders() {
    if (_pendingOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule_outlined,
        title: 'Bekleyen Sipariş Yok',
        subtitle: 'Bekleyen siparişleriniz burada görünecek',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        itemCount: _pendingOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _pendingOrders[index];
          return OrderCard(
            order: order,
            onTap: () => _navigateToOrderDetail(order),
          );
        },
      ),
    );
  }

  Widget _buildCompletedOrders() {
    if (_completedOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'Tamamlanan Sipariş Yok',
        subtitle: 'Tamamlanan siparişleriniz burada görünecek',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        itemCount: _completedOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _completedOrders[index];
          return OrderCard(
            order: order,
            onTap: () => _navigateToOrderDetail(order),
          );
        },
      ),
    );
  }

  Widget _buildCancelledOrders() {
    if (_cancelledOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.cancel_outlined,
        title: 'İptal Edilen Sipariş Yok',
        subtitle: 'İptal edilen siparişler burada görünecek',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        itemCount: _cancelledOrders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _cancelledOrders[index];
          return OrderCard(
            order: order,
            onTap: () => _navigateToOrderDetail(order),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _navigateToOrderDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompanyOrderDetailPage(orderId: order.id),
      ),
    ).then((_) {
      // Refresh orders when returning from detail page
      _loadOrders();
    });
  }
}
















