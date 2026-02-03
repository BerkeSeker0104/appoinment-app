import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/announcement_model.dart';
import '../providers/announcement_provider.dart';

class AnnouncementRibbon extends StatefulWidget {
  const AnnouncementRibbon({super.key});

  @override
  State<AnnouncementRibbon> createState() => _AnnouncementRibbonState();
}

class _AnnouncementRibbonState extends State<AnnouncementRibbon> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

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
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll(List<AnnouncementModel> announcements) {
    if (announcements.length <= 1) return;
    if (_isUserInteracting) return; // Kullanıcı etkileşimdeyse başlatma

    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _isUserInteracting) {
        timer.cancel();
        return;
      }

      final nextIndex = (_currentIndex + 1) % announcements.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onUserInteractionStart() {
    _isUserInteracting = true;
    _stopAutoScroll();
  }

  void _onUserInteractionEnd(List<AnnouncementModel> announcements) {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
        _startAutoScroll(announcements);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnnouncementProvider>(
      builder: (context, announcementProvider, child) {
        final announcements = announcementProvider.activeAnnouncements;

        if (announcements.isEmpty) {
          return const SizedBox.shrink();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isUserInteracting) {
            _startAutoScroll(announcements);
          }
        });

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 80,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification) {
                      _onUserInteractionStart();
                    } else if (notification is ScrollEndNotification) {
                      _onUserInteractionEnd(announcements);
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const ClampingScrollPhysics(),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return _buildAnnouncementCard(context, announcement);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (announcements.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    announcements.length,
                    (index) => _buildDotIndicator(index == _currentIndex),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.border.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
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
      onTap: () {
        _stopAutoScroll();
        _showAnnouncementDetail(context, announcement);
        // Restart auto scroll after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _startAutoScroll(
                context.read<AnnouncementProvider>().activeAnnouncements);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: announcement.isExpired
                        ? [AppColors.grey300, AppColors.grey400]
                        : [
                            AppColors.accent.withValues(alpha: 0.1),
                            AppColors.primary.withValues(alpha: 0.1)
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  announcement.isExpired ? Icons.info_outline : Icons.campaign,
                  color: announcement.isExpired
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: announcement.isExpired
                                ? AppColors.textTertiary
                                : AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          announcement.isExpired ? 'Süresi Doldu' : 'Aktif',
                          style: AppTypography.caption.copyWith(
                            color: announcement.isExpired
                                ? AppColors.textTertiary
                                : AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textTertiary,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      height: 6,
      width: isActive ? 20 : 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(3),
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
                title,
                style: AppTypography.h5.copyWith(
                  color: AppColors.textPrimary,
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
