import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class OnboardingContent extends StatelessWidget {
  final String imagePath;

  const OnboardingContent({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            // Fallback handled by errorBuilder in Image.asset below
          },
        ),
      ),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to a gradient background if image fails to load
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.secondary.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.image,
                size: 80,
                color: AppColors.textTertiary,
              ),
            ),
          );
        },
      ),
    );
  }
}
