import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/onboarding_content.dart';
import '../auth/welcome_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      imagePath: 'assets/onboarding/onboarding_1.png',
      titleKey: 'onboardingTitle1',
      descriptionKey: 'onboardingDesc1',
    ),
    OnboardingData(
      imagePath: 'assets/onboarding/onboarding_2.png',
      titleKey: 'onboardingTitle2',
      descriptionKey: 'onboardingDesc2',
    ),
    OnboardingData(
      imagePath: 'assets/onboarding/onboarding_3.png',
      titleKey: 'onboardingTitle3',
      descriptionKey: 'onboardingDesc3',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.setOnboardingCompleted();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentData = _onboardingData[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content with Column layout
          Column(
            children: [
              // Page content (images only)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    final data = _onboardingData[index];
                    return OnboardingContent(
                      imagePath: data.imagePath,
                    );
                  },
                ),
              ),

              // Navigation and text content
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32.0, vertical: 32.0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      _getLocalizedText(l10n, currentData.titleKey),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: const Color(0xFF1A1A1A), // Very dark text
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            fontSize: 24,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      _getLocalizedText(l10n, currentData.descriptionKey),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF4A4A4A), // Dark gray text
                            height: 1.5,
                            fontSize: 16,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Page indicator
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _onboardingData.length,
                      effect: const WormEffect(
                        dotColor: AppColors.border,
                        activeDotColor: AppColors.primary,
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 12,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Next/Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textInverse,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage == _onboardingData.length - 1
                              ? l10n.getStarted
                              : l10n.next,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textInverse,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Skip button (floating)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  l10n.skip,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF666666), // Darker gray
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedText(AppLocalizations l10n, String key) {
    switch (key) {
      case 'onboardingTitle1':
        return l10n.onboardingTitle1;
      case 'onboardingDesc1':
        return l10n.onboardingDesc1;
      case 'onboardingTitle2':
        return l10n.onboardingTitle2;
      case 'onboardingDesc2':
        return l10n.onboardingDesc2;
      case 'onboardingTitle3':
        return l10n.onboardingTitle3;
      case 'onboardingDesc3':
        return l10n.onboardingDesc3;
      default:
        return '';
    }
  }
}

class OnboardingData {
  final String imagePath;
  final String titleKey;
  final String descriptionKey;

  OnboardingData({
    required this.imagePath,
    required this.titleKey,
    required this.descriptionKey,
  });
}
