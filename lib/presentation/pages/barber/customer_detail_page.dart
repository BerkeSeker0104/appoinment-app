import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/appointment_model.dart';
import '../../widgets/premium_button.dart';
import 'barber_clients_page.dart';
import 'appointment_detail_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final ClientData clientData;

  const CustomerDetailPage({super.key, required this.clientData});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      appBar: AppBar(
        title: Text(
          widget.clientData.user.name,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.primary),
            onPressed: _callCustomer,
          ),
          IconButton(
            icon: const Icon(Icons.message, color: AppColors.primary),
            onPressed: _messageCustomer,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomerHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildAppointmentsTab(),
                  _buildNotesTab(),
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.primary, width: 0.5),
            ),
            child:
                widget.clientData.user.avatar != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Image.network(
                        widget.clientData.user.avatar!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                _buildAvatarFallback(),
                      ),
                    )
                    : _buildAvatarFallback(),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.clientData.user.name,
                        style: AppTypography.h5.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: _getClientStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        _getClientStatusText(),
                        style: AppTypography.bodySmall.copyWith(
                          color: _getClientStatusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (widget.clientData.user.phone != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: AppSpacing.iconSm,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        widget.clientData.user.phone!,
                        style: AppTypography.bodyMedium.copyWith(
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
                      Icons.email,
                      size: AppSpacing.iconSm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        widget.clientData.user.email,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Center(
        child: Text(
          widget.clientData.user.name.isNotEmpty
              ? widget.clientData.user.name[0].toUpperCase()
              : '?',
          style: AppTypography.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.bodyMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        tabs: const [
          Tab(text: 'Genel Bakış'),
          Tab(text: 'Randevular'),
          Tab(text: 'Notlar'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsGrid(),
          const SizedBox(height: AppSpacing.xl),
          _buildPreferencesSection(),
          const SizedBox(height: AppSpacing.xl),
          _buildVisitHistorySection(),
          const SizedBox(height: AppSpacing.xl),
          _buildPaymentSummarySection(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Toplam Randevu',
          widget.clientData.totalAppointments.toString(),
          Icons.event,
          AppColors.primary,
        ),
        _buildStatCard(
          'Toplam Harcama',
          '₺${widget.clientData.totalSpent.toStringAsFixed(0)}',
          Icons.attach_money,
          AppColors.success,
        ),
        _buildStatCard(
          'Ortalama Harcama',
          '₺${(widget.clientData.totalSpent / widget.clientData.totalAppointments).toStringAsFixed(0)}',
          Icons.trending_up,
          AppColors.info,
        ),
        _buildStatCard(
          'Müşteri Süresi',
          '${DateTime.now().difference(widget.clientData.firstVisit).inDays} gün',
          Icons.schedule,
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: AppSpacing.iconMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Tercihler',
      icon: Icons.favorite,
      child: Column(
        children: [
          _buildPreferenceItem('Favori Hizmet', 'Saç Kesimi'),
          _buildPreferenceItem('Tercih Edilen Saat', '10:00 - 12:00'),
          _buildPreferenceItem('Tercih Edilen Gün', 'Cumartesi'),
          _buildPreferenceItem('Özel İstekler', 'Yanlar kısa, üst uzun'),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitHistorySection() {
    return _buildSection(
      title: 'Ziyaret Geçmişi',
      icon: Icons.history,
      child: Column(
        children: [
          _buildVisitItem('İlk Ziyaret', widget.clientData.firstVisit),
          if (widget.clientData.lastVisit != null)
            _buildVisitItem('Son Ziyaret', widget.clientData.lastVisit!),
          _buildVisitItem(
            'Ortalama Aralık',
            null,
            customValue: '${_getAverageVisitInterval()} gün',
          ),
          _buildVisitItem('En Uzun Aralık', null, customValue: '45 gün'),
        ],
      ),
    );
  }

  Widget _buildVisitItem(String label, DateTime? date, {String? customValue}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            customValue ?? (date != null ? _formatDate(date) : 'Bilinmiyor'),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummarySection() {
    return _buildSection(
      title: 'Ödeme Özeti',
      icon: Icons.payment,
      child: Column(
        children: [
          _buildPaymentItem(
            'Toplam Ödeme',
            '₺${widget.clientData.totalSpent.toStringAsFixed(0)}',
          ),
          _buildPaymentItem(
            'Ortalama Ödeme',
            '₺${(widget.clientData.totalSpent / widget.clientData.totalAppointments).toStringAsFixed(0)}',
          ),
          _buildPaymentItem('En Yüksek Ödeme', '₺120'),
          _buildPaymentItem('En Düşük Ödeme', '₺40'),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    final appointments = _getCustomerAppointments();

    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppColors.textQuaternary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Henüz randevu geçmişi yok',
              style: AppTypography.h6.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return GestureDetector(
          onTap: () => _navigateToAppointmentDetail(appointment),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildAppointmentCard(appointment),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.startDate,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      appointment.startHour,
                      style: AppTypography.monoMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(appointment.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  appointment.statusText,
                  style: AppTypography.bodySmall.copyWith(
                    color: _getStatusColor(appointment.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            appointment.services.map((s) => s.name).join(', '),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (appointment.services.isNotEmpty &&
                  appointment.services.any((s) => s.durationMinutes != null))
                Text(
                  '${appointment.services.fold<int>(0, (sum, s) => sum + (s.durationMinutes ?? 0))} dakika',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              const Spacer(),
              if (appointment.totalPrice != null)
                Text(
                  '₺${appointment.totalPrice!.toStringAsFixed(0)}',
                  style: AppTypography.monoMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Müşteri Notları',
            icon: Icons.note,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Text(
                'Bu müşteri için henüz not eklenmemiş.\n\nBuraya müşterinin tercihlerini, özel isteklerini veya önemli bilgilerini ekleyebilirsiniz.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PremiumButton(
            text: 'Not Ekle',
            onPressed: _addNote,
            variant: ButtonVariant.secondary,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: AppSpacing.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PremiumButton(
              text: 'Randevu Oluştur',
              onPressed: _createAppointment,
              variant: ButtonVariant.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: PremiumButton(
              text: 'Mesaj Gönder',
              onPressed: _messageCustomer,
              variant: ButtonVariant.secondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primary),
                  title: const Text('Bilgileri Düzenle'),
                  onTap: () {
                    Navigator.pop(context);
                    _editCustomer();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.note_add, color: AppColors.info),
                  title: const Text('Not Ekle'),
                  onTap: () {
                    Navigator.pop(context);
                    _addNote();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: AppColors.secondary),
                  title: const Text('Bilgileri Paylaş'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareCustomer();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: AppColors.error),
                  title: const Text('Müşteriyi Engelle'),
                  onTap: () {
                    Navigator.pop(context);
                    _blockCustomer();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Color _getClientStatusColor() {
    if (widget.clientData.lastVisit == null) return AppColors.textQuaternary;

    final daysSinceLastVisit =
        DateTime.now().difference(widget.clientData.lastVisit!).inDays;
    if (daysSinceLastVisit <= 7) return AppColors.success;
    if (daysSinceLastVisit <= 30) return AppColors.warning;
    return AppColors.error;
  }

  String _getClientStatusText() {
    if (widget.clientData.lastVisit == null) return 'Yeni Müşteri';

    final daysSinceLastVisit =
        DateTime.now().difference(widget.clientData.lastVisit!).inDays;
    if (daysSinceLastVisit <= 7) return 'Aktif Müşteri';
    if (daysSinceLastVisit <= 30) return 'Uzak Müşteri';
    return 'Kayıp Müşteri';
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.confirmed:
        return AppColors.info;
      case AppointmentStatus.inProgress:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.noShow:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int _getAverageVisitInterval() {
    if (widget.clientData.totalAppointments <= 1) return 0;

    final totalDays =
        DateTime.now().difference(widget.clientData.firstVisit).inDays;
    return (totalDays / widget.clientData.totalAppointments).round();
  }

  List<AppointmentModel> _getCustomerAppointments() {
    // TODO: Replace with real customer appointment data from API
    return <AppointmentModel>[];
  }

  void _navigateToAppointmentDetail(AppointmentModel appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailPage(appointment: appointment),
      ),
    );
  }

  void _callCustomer() {
    // Müşteriyi ara
  }

  void _messageCustomer() {
    // Müşteriye mesaj gönder
  }

  void _createAppointment() {
    // Randevu oluşturma sayfasına git
  }

  void _editCustomer() {
    // Müşteri düzenleme sayfasına git
  }

  void _addNote() {
    // Not ekleme dialog'u aç
  }

  void _shareCustomer() {
    // Müşteri bilgilerini paylaş
  }

  void _blockCustomer() {
    // Müşteriyi engelle
  }
}
