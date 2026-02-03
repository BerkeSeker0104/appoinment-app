import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/user_model.dart';

import 'customer_detail_page.dart';

class BarberClientsPage extends StatefulWidget {
  const BarberClientsPage({super.key});

  @override
  State<BarberClientsPage> createState() => _BarberClientsPageState();
}

class _BarberClientsPageState extends State<BarberClientsPage> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildStatsCards(),
            Expanded(child: _buildClientsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Müşterilerim',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${_getClients().length} toplam müşteri',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary, width: 0.5),
            ),
            child: Icon(
              Icons.group,
              color: AppColors.primary,
              size: AppSpacing.iconMd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Müşteri ara...',
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: AppSpacing.iconMd,
            ),
            suffixIcon:
                searchQuery.isNotEmpty
                    ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                        size: AppSpacing.iconMd,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => searchQuery = '');
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final clients = _getClients();
    final totalAppointments = _getTotalAppointments();
    final thisMonthClients = _getThisMonthClients();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Toplam Müşteri',
              clients.length.toString(),
              Icons.people,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              'Bu Ay Yeni',
              thisMonthClients.toString(),
              Icons.person_add,
              AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _buildStatCard(
              'Toplam Randevu',
              totalAppointments.toString(),
              Icons.event,
              AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSpacing.iconMd),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.monoLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsList() {
    final filteredClients = _getFilteredClients();

    if (filteredClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isNotEmpty ? Icons.search_off : Icons.group_off,
              size: 64,
              color: AppColors.textQuaternary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              searchQuery.isNotEmpty
                  ? 'Arama sonucu bulunamadı'
                  : 'Henüz müşteriniz yok',
              style: AppTypography.h6.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              searchQuery.isNotEmpty
                  ? 'Farklı anahtar kelimeler deneyin'
                  : 'İlk randevunuz geldiğinde müşteriler burada görünecek',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.screenHorizontal,
        AppSpacing.screenHorizontal,
        AppSpacing.screenHorizontal + 100, // Navigation bar için extra space
      ),
      itemCount: filteredClients.length,
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        return GestureDetector(
          onTap: () => _navigateToClientDetail(client),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildClientCard(client),
          ),
        );
      },
    );
  }

  Widget _buildClientCard(ClientData client) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary, width: 0.5),
            ),
            child:
                client.user.avatar != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Image.network(
                        client.user.avatar!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _buildAvatarFallback(client.user.name),
                      ),
                    )
                    : _buildAvatarFallback(client.user.name),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.user.name,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (client.user.phone != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: AppSpacing.iconSm,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        client.user.phone!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: AppSpacing.iconSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${client.totalAppointments} randevu',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Icon(
                      Icons.attach_money,
                      size: AppSpacing.iconSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '₺${client.totalSpent.toStringAsFixed(0)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getClientStatusColor(
                    client.lastVisit,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  _getClientStatusText(client.lastVisit),
                  style: AppTypography.bodySmall.copyWith(
                    color: _getClientStatusColor(client.lastVisit),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                client.lastVisit != null
                    ? _formatDate(client.lastVisit!)
                    : 'Henüz gelmedi',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTypography.h5.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _navigateToClientDetail(ClientData client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailPage(clientData: client),
      ),
    );
  }

  List<ClientData> _getClients() {
    // Placeholder disabled until API integration
    return [];
  }

  List<ClientData> _getFilteredClients() {
    final clients = _getClients();
    if (searchQuery.isEmpty) return clients;

    return clients.where((client) {
      final query = searchQuery.toLowerCase();
      return client.user.name.toLowerCase().contains(query) ||
          (client.user.phone?.contains(query) ?? false) ||
          client.user.email.toLowerCase().contains(query);
    }).toList();
  }

  int _getTotalAppointments() {
    return _getClients().fold(
      0,
      (sum, client) => sum + client.totalAppointments,
    );
  }

  int _getThisMonthClients() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);

    return _getClients().where((client) {
      return client.firstVisit.isAfter(thisMonth);
    }).length;
  }

  Color _getClientStatusColor(DateTime? lastVisit) {
    if (lastVisit == null) return AppColors.textQuaternary;

    final daysSinceLastVisit = DateTime.now().difference(lastVisit).inDays;
    if (daysSinceLastVisit <= 7) return AppColors.success;
    if (daysSinceLastVisit <= 30) return AppColors.warning;
    return AppColors.error;
  }

  String _getClientStatusText(DateTime? lastVisit) {
    if (lastVisit == null) return 'Yeni';

    final daysSinceLastVisit = DateTime.now().difference(lastVisit).inDays;
    if (daysSinceLastVisit <= 7) return 'Aktif';
    if (daysSinceLastVisit <= 30) return 'Uzak';
    return 'Kayıp';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class ClientData {
  final UserModel user;
  final int totalAppointments;
  final double totalSpent;
  final DateTime? lastVisit;
  final DateTime firstVisit;

  const ClientData({
    required this.user,
    required this.totalAppointments,
    required this.totalSpent,
    this.lastVisit,
    required this.firstVisit,
  });
}
