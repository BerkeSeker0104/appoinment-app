import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final bool showRating;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.color,
    this.showRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starRating = index + 1;
          final isHalfStar =
              rating - starRating >= -0.5 && rating - starRating < 0;
          final isFullStar = rating >= starRating;

          return Icon(
            isFullStar
                ? Icons.star
                : isHalfStar
                    ? Icons.star_half
                    : Icons.star_border,
            size: size,
            color: color ?? AppColors.warning,
          );
        }),
        if (showRating) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
