import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Gizlilik Politikası',
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gizlilik Politikası',
              style: AppTypography.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Son güncelleme: 25 Temmuz 2025',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildSection(
              'M&W uygulaması olarak, kullanıcılarımızın gizliliğine büyük önem veriyoruz. Bu gizlilik politikası, uygulamamızın kullanıcı bilgilerini nasıl topladığını, kullandığını ve koruduğunu açıklamaktadır.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Sorumluluk Reddi'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Bu uygulama herhangi bir devlet kurumu tarafından geliştirilmemiştir, desteklenmemektedir ve resmi bir otoriteyi temsil etmemektedir. Uygulamada sunulan bilgiler yalnızca bilgilendirme amaçlıdır ve resmi belge niteliği taşımaz.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Toplanan Bilgiler'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Uygulama, aşağıdaki türde bilgileri toplayabilir:',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildBulletPoint('İsim, e-posta adresi ve diğer iletişim bilgileri'),
            _buildBulletPoint('Cihaz bilgileri (model, işletim sistemi, IP adresi vb.)'),
            _buildBulletPoint('Uygulama kullanımıyla ilgili analiz verileri'),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Bilgilerin Kullanımı'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Toplanan bilgiler şu amaçlarla kullanılabilir:',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildBulletPoint('Hizmetleri sağlamak ve geliştirmek'),
            _buildBulletPoint('Kullanıcı desteği sunmak'),
            _buildBulletPoint('Geliştirme ve analiz çalışmaları yapmak'),
            _buildBulletPoint('Gerektiğinde yasal yükümlülükleri yerine getirmek'),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Bilgi Paylaşımı'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Kullanıcı bilgileri, üçüncü taraflarla yalnızca aşağıdaki durumlarda paylaşılır:',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildBulletPoint('Kullanıcının açık izniyle'),
            _buildBulletPoint('Yasal zorunluluklar kapsamında resmi mercilerle'),
            _buildBulletPoint('Hizmet sağlayıcılarla (barındırma, analiz araçları vb.), sadece hizmet sunumu amacıyla'),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Güvenlik'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Kullanıcı verileri, güncel güvenlik teknolojileriyle korunur. Verilere yetkisiz erişimi engellemek için makul teknik ve idari önlemler alınmaktadır.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Çocukların Gizliliği'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Uygulamamız 13 yaş altı çocuklara yönelik değildir. 13 yaş altındaki çocuklardan bilinçli olarak bilgi toplamıyoruz.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Değişiklikler'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Bu gizlilik politikası zaman zaman güncellenebilir. Önemli değişiklikler durumunda kullanıcılar uygulama içinden veya web sitemizden bilgilendirilecektir.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('İletişim'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Gizlilik politikamızla ilgili her türlü soru için bizimle iletişime geçebilirsiniz:',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSection(
              'E-posta: app@mw.com',
              isBold: true,
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.h6.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSection(String text, {bool isBold = false}) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}









