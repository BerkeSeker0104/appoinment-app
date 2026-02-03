import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/announcement_model.dart';
import '../providers/announcement_provider.dart';

class AnnouncementSection extends StatefulWidget {
  const AnnouncementSection({super.key});

  @override
  State<AnnouncementSection> createState() => _AnnouncementSectionState();
}

class _AnnouncementSectionState extends State<AnnouncementSection> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementProvider>().loadAnnouncements();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnouncementProvider>(
      builder: (context, announcementProvider, child) {
        final announcements = announcementProvider.activeAnnouncements;

        if (announcementProvider.isLoading && announcements.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            alignment: Alignment.centerLeft,
            child: const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (announcements.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            bottom: AppSpacing.sm,
          ),
          child: SizedBox(
            height: 104,
            child: Stack(
                  children: [
                    // PageView for announcements
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemCount: announcements.length,
                      itemBuilder: (context, index) {
                        final announcement = announcements[index];
                        return _buildAnnouncementCard(context, announcement);
                      },
                    ),

                    // Page Indicators
                    if (announcements.length > 1)
                      Positioned(
                        bottom: AppSpacing.xxs,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            announcements.length,
                            (index) =>
                                _buildPageIndicator(index == _currentIndex),
                          ),
                        ),
                      ),
                  ],
                ),
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementCard(
      BuildContext context, AnnouncementModel announcement) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final title = announcement.getLocalizedTitle(localeCode);

    return GestureDetector(
      onTap: () => _showAnnouncementDetail(context, announcement),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: announcement.isExpired
                ? [AppColors.grey300, AppColors.grey400]
                : [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.h5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    announcement.isExpired
                        ? 'Süresi Doldu'
                        : 'Aktif: ${announcement.formattedExpiredDate}',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      height: AppSpacing.xxs,
      width: isActive ? AppSpacing.md : AppSpacing.xxs,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.grey300,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
    );
  }

  void _showAnnouncementDetail(
      BuildContext context, AnnouncementModel announcement) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final htmlContent = announcement.getLocalizedHtmlContent(localeCode);
    final title = announcement.getLocalizedTitle(localeCode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
              Text(
                'Duyuru Detayı',
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Html(
                    data: htmlContent,
                    onLinkTap: (url, _, __) async {
                      if (url != null) {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize.large,
                        color: AppColors.textSecondary,
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 8),
                        color: AppColors.textSecondary,
                      ),
                      "strong": Style(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Yayınlanma Tarihi: ${announcement.createdAt.day}/${announcement.createdAt.month}/${announcement.createdAt.year}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    announcement.isExpired
                        ? 'Süresi Doldu'
                        : 'Bitiş Tarihi: ${announcement.formattedExpiredDate}',
                    style: AppTypography.caption.copyWith(
                      color: announcement.isExpired
                          ? AppColors.error
                          : AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Kapat',
                    style: AppTypography.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
