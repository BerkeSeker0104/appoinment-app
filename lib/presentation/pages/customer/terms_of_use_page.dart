import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kullanım Koşulları',
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
              'Kullanım Koşulları',
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
              'Bu kullanım koşulları, M&W mobil uygulamasının kullanımını düzenler. Uygulamayı kullanarak bu şartları kabul etmiş sayılırsınız.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Hizmet Tanımı'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'M&W, kullanıcılarına belirli bilgi ve hizmetlere erişim sağlayan bir mobil uygulamadır. Uygulama içeriği zamanla değişebilir.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Kullanım Kuralları'),
            const SizedBox(height: AppSpacing.sm),
            _buildBulletPoint('Uygulama yalnızca yasal amaçlar için kullanılabilir.'),
            _buildBulletPoint('Kullanıcılar, uygulamayı kullanırken diğer kullanıcıların haklarına saygı göstermelidir.'),
            _buildBulletPoint('Yetkisiz erişim, tersine mühendislik veya sistemin kötüye kullanımı yasaktır.'),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Abonelikler'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Uygulamamız, otomatik yenilenen abonelik seçenekleri sunabilir. Abonelik satın alındığında, kullanıcı belirli premium özelliklere erişim kazanır.',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildSection(
              'Abonelik Koşulları:',
              isBold: true,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildBulletPoint('Abonelik süresi boyunca tüm premium içerik ve özellikler aktif olur.'),
            _buildBulletPoint('Abonelik, kullanıcı iptal edene kadar otomatik olarak yenilenir.'),
            _buildBulletPoint('Abonelik ücreti, onay sırasında App Store hesabına yansıtılır.'),
            _buildBulletPoint('Yenileme ücreti, her fatura dönemi sonunda otomatik olarak tahsil edilir.'),
            _buildBulletPoint('Kullanıcılar, yenileme tarihinden en az 24 saat öncesine kadar otomatik yenilemeyi kapatabilir.'),
            _buildBulletPoint('Abonelik yönetimi ve iptal işlemleri, App Store hesap ayarlarından yapılabilir.'),
            const SizedBox(height: AppSpacing.md),
            _buildSection(
              'Abonelikler, iTunes/Apple hesabınız üzerinden yönetilir. Otomatik yenileme, kullanıcı tarafından devre dışı bırakılmadığı sürece geçerliliğini sürdürür. İptal işlemi, aktif abonelik döneminin sonunda geçerli olur; öncesinde geri ödeme yapılmaz.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Fikri Mülkiyet'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Uygulama ve içeriği, M&W\'a aittir. İzinsiz çoğaltılamaz, dağıtılamaz veya ticari amaçla kullanılamaz.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Sorumluluk Reddi'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Bu uygulama herhangi bir devlet kurumu tarafından geliştirilmemiştir, desteklenmemektedir ve resmi bir otoriteyi temsil etmemektedir. Uygulama içerisindeki bilgiler yalnızca rehberlik amaçlıdır ve yasal tavsiye niteliği taşımaz.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('Değişiklikler'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Bu kullanım koşulları zaman zaman değiştirilebilir. Değişiklikler uygulama üzerinden duyurulur ve yayım tarihi itibarıyla geçerli olur.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSectionTitle('İletişim'),
            const SizedBox(height: AppSpacing.sm),
            _buildSection(
              'Sorularınız için bize ulaşın: app@mw.com',
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









